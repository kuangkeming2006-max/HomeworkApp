import XCTest
@testable import HomeworkDomain

final class ReminderPlanTests: XCTestCase {
    func testCapacityUsesEarliestFireTimesAndPastRemindersAreSkipped() {
        let now = Date(timeIntervalSince1970: 100_000)
        let assignments = (0..<70).map { index in
            Assignment(title: "Task \(index)", dueDate: now.addingTimeInterval(Double(index) * 3600),
                       dueTimeZone: "UTC", reminder: .init(amount: 30, unit: .minutes), now: now)
        }
        let plan = ReminderPlan(assignments: Array(assignments.reversed()), now: now)
        XCTAssertEqual(plan.scheduled.count, 60)
        XCTAssertEqual(plan.pastCount, 1)
        XCTAssertEqual(plan.deferredCount, 9)
        XCTAssertEqual(plan.scheduled.first?.title, "Task 1")
        XCTAssertEqual(plan.scheduled.last?.title, "Task 60")
    }

    func testCompletionDeletionAndRestorationRecalculateRequests() {
        let now = Date()
        var assignment = Assignment(title: "Report", dueDate: now.addingTimeInterval(7200),
                                    reminder: .init(amount: 1, unit: .hours))
        XCTAssertEqual(ReminderPlan(assignments: [assignment], now: now).scheduled.count, 1)
        assignment.isCompleted = true; assignment.completedAt = now
        XCTAssertTrue(ReminderPlan(assignments: [assignment], now: now).scheduled.isEmpty)
        assignment.isCompleted = false; assignment.completedAt = nil
        XCTAssertEqual(ReminderPlan(assignments: [assignment], now: now).scheduled.count, 1)
        assignment.deletedAt = now
        XCTAssertTrue(ReminderPlan(assignments: [assignment], now: now).scheduled.isEmpty)
    }
}
