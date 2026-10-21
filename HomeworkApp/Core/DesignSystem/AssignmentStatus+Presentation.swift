import SwiftUI
import HomeworkDomain

extension AssignmentStatus {
    var categoryTitle: String { self == .active ? "Upcoming" : label }
    var markerColor: Color {
        switch self {
        case .active: .blue
        case .completed: .green
        case .abandoned: .gray
        }
    }
}
