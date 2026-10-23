import Foundation

public enum AssignmentFilter: String, CaseIterable, Identifiable, Sendable {
    case all = "All", upcoming = "Upcoming", completed = "Completed", abandoned = "Abandoned", deleted = "Deleted"
    public var id: String { rawValue }
}

public enum AssignmentSort: String, CaseIterable, Identifiable, Sendable {
    case priority = "Priority", deadline = "Deadline"
    public var id: String { rawValue }
}

public enum AssignmentQuery {
    public static func apply(_ assignments: [Assignment], filter: AssignmentFilter = .upcoming,
                             sort: AssignmentSort = .priority, search: String = "") -> [Assignment] {
        matching(assignments, filter: filter, search: search).sorted {
            if sort == .priority, $0.priority != $1.priority { return $0.priority.rawValue < $1.priority.rawValue }
            if $0.dueDate != $1.dueDate { return $0.dueDate < $1.dueDate }
            if $0.createdAt != $1.createdAt { return $0.createdAt < $1.createdAt }
            return $0.id.uuidString < $1.id.uuidString
        }
    }

    /// Filters an already ordered projection without sorting it again on every search keystroke.
    public static func matching(_ assignments: [Assignment], filter: AssignmentFilter, search: String) -> [Assignment] {
        let term = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return assignments.filter {
            let matchesStatus = switch filter {
            case .upcoming: $0.status == .active
            case .completed: $0.status == .completed
            case .abandoned: $0.status == .abandoned
            case .all, .deleted: true
            }
            let matchesDeletion = filter == .deleted ? $0.deletedAt != nil : $0.deletedAt == nil
            return matchesDeletion && matchesStatus && (term.isEmpty ||
                [$0.title, $0.course ?? "", $0.notes ?? ""].contains { $0.localizedStandardContains(term) })
        }
    }
}
