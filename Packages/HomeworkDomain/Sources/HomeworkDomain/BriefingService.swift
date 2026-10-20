import Foundation

public struct BriefingConfiguration: Codable, Equatable, Sendable {
    public enum Frequency: String, Codable, CaseIterable, Identifiable, Sendable {
        case twiceDaily, daily, weekly
        public var id: String { rawValue }
        public var label: String {
            switch self { case .twiceDaily: "Every 12 hours"; case .daily: "Daily"; case .weekly: "Weekly" }
        }
    }
    public var enabled: Bool
    public var frequency: Frequency
    public var hour: Int
    public var minute: Int
    public var weekday: Int
    public init(enabled: Bool = false, frequency: Frequency = .daily, hour: Int = 9, minute: Int = 0, weekday: Int = 2) {
        self.enabled = enabled; self.frequency = frequency; self.hour = hour; self.minute = minute; self.weekday = weekday
    }
}

public struct BriefingReport: Codable, Equatable, Sendable, Identifiable {
    public struct Highlight: Codable, Equatable, Sendable {
        public let id: UUID
        public let title: String
        public let course: String?
        public let deadline: Date
    }
    public let day: Date
    public let recordedAt: Date
    public let remaining: Int
    public let completedToday: Int
    public let dueWithin24Hours: Int
    public let overdue: Int
    public let dueToday: Int
    public let completedDueToday: Int
    public let mostUrgent: Highlight?
    public var id: Date { day }
    public var progress: Double { dueToday == 0 ? 0 : Double(completedDueToday) / Double(dueToday) }
}

public struct PlannedBriefing: Equatable, Sendable {
    public let identifier: String
    public let fireDate: Date
    public let title: String
    public let body: String
}

public enum BriefingService {
    public static func report(_ values: [Assignment], now: Date, calendar: Calendar = .current) -> BriefingReport {
        let visible = values.filter { $0.deletedAt == nil }
        let active = visible.filter { $0.status == .active }
        let dueToday = visible.filter { $0.status != .abandoned && calendar.isDate($0.dueDate, inSameDayAs: now) }
        let urgent = AssignmentQuery.apply(active.filter { $0.dueDate > now }).first
        return BriefingReport(day: calendar.startOfDay(for: now), recordedAt: now, remaining: active.count,
                              completedToday: visible.filter { $0.completedAt.map { calendar.isDate($0, inSameDayAs: now) } ?? false }.count,
                              dueWithin24Hours: active.filter { $0.dueDate > now && $0.dueDate <= now.addingTimeInterval(86400) }.count,
                              overdue: active.filter { $0.dueDate < now }.count, dueToday: dueToday.count,
                              completedDueToday: dueToday.filter { $0.status == .completed }.count,
                              mostUrgent: urgent.map { .init(id: $0.id, title: $0.title, course: $0.course, deadline: $0.dueDate) })
    }

    /// Finite, nonrepeating requests: content is a projection from the last known local data.
    public static func plan(_ values: [Assignment], configuration: BriefingConfiguration, now: Date,
                            calendar: Calendar = .current, limit: Int = 7) -> [PlannedBriefing] {
        guard configuration.enabled, (0...23).contains(configuration.hour), (0...59).contains(configuration.minute),
              (1...7).contains(configuration.weekday), limit > 0 else { return [] }
        var cursor = now
        var result: [PlannedBriefing] = []
        for _ in 0..<min(limit, 14) {
            var match = DateComponents(hour: configuration.hour, minute: configuration.minute, second: 0)
            if configuration.frequency == .weekly { match.weekday = configuration.weekday }
            var next = calendar.nextDate(after: cursor, matching: match, matchingPolicy: .nextTime, repeatedTimePolicy: .first)
            if configuration.frequency == .twiceDaily {
                var second = match; second.hour = (configuration.hour + 12) % 24
                if let other = calendar.nextDate(after: cursor, matching: second, matchingPolicy: .nextTime, repeatedTimePolicy: .first) {
                    next = next.map { min($0, other) } ?? other
                }
            }
            guard let fire = next else { break }
            let report = report(values, now: fire, calendar: calendar)
            var body = "\(report.remaining) remaining · \(report.completedToday) completed today · \(report.overdue) overdue."
            if let urgent = report.mostUrgent {
                let formatter = DateFormatter(); formatter.locale = Locale(identifier: "en_US")
                formatter.calendar = calendar; formatter.timeZone = calendar.timeZone
                formatter.dateStyle = .medium; formatter.timeStyle = .short
                body += " Next: \(urgent.title), \(formatter.string(from: urgent.deadline))."
            } else { body += " You're all caught up with upcoming deadlines." }
            result.append(.init(identifier: "briefing.\(Int(fire.timeIntervalSince1970))", fireDate: fire,
                                title: "Your Homework Report", body: body))
            cursor = fire.addingTimeInterval(1)
        }
        return result
    }
}
