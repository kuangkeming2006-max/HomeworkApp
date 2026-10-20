import Foundation
import XCTest
import HomeworkDomain
@testable import HomeworkApp

@MainActor
private final class MemoryActivityClient: LiveActivityClient {
    var available = true
    var activities: [HomeworkLiveActivity] = []
    var requests = 0
    var updates = 0
    var ends = 0
    var fail = false
    func request(_ plan: LiveActivityPlan, now: Date) throws {
        if fail { throw AssignmentError.invalid("Synthetic capability failure") }
        requests += 1
        activities.append(.init(id: UUID().uuidString, assignmentID: plan.assignmentID, title: plan.title, course: plan.course,
                                deadline: plan.deadline, start: plan.start, priority: plan.priority.rawValue,
                                state: plan.start > now ? .pending : .active))
    }
    func update(_ id: String, plan: LiveActivityPlan) async {
        updates += 1
        activities.removeAll { $0.id == id }
        activities.append(.init(id: id, assignmentID: plan.assignmentID, title: plan.title, course: plan.course,
                                deadline: plan.deadline, start: plan.start, priority: plan.priority.rawValue, state: .active))
    }
    func end(_ id: String) async { ends += 1; activities.removeAll { $0.id == id } }
}

@MainActor
final class LiveActivityTests: XCTestCase {
    func testPendingRescheduleAndTerminalCancellation() async throws {
        let client = MemoryActivityClient(); let coordinator = LiveActivityCoordinator(client: client)
        var task = Assignment(title: "Report", dueDate: Date().addingTimeInterval(86400), reminder: .init(amount: 1, unit: .hours))
        coordinator.refresh([task], enabled: true, foreground: true); await coordinator.waitUntilIdle()
        XCTAssertEqual(client.requests, 1); XCTAssertEqual(client.activities.first?.state, .pending)
        coordinator.refresh([task], enabled: true, foreground: true); await coordinator.waitUntilIdle()
        XCTAssertEqual(client.requests, 1)
        task.dueDate.addTimeInterval(3600)
        coordinator.refresh([task], enabled: true, foreground: true); await coordinator.waitUntilIdle()
        XCTAssertEqual(client.ends, 1); XCTAssertEqual(client.requests, 2); XCTAssertEqual(client.activities.count, 1)
        task.transition(to: .abandoned, at: Date())
        coordinator.refresh([task], enabled: true, foreground: true); await coordinator.waitUntilIdle()
        XCTAssertTrue(client.activities.isEmpty); XCTAssertNil(coordinator.registeredPlan)
    }

    func testImmediateUpdatesFailureFallbackAndForegroundGuard() async {
        let client = MemoryActivityClient(); let coordinator = LiveActivityCoordinator(client: client)
        var task = Assignment(title: "Report", dueDate: Date().addingTimeInterval(1800), reminder: .init(amount: 1, unit: .hours))
        coordinator.refresh([task], enabled: true, foreground: false); await coordinator.waitUntilIdle()
        XCTAssertEqual(client.requests, 0); XCTAssertNil(coordinator.registeredPlan)
        client.fail = true
        coordinator.refresh([task], enabled: true, foreground: true); await coordinator.waitUntilIdle()
        XCTAssertNil(coordinator.registeredPlan); XCTAssertNotNil(coordinator.errorMessage)
        client.fail = false
        coordinator.refresh([task], enabled: true, foreground: true); await coordinator.waitUntilIdle()
        XCTAssertEqual(client.activities.first?.state, .active)
        task.title = "Updated title"
        coordinator.refresh([task], enabled: true, foreground: true); await coordinator.waitUntilIdle()
        XCTAssertEqual(client.updates, 1); XCTAssertEqual(client.requests, 1)
        client.available = false
        coordinator.refresh([task], enabled: true, foreground: true); await coordinator.waitUntilIdle()
        XCTAssertTrue(client.activities.isEmpty); XCTAssertNil(coordinator.registeredPlan)
    }
}
