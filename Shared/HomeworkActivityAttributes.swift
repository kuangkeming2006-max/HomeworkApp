import ActivityKit
import Foundation

struct HomeworkActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var title: String
        var course: String?
        var deadline: Date
        var start: Date
        var priority: Int
    }
    var assignmentID: UUID
}
