import ActivityKit
import Foundation

struct HomeworkActivityAttributes: ActivityAttributes, Sendable {
    struct ContentState: Codable, Hashable, Sendable {
        var title: String
        var course: String?
        var deadline: Date
        var start: Date
        var priority: Int
    }
    var assignmentID: UUID
}
