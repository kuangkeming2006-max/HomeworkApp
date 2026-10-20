import Foundation

public struct MonthGrid: Sendable {
    public let month: Date
    public let days: [Date?]

    public init(containing date: Date, calendar: Calendar) {
        let start = calendar.dateInterval(of: .month, for: date)?.start ?? date
        month = start
        let leading = (calendar.component(.weekday, from: start) - calendar.firstWeekday + 7) % 7
        let count = calendar.range(of: .day, in: .month, for: start)?.count ?? 0
        var result: [Date?] = Array(repeating: nil, count: leading)
        result += (0..<count).map { calendar.date(byAdding: .day, value: $0, to: start) }
        while result.count % 7 != 0 { result.append(nil) }
        days = result
    }
}
