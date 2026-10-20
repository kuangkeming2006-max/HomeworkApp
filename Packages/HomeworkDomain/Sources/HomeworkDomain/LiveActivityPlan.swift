import Foundation

public struct LiveActivityPlan: Equatable, Sendable {
    public let assignmentID: UUID
    public let title: String
    public let course: String?
    public let deadline: Date
    public let start: Date
    public let priority: Priority

    /// One activity, at most four hours before its deadline. Longer lead times remain notifications.
    public static func next(_ assignments: [Assignment], now: Date) -> Self? {
        let candidates = AssignmentQuery.apply(assignments).filter {
            $0.dueDate > now && $0.reminder.amount > 0 && (try? $0.validate()) != nil
        }
        let plans: [Self] = candidates.compactMap { task in
            guard let zone = TimeZone(identifier: task.dueTimeZone),
                  let reminder = task.reminder.fireDate(dueDate: task.dueDate, timeZone: zone) else { return nil }
            return .init(assignmentID: task.id, title: task.title, course: task.course,
                         deadline: task.dueDate, start: max(reminder, task.dueDate.addingTimeInterval(-4 * 3600)), priority: task.priority)
        }
        // First service the current countdown window, then the next window. Priority breaks overlaps.
        return plans.sorted {
            let lhsActive = $0.start <= now; let rhsActive = $1.start <= now
            if lhsActive != rhsActive { return lhsActive }
            if lhsActive && $0.priority != $1.priority { return $0.priority.rawValue < $1.priority.rawValue }
            if $0.start != $1.start { return $0.start < $1.start }
            if $0.deadline != $1.deadline { return $0.deadline < $1.deadline }
            return $0.assignmentID.uuidString < $1.assignmentID.uuidString
        }.first
    }
}

public enum HomeworkRoute: Equatable, Sendable {
    case assignment(UUID), briefing
    public var url: URL? {
        switch self {
        case .assignment(let id): URL(string: "homework://assignment/\(id.uuidString)")
        case .briefing: URL(string: "homework://briefing")
        }
    }
    public init?(url: URL) {
        guard url.scheme == "homework", url.user == nil, url.password == nil, url.query == nil, url.fragment == nil else { return nil }
        if url.host == "briefing", url.path.isEmpty || url.path == "/" { self = .briefing }
        else if url.host == "assignment", let id = UUID(uuidString: String(url.path.dropFirst())) { self = .assignment(id) }
        else { return nil }
    }
}
