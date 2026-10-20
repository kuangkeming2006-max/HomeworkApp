import Foundation
import XCTest
@testable import HomeworkDomain

final class AssignmentTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_792_454_400)

    func testPriorityThenDeadlineAndStableTieBreak() {
        var low = Assignment(title: "Low", dueDate: now, priority: .low, now: now)
        let urgent = Assignment(title: "Urgent", dueDate: now.addingTimeInterval(3600), priority: .urgent, now: now)
        let earlier = Assignment(title: "Earlier", dueDate: now, priority: .urgent, now: now)
        low.id = UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? low.id
        let source = [low, urgent, earlier]
        XCTAssertEqual(AssignmentQuery.apply(source).map(\.title), ["Earlier", "Urgent", "Low"])
        XCTAssertEqual(AssignmentQuery.apply(source, sort: .deadline).last?.title, "Urgent")
        let sorted = AssignmentQuery.apply(source)
        XCTAssertEqual(AssignmentQuery.apply(Array(source.reversed())), sorted)
    }

    func testCompletedAndDeletedFiltering() {
        var completed = Assignment(title: "Completed", dueDate: now, now: now)
        completed.isCompleted = true; completed.completedAt = now
        var deleted = Assignment(title: "Deleted", dueDate: now, now: now)
        deleted.deletedAt = now
        let active = Assignment(title: "Active", dueDate: now, now: now)
        XCTAssertEqual(AssignmentQuery.apply([completed, deleted, active]).map(\.title), ["Active"])
        XCTAssertEqual(AssignmentQuery.apply([completed, deleted, active], filter: .completed).map(\.title), ["Completed"])
        XCTAssertEqual(AssignmentQuery.apply([completed, deleted, active], filter: .all).count, 2)
    }

    func testValidationAndRoundTrip() throws {
        var assignment = Assignment(title: "  ", dueDate: now, now: now)
        XCTAssertThrowsError(try assignment.validate())
        assignment.title = "Report"
        assignment.dueTimeZone = "not/a/zone"
        XCTAssertThrowsError(try assignment.validate())
        assignment.dueTimeZone = "Asia/Tokyo"
        try assignment.validate()
        XCTAssertEqual(try JSONDecoder().decode(Assignment.self, from: JSONEncoder().encode(assignment)), assignment)
        assignment.isCompleted = true
        XCTAssertThrowsError(try assignment.validate())
    }

    func testCalendarDaysRespectDST() throws {
        let zone = try XCTUnwrap(TimeZone(identifier: "America/New_York"))
        let due = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-03-08T16:00:00Z"))
        let fire = try XCTUnwrap(ReminderConfiguration(amount: 1, unit: .days).fireDate(dueDate: due, timeZone: zone))
        XCTAssertEqual(due.timeIntervalSince(fire), 23 * 3600)
        XCTAssertNil(ReminderConfiguration.none.fireDate(dueDate: due, timeZone: zone))
    }

    func testLeapMonthAndGridPadding() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        calendar.firstWeekday = 2
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2028, month: 2, day: 15)))
        let grid = MonthGrid(containing: date, calendar: calendar)
        XCTAssertEqual(grid.days.compactMap { $0 }.count, 29)
        XCTAssertEqual(grid.days.count % 7, 0)
        XCTAssertEqual(grid.days.first.flatMap { $0 }, nil)
    }
}
