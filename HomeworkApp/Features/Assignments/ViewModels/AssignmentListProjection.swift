import Foundation
import Observation
import HomeworkDomain

@Observable @MainActor
final class AssignmentListProjection {
    enum Entry: Identifiable {
        case heading(AssignmentStatus)
        case assignment(Assignment)
        var id: String {
            switch self {
            case .heading(let status): "section.\(status.rawValue)"
            case .assignment(let value): value.id.uuidString
            }
        }
    }
    private(set) var entries: [Entry] = []
    private(set) var pendingVisibility: [UUID: Date] = [:]
    private var ordered: [Assignment] = []
    var nextExpiry: Date? { pendingVisibility.values.min() }

    func keepCompleted(_ id: UUID, until: Date = Date().addingTimeInterval(5)) {
        pendingVisibility[id] = until
    }
    func expire(at now: Date = Date()) -> Set<UUID> {
        let expired = Set(pendingVisibility.filter { $0.value <= now }.map(\.key))
        pendingVisibility = pendingVisibility.filter { !expired.contains($0.key) }
        return expired
    }
    func clearPending() { pendingVisibility.removeAll() }

    func rebuild(_ values: [Assignment], sort: AssignmentSort, filter: AssignmentFilter, search: String) {
        ordered = AssignmentQuery.apply(values, filter: .all, sort: sort)
            + AssignmentQuery.apply(values, filter: .deleted, sort: sort)
        let eligible = Set(values.filter { $0.deletedAt == nil && $0.status == .completed }.map(\.id))
        pendingVisibility = pendingVisibility.filter { eligible.contains($0.key) }
        refilter(filter: filter, search: search)
    }

    func refilter(filter: AssignmentFilter, search: String) {
        var values = AssignmentQuery.matching(ordered, filter: filter, search: search)
        if filter == .upcoming, !pendingVisibility.isEmpty {
            let matches = AssignmentQuery.matching(ordered, filter: .completed, search: search)
            let allowed = Set(values.map(\.id)).union(matches.filter { pendingVisibility[$0.id] != nil }.map(\.id))
            values = ordered.filter { allowed.contains($0.id) }
        }
        if filter == .all {
            entries = AssignmentStatus.allCases.flatMap { status in
                [Entry.heading(status)] + values.filter { $0.status == status }.map(Entry.assignment)
            }
        } else { entries = values.map(Entry.assignment) }
    }

    var isEmpty: Bool { !entries.contains { if case .assignment = $0 { true } else { false } } }
}
