import Foundation

public enum AssignmentStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case active, completed, abandoned
    public var id: String { rawValue }
    public var label: String { rawValue.capitalized }
}

/// The reversible fields of an action, independent from concurrent edits to task content.
public struct AssignmentDisposition: Equatable, Sendable {
    public var status: AssignmentStatus
    public var completedAt: Date?
    public var abandonedAt: Date?
    public var deletedAt: Date?

    public init(_ assignment: Assignment) {
        status = assignment.status; completedAt = assignment.completedAt
        abandonedAt = assignment.abandonedAt; deletedAt = assignment.deletedAt
    }

    public func apply(to assignment: inout Assignment) {
        assignment.status = status; assignment.completedAt = completedAt
        assignment.abandonedAt = abandonedAt; assignment.deletedAt = deletedAt
    }
}
