import XCTest
import HomeworkDomain
@testable import HomeworkApp

@MainActor
private final class MemoryNotificationClient: ReminderNotificationClient {
    var status: NotificationPermission = .allowed
    var pending: [String] = ["unrelated"]
    var added: [PlannedReminder] = []
    func permission() async -> NotificationPermission { status }
    func requestPermission() async throws -> Bool { status = .allowed; return true }
    func pendingIdentifiers() async -> [String] { pending }
    func remove(identifiers: [String]) { pending.removeAll { identifiers.contains($0) } }
    func add(_ reminder: PlannedReminder) async throws { pending.append(reminder.identifier); added.append(reminder) }
}

@MainActor
final class NotificationTests: XCTestCase {
    func testReconciliationCancelsCompletedRequestsAndPreservesOtherRequests() async {
        let client = MemoryNotificationClient()
        let coordinator = NotificationCoordinator(client: client)
        var assignment = Assignment(title: "Report", dueDate: Date().addingTimeInterval(7200),
                                    reminder: .init(amount: 30, unit: .minutes))
        coordinator.refresh([assignment]); await coordinator.waitUntilIdle()
        XCTAssertEqual(coordinator.scheduledCount, 1)
        XCTAssertTrue(client.pending.contains("unrelated"))
        assignment.isCompleted = true; assignment.completedAt = Date()
        coordinator.refresh([assignment]); await coordinator.waitUntilIdle()
        XCTAssertEqual(client.pending, ["unrelated"])
        client.status = .denied
        assignment.isCompleted = false; assignment.completedAt = nil
        coordinator.refresh([assignment]); await coordinator.waitUntilIdle()
        XCTAssertEqual(coordinator.scheduledCount, 0)
        XCTAssertEqual(coordinator.permission, .denied)
    }
}
