import Foundation

public enum DeadlineClassification: String, CaseIterable, Identifiable, Sendable {
    // Stable dot order prioritizes active work, then terminal states.
    case overdue, reminderReached, dueSoon, upcoming, completed, abandoned
    public var id: String { rawValue }
    public var label: String {
        switch self {
        case .overdue: "Overdue"
        case .reminderReached: "Reminder reached"
        case .dueSoon: "Due within 24 hours"
        case .upcoming: "Upcoming"
        case .completed: "Completed"
        case .abandoned: "Abandoned"
        }
    }

    public static func classify(_ task: Assignment, now: Date) -> Self {
        if task.status == .abandoned { return .abandoned }
        if task.status == .completed { return .completed }
        if task.dueDate <= now { return .overdue }
        if let zone = TimeZone(identifier: task.dueTimeZone),
           let reminder = task.reminder.fireDate(dueDate: task.dueDate, timeZone: zone), reminder <= now {
            return .reminderReached
        }
        if task.dueDate.timeIntervalSince(now) < 86_400 { return .dueSoon }
        return .upcoming
    }
}

public struct AssignmentDayIndex: Sendable {
    public struct Day: Sendable {
        public let assignments: [Assignment]
        public let counts: [DeadlineClassification: Int]
        public var dots: [DeadlineClassification] { DeadlineClassification.allCases.filter { counts[$0, default: 0] > 0 } }
        public var accessibilitySummary: String {
            dots.map { "\(counts[$0, default: 0]) \($0.label.lowercased())" }.joined(separator: ", ")
        }
    }
    private let days: [Date: Day]
    private let calendar: Calendar

    public init(assignments: [Assignment], now: Date, calendar: Calendar) {
        self.calendar = calendar
        let grouped = Dictionary(grouping: AssignmentQuery.apply(assignments, filter: .all)) {
            calendar.startOfDay(for: $0.dueDate)
        }
        days = grouped.mapValues { values in
            var counts: [DeadlineClassification: Int] = [:]
            for task in values { counts[DeadlineClassification.classify(task, now: now), default: 0] += 1 }
            return Day(assignments: values, counts: counts)
        }
    }

    public func day(_ date: Date) -> Day {
        days[calendar.startOfDay(for: date)] ?? Day(assignments: [], counts: [:])
    }
}
