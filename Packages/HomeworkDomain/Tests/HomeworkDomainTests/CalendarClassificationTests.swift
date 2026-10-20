import Foundation
import XCTest
@testable import HomeworkDomain

final class CalendarClassificationTests: XCTestCase {
    func testClassificationPrecedenceAndUniqueStableDots() throws {
        let now = Date(timeIntervalSince1970: 1_790_000_000)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        var task = Assignment(title: "Lab", dueDate: now.addingTimeInterval(3600), reminder: .init(amount: 3, unit: .hours), now: now)
        XCTAssertEqual(DeadlineClassification.classify(task, now: now), .reminderReached)
        task.reminder = .none
        XCTAssertEqual(DeadlineClassification.classify(task, now: now), .dueSoon)
        task.dueDate = now
        XCTAssertEqual(DeadlineClassification.classify(task, now: now), .overdue)
        task.transition(to: .completed, at: now)
        XCTAssertEqual(DeadlineClassification.classify(task, now: now), .completed)
        task.transition(to: .active, at: now)
        task.transition(to: .abandoned, at: now)
        XCTAssertEqual(DeadlineClassification.classify(task, now: now), .abandoned)
        let abandoned = task
        task.transition(to: .active, at: now)
        var second = task; second.id = UUID()
        let values = [abandoned, task, second]
        let index = AssignmentDayIndex(assignments: values, now: now, calendar: calendar)
        XCTAssertEqual(index.day(now).dots, [.overdue, .abandoned])
        XCTAssertEqual(index.day(now).counts[.overdue], 2)
        XCTAssertEqual(index.day(now).assignments.count, 3)
        XCTAssertEqual(index.day(now).dots, AssignmentDayIndex(assignments: Array(values.reversed()), now: now, calendar: calendar).day(now).dots)
        XCTAssertTrue(index.day(now).accessibilitySummary.contains("2 overdue"))
    }
}
