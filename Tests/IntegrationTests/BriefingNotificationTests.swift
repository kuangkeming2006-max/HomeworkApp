import Foundation
import XCTest
import HomeworkDomain
@testable import HomeworkApp

@MainActor
private final class SummaryNotificationClient: BriefingNotificationClient {
    var status: NotificationPermission = .allowed
    var pending: Set<String> = []
    var reminders: [PlannedReminder] = []
    var briefings: [PlannedBriefing] = []
    var removals: [[String]] = []
    var permissionRequests = 0
    func permission() async -> NotificationPermission { status }
    func requestPermission() async throws -> Bool { permissionRequests += 1; status = .allowed; return true }
    func pendingIdentifiers() async -> [String] { Array(pending) }
    func remove(identifiers: [String]) { removals.append(identifiers); pending.subtract(identifiers) }
    func add(_ reminder: PlannedReminder) async throws { reminders.append(reminder); pending.insert(reminder.identifier) }
    func addBriefing(_ briefing: PlannedBriefing) async throws { briefings.append(briefing); pending.insert(briefing.identifier) }
}

@MainActor
final class BriefingNotificationTests: XCTestCase {
    func testCompletionAlsoRemovesAlreadyDeliveredReminderAndUndoRestoresSchedule() async {
        let client = SummaryNotificationClient(); let coordinator = NotificationCoordinator(client: client)
        var task = Assignment(title: "Synthetic", dueDate: Date().addingTimeInterval(7200), reminder: .init(amount: 1, unit: .hours))
        coordinator.refresh([task]); await coordinator.waitUntilIdle()
        let id = "assignment.\(task.id.uuidString)"
        client.pending.remove(id) // The system delivered it; it is no longer pending.
        task.transition(to: .completed, at: Date())
        coordinator.refresh([task]); await coordinator.waitUntilIdle()
        XCTAssertTrue(client.removals.contains { $0.contains(id) })
        task.transition(to: .active, at: Date())
        coordinator.refresh([task]); await coordinator.waitUntilIdle()
        XCTAssertTrue(client.pending.contains(id))
    }
    func testNotificationActionsPersistCompletionAndRouteToTheCorrectAssignment() async throws {
        let container = AppContainer(testing: true)
        let store = try XCTUnwrap(container.store)
        let task = Assignment(title: "Synthetic action", dueDate: Date().addingTimeInterval(7200), reminder: .init(amount: 1, unit: .hours))
        try store.save([task])
        await container.handleNotificationAndWait(.complete(task.id))
        XCTAssertEqual(store.assignment(task.id)?.status, .completed)
        XCTAssertNotNil(store.assignment(task.id)?.completedAt)
        XCTAssertEqual(container.notifications.scheduledCount, 0)
        container.handleNotification(.open(.assignment(task.id)))
        XCTAssertEqual(container.pendingRoute, .assignment(task.id))
        container.handleNotification(.open(.briefing))
        XCTAssertEqual(container.pendingRoute, .briefing)
    }
    func testIncrementalRequestsCapacityAndDeniedPermission() async {
        let client = SummaryNotificationClient()
        client.pending = Set((0..<3).map { "unrelated.\($0)" })
        let coordinator = NotificationCoordinator(client: client)
        let tasks = (0..<80).map { Assignment(title: "Synthetic \($0)", dueDate: Date().addingTimeInterval(Double(7200 + $0)), reminder: .init(amount: 1, unit: .hours)) }
        let configuration = BriefingConfiguration(enabled: true)
        coordinator.refresh(tasks, briefing: configuration); await coordinator.waitUntilIdle()
        XCTAssertEqual(client.pending.count, 60); XCTAssertEqual(coordinator.briefingCount, 7)
        let added = client.reminders.count
        coordinator.refresh(tasks, briefing: configuration); await coordinator.waitUntilIdle()
        XCTAssertEqual(client.reminders.count, added); XCTAssertEqual(client.briefings.count, 7)
        XCTAssertTrue(client.removals.isEmpty)
        var changed = tasks; changed[0].notes = "Unrelated content edit"
        coordinator.refresh(changed, briefing: configuration); await coordinator.waitUntilIdle()
        XCTAssertEqual(client.reminders.count, added)
        client.status = .denied
        coordinator.refresh(changed, briefing: configuration); await coordinator.waitUntilIdle()
        XCTAssertEqual(client.pending.count, 3); XCTAssertEqual(coordinator.scheduledCount, 0)
        await coordinator.enable(); XCTAssertEqual(client.permissionRequests, 0)
        client.status = .notDetermined
        await coordinator.enable(); XCTAssertEqual(client.permissionRequests, 1)
        await coordinator.enable(); XCTAssertEqual(client.permissionRequests, 1)
    }

    func testBriefingHistoryContainsOnlyObservedSnapshotsAndPersists() throws {
        let suite = "synthetic.briefing.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let history = BriefingHistoryStore(defaults: defaults)
        XCTAssertTrue(history.reports.isEmpty)
        let now = Date()
        history.record(BriefingService.report([], now: now.addingTimeInterval(-3 * 86400)))
        history.record(BriefingService.report([], now: now))
        history.record(BriefingService.report([], now: now.addingTimeInterval(1)))
        XCTAssertEqual(history.reports.count, 2)
        XCTAssertEqual(BriefingHistoryStore(defaults: defaults).reports, history.reports)
    }
}
