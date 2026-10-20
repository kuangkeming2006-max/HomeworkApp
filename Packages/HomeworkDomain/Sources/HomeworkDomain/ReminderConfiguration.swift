import Foundation

public struct ReminderConfiguration: Codable, Equatable, Hashable, Sendable {
    public enum Unit: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
        case minutes, hours, days, weeks
        public var id: String { rawValue }
    }
    public var amount: Int
    public var unit: Unit
    public static let none = ReminderConfiguration(amount: 0, unit: .minutes)

    public init(amount: Int, unit: Unit) { self.amount = amount; self.unit = unit }

    public var label: String {
        amount == 0 ? "None" : "\(amount) \(unit.rawValue) before"
    }

    public static let presets: [Self] = [
        .none, .init(amount: 5, unit: .minutes), .init(amount: 30, unit: .minutes),
        .init(amount: 1, unit: .hours), .init(amount: 3, unit: .hours),
        .init(amount: 1, unit: .days), .init(amount: 3, unit: .days), .init(amount: 1, unit: .weeks)
    ]

    public func validate() throws {
        let maximum: Int
        switch unit {
        case .minutes: maximum = 525_600
        case .hours: maximum = 8_760
        case .days: maximum = 365
        case .weeks: maximum = 52
        }
        guard (0...maximum).contains(amount) else {
            throw AssignmentError.invalid("Choose a reminder within one year of the deadline.")
        }
    }

    /// Calendar days and weeks preserve wall time across daylight-saving transitions.
    public func fireDate(dueDate: Date, timeZone: TimeZone) -> Date? {
        guard amount > 0 else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        switch unit {
        case .minutes: return dueDate.addingTimeInterval(-Double(amount) * 60)
        case .hours: return dueDate.addingTimeInterval(-Double(amount) * 3600)
        case .days: return calendar.date(byAdding: .day, value: -amount, to: dueDate)
        case .weeks: return calendar.date(byAdding: .day, value: -amount * 7, to: dueDate)
        }
    }
}
