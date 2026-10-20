import SwiftUI
import HomeworkDomain

extension DeadlineClassification {
    var color: Color {
        switch self {
        case .overdue: .red
        case .reminderReached: .orange
        case .dueSoon: .yellow
        case .upcoming: .accentColor
        case .completed: .green
        case .abandoned: .gray
        }
    }
}
