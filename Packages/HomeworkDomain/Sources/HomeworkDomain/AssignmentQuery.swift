import Foundation

public enum AssignmentFilter: String, CaseIterable, Identifiable, Sendable {
    case upcoming = "Upcoming", completed = "Completed", all = "All"
    public var id: String { rawValue }
}

public enum AssignmentSort: String, CaseIterable, Identifiable, Sendable {
    case priority = "Priority", deadline = "Deadline"
    public var id: String { rawValue }
}

public enum AssignmentQuery {
    public static func apply(_ assignments: [Assignment], filter: AssignmentFilter = .upcoming,
                             sort: AssignmentSort = .priority) -> [Assignment] {
        assignments.filter {
            $0.deletedAt == nil && (filter == .all || $0.isCompleted == (filter == .completed))
        }.sorted {
            if sort == .priority, $0.priority != $1.priority { return $0.priority.rawValue < $1.priority.rawValue }
            if $0.dueDate != $1.dueDate { return $0.dueDate < $1.dueDate }
            if $0.createdAt != $1.createdAt { return $0.createdAt < $1.createdAt }
            return $0.id.uuidString < $1.id.uuidString
        }
    }
}
