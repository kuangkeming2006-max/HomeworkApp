import Foundation
import XCTest
import HomeworkDomain
@testable import HomeworkApp

@MainActor
final class CalendarTests: XCTestCase {
    func testMonthSelectionPreservesDayAndClampsFebruary() throws {
        let calendar = Calendar.current
        let january = try XCTUnwrap(calendar.date(from: DateComponents(year: 2028, month: 1, day: 31)))
        let model = CalendarViewModel(now: january)
        model.shiftMonth(1)
        XCTAssertEqual(model.calendar.component(.month, from: model.month), 2)
        XCTAssertEqual(model.calendar.component(.day, from: model.selectedDate), 29)
        XCTAssertEqual(model.direction, 1)
        model.shiftMonth(-1); XCTAssertEqual(model.direction, -1)
        XCTAssertEqual(model.calendar.component(.day, from: model.selectedDate), 29)
        model.today()
        XCTAssertTrue(model.calendar.isDateInToday(model.selectedDate))
    }

    func testCalendarIndexBenchmarkMatchesPreviousCellScans() {
        let calendar = Calendar.current
        let now = Date()
        let values = (0..<2000).map { index in
            Assignment(title: "Synthetic \(index)", dueDate: now.addingTimeInterval(Double(index % 42) * 86400))
        }
        let days = (0..<42).map { now.addingTimeInterval(Double($0) * 86400) }
        let clock = ContinuousClock()
        var oldCounts: [Int] = []
        let before = clock.measure {
            oldCounts = days.map { day in
                AssignmentQuery.apply(values.filter { calendar.isDate($0.dueDate, inSameDayAs: day) }, filter: .all).count
            }
        }
        var newCounts: [Int] = []
        let after = clock.measure {
            let index = AssignmentDayIndex(assignments: values, now: now, calendar: calendar)
            newCounts = days.map { index.day($0).assignments.count }
        }
        XCTAssertEqual(oldCounts, newCounts)
        print("PERFORMANCE calendar 2000 synthetic tasks / 42 days: previous scans=\(before), indexed build+lookup=\(after)")
    }
}
