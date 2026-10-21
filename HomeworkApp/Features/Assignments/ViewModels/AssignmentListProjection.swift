import Foundation
import Observation
import HomeworkDomain

@Observable @MainActor
final class AssignmentListProjection {
    struct StatusSection: Identifiable {
        let id: AssignmentStatus
        let title: String
        let rows: [Assignment]
    }
    private(set) var sections: [StatusSection] = []
    private var ordered: [Assignment] = []
    func rebuild(_ values: [Assignment], sort: AssignmentSort, search: String) {
        ordered = AssignmentQuery.apply(values, filter: .all, sort: sort)
        refilter(search: search)
    }
    func refilter(search: String) {
        let values = AssignmentQuery.matching(ordered, filter: .all, search: search)
        let groups = Dictionary(grouping: values, by: \.status)
        sections = [StatusSection(id: .active, title: "Upcoming", rows: groups[.active] ?? []),
                    StatusSection(id: .completed, title: "Completed", rows: groups[.completed] ?? []),
                    StatusSection(id: .abandoned, title: "Abandoned", rows: groups[.abandoned] ?? [])]
    }
}
