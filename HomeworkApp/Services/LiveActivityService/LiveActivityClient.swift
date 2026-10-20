import Foundation
import HomeworkDomain

struct HomeworkLiveActivity: Equatable {
    enum State { case pending, active, ended }
    let id: String
    let assignmentID: UUID
    let title: String
    let course: String?
    let deadline: Date
    let start: Date
    let priority: Int
    let state: State

    func matches(_ plan: LiveActivityPlan) -> Bool {
        assignmentID == plan.assignmentID && title == plan.title && course == plan.course && deadline == plan.deadline &&
        start == plan.start && priority == plan.priority.rawValue
    }
}

@MainActor
protocol LiveActivityClient {
    var available: Bool { get }
    var activities: [HomeworkLiveActivity] { get }
    func request(_ plan: LiveActivityPlan, now: Date) throws
    func update(_ id: String, plan: LiveActivityPlan) async
    func end(_ id: String) async
}
