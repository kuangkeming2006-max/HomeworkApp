import Foundation
import Observation
import HomeworkDomain

@Observable @MainActor
final class CalendarViewModel {
    var month: Date
    var selectedDate: Date
    private(set) var calendar: Calendar
    private(set) var index: AssignmentDayIndex
    private(set) var direction = 1

    init(now: Date = Date()) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US")
        calendar.timeZone = .current
        calendar.firstWeekday = 2
        self.calendar = calendar
        index = AssignmentDayIndex(assignments: [], now: now, calendar: calendar)
        month = calendar.dateInterval(of: .month, for: now)?.start ?? now
        selectedDate = calendar.startOfDay(for: now)
    }

    var grid: MonthGrid { MonthGrid(containing: month, calendar: calendar) }
    var weekdaySymbols: [String] {
        let symbols = calendar.shortStandaloneWeekdaySymbols
        return Array(symbols.dropFirst()) + [symbols[0]]
    }

    func shiftMonth(_ offset: Int) {
        guard let next = calendar.date(byAdding: .month, value: offset, to: month) else { return }
        selectMonth(next)
    }

    func selectMonth(_ next: Date) {
        direction = next >= month ? 1 : -1
        let day = calendar.component(.day, from: selectedDate)
        month = calendar.dateInterval(of: .month, for: next)?.start ?? next
        let maximum = calendar.range(of: .day, in: .month, for: month)?.count ?? 28
        selectedDate = calendar.date(byAdding: .day, value: min(day, maximum) - 1, to: month) ?? month
    }

    func today() {
        selectedDate = calendar.startOfDay(for: Date())
        month = calendar.dateInterval(of: .month, for: selectedDate)?.start ?? selectedDate
    }

    func rebuild(_ values: [Assignment], now: Date) {
        calendar.timeZone = .current
        index = AssignmentDayIndex(assignments: values, now: now, calendar: calendar)
    }

    func identifier(for day: Date) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: day)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
}
