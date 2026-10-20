import Foundation
import XCTest
@testable import HomeworkDomain

final class StatusTests: XCTestCase {
    func testTransitionsSearchAndReminderExclusion() throws {
        let now = Date()
        var task = Assignment(title: "Lab", course: "Networks", notes: "TCP analysis", dueDate: now.addingTimeInterval(7200),
                              reminder: .init(amount: 1, unit: .hours), now: now)
        for status in [AssignmentStatus.completed, .active, .abandoned, .active] {
            task.transition(to: status, at: now)
            try task.validate()
            XCTAssertEqual(task.completedAt != nil, status == .completed)
            XCTAssertEqual(task.abandonedAt != nil, status == .abandoned)
            XCTAssertEqual(ReminderPlan(assignments: [task], now: now).scheduled.count, status == .active ? 1 : 0)
        }
        task.transition(to: .abandoned, at: now)
        XCTAssertTrue(AssignmentQuery.apply([task]).isEmpty)
        XCTAssertEqual(AssignmentQuery.apply([task], filter: .abandoned, search: "tcp"), [task])
        XCTAssertTrue(AssignmentQuery.apply([task], filter: .completed, search: "Lab").isEmpty)
        XCTAssertTrue(AssignmentQuery.apply([task], filter: .all, search: "unrelated").isEmpty)
    }

    func testLegacyBackupDecodesAndNewStatusRoundTrips() throws {
        var task = Assignment(title: "Legacy", dueDate: Date())
        task.transition(to: .completed, at: Date())
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(task)) as? [String: Any])
        object.removeValue(forKey: "status"); object.removeValue(forKey: "abandonedAt")
        XCTAssertEqual(try JSONDecoder().decode(Assignment.self, from: JSONSerialization.data(withJSONObject: object)), task)
        task.transition(to: .abandoned, at: Date())
        XCTAssertEqual(try JSONDecoder().decode(Assignment.self, from: JSONEncoder().encode(task)), task)
    }
}
