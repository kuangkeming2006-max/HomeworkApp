import Foundation
import XCTest
@testable import HomeworkDomain

final class BriefingTests: XCTestCase {
    func testReportUsesExplicitDailyDenominatorAndRecordedCompletions() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 10, day: 20, hour: 12)))
        let active = Assignment(title: "Upcoming", dueDate: now.addingTimeInterval(3600), now: now)
        var completed = active; completed.id = UUID(); completed.transition(to: .completed, at: now)
        var abandoned = active; abandoned.id = UUID(); abandoned.transition(to: .abandoned, at: now)
        var overdue = active; overdue.id = UUID(); overdue.dueDate = now.addingTimeInterval(-3600)
        var deleted = active; deleted.id = UUID(); deleted.deletedAt = now
        var futureCompleted = active; futureCompleted.id = UUID(); futureCompleted.dueDate = now.addingTimeInterval(86400 * 3)
        futureCompleted.transition(to: .completed, at: now)
        let report = BriefingService.report([active, completed, abandoned, overdue, deleted, futureCompleted], now: now, calendar: calendar)
        XCTAssertEqual(report.remaining, 2); XCTAssertEqual(report.completedToday, 2)
        XCTAssertEqual(report.dueWithin24Hours, 1); XCTAssertEqual(report.overdue, 1)
        XCTAssertEqual(report.dueToday, 3); XCTAssertEqual(report.completedDueToday, 1)
        XCTAssertEqual(report.progress, 1.0 / 3.0); XCTAssertEqual(report.mostUrgent?.id, active.id)
    }

    func testFiniteBriefingScheduleRespectsFrequencyDSTAndDisabledPreference() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "America/New_York"))
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 3, day: 7, hour: 10)))
        XCTAssertTrue(BriefingService.plan([], configuration: .init(), now: now, calendar: calendar).isEmpty)
        let daily = BriefingService.plan([], configuration: .init(enabled: true), now: now, calendar: calendar)
        XCTAssertEqual(daily.count, 7); XCTAssertTrue(daily.allSatisfy { $0.fireDate > now && calendar.component(.hour, from: $0.fireDate) == 9 })
        XCTAssertEqual(Set(daily.map(\.identifier)).count, 7)
        let twice = BriefingService.plan([], configuration: .init(enabled: true, frequency: .twiceDaily), now: now, calendar: calendar)
        XCTAssertEqual(calendar.component(.hour, from: try XCTUnwrap(twice.first).fireDate), 21)
        let weekly = BriefingService.plan([], configuration: .init(enabled: true, frequency: .weekly, weekday: 2), now: now, calendar: calendar)
        XCTAssertTrue(weekly.allSatisfy { calendar.component(.weekday, from: $0.fireDate) == 2 })
    }

    func testLiveActivityUsesOneFinalWindowAndExcludesTerminalTasks() throws {
        let now = Date()
        var task = Assignment(title: "Report", dueDate: now.addingTimeInterval(3 * 86400), reminder: .init(amount: 1, unit: .days))
        let plan = try XCTUnwrap(LiveActivityPlan.next([task], now: now))
        XCTAssertEqual(plan.start, task.dueDate.addingTimeInterval(-4 * 3600))
        task.transition(to: .abandoned, at: now)
        XCTAssertNil(LiveActivityPlan.next([task], now: now))
        task.transition(to: .active, at: now)
        task.transition(to: .completed, at: now)
        XCTAssertNil(LiveActivityPlan.next([task], now: now))
        task.transition(to: .active, at: now); task.deletedAt = now
        XCTAssertNil(LiveActivityPlan.next([task], now: now))
    }

    func testRoutesValidateUUIDAndMessageContainsRemainingTime() throws {
        let id = UUID()
        let url = try XCTUnwrap(HomeworkRoute.assignment(id).url)
        XCTAssertEqual(HomeworkRoute(url: url), .assignment(id))
        XCTAssertNil(HomeworkRoute(url: try XCTUnwrap(URL(string: "https://assignment/\(id)"))))
        XCTAssertNil(HomeworkRoute(url: try XCTUnwrap(URL(string: "homework://assignment/not-a-uuid"))))
        XCTAssertTrue(ReminderMessage.body(deadline: Date(timeIntervalSince1970: 10800), fireDate: Date(timeIntervalSince1970: 0)).contains("3 hours"))
    }
}
