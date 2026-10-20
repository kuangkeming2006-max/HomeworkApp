import Foundation
import Observation
import HomeworkDomain

@Observable @MainActor
final class AssignmentListProjection {
    private(set) var rows: [Assignment] = []
    private var ordered: [Assignment] = []
    func rebuild(_ values: [Assignment], sort: AssignmentSort, filter: AssignmentFilter, search: String) {
        ordered = AssignmentQuery.apply(values, filter: .all, sort: sort)
        refilter(filter, search: search)
    }
    func refilter(_ filter: AssignmentFilter, search: String) {
        rows = AssignmentQuery.matching(ordered, filter: filter, search: search)
    }
}
