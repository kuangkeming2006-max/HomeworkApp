import ActivityKit
import Foundation
import HomeworkDomain

@MainActor
final class ActivityKitClient: LiveActivityClient {
    var available: Bool {
        Bundle.main.object(forInfoDictionaryKey: "NSSupportsLiveActivities") as? Bool == true &&
            ActivityAuthorizationInfo().areActivitiesEnabled
    }
    var activities: [HomeworkLiveActivity] {
        Activity<HomeworkActivityAttributes>.activities.map { activity in
            let state = activity.content.state
            return .init(id: activity.id, assignmentID: activity.attributes.assignmentID, title: state.title,
                         course: state.course, deadline: state.deadline, start: state.start, priority: state.priority,
                         state: activity.activityState == .pending ? .pending :
                            (activity.activityState == .active || activity.activityState == .stale ? .active : .ended))
        }
    }

    func request(_ plan: LiveActivityPlan, now: Date) throws {
        let attributes = HomeworkActivityAttributes(assignmentID: plan.assignmentID)
        let content = Self.content(plan)
        if plan.start > now {
            // Verified by scripts/probe_activitykit.py against the installed Xcode 27 SDK.
            _ = try Activity.request(attributes: attributes, content: content, pushType: nil, style: .standard,
                                     alertConfiguration: .init(title: "Homework countdown", body: "\(plan.title) is due soon.", sound: .default),
                                     start: plan.start)
        } else {
            _ = try Activity.request(attributes: attributes, content: content, pushType: nil, style: .standard)
        }
    }

    nonisolated func update(_ id: String, plan: LiveActivityPlan) async {
        guard let activity = Activity<HomeworkActivityAttributes>.activities.first(where: { $0.id == id }) else { return }
        await activity.update(Self.content(plan))
    }

    nonisolated func end(_ id: String) async {
        guard let activity = Activity<HomeworkActivityAttributes>.activities.first(where: { $0.id == id }) else { return }
        await activity.end(nil, dismissalPolicy: .immediate)
    }

    private nonisolated static func content(_ plan: LiveActivityPlan) -> ActivityContent<HomeworkActivityAttributes.ContentState> {
        .init(state: .init(title: plan.title, course: plan.course, deadline: plan.deadline, start: plan.start,
                           priority: plan.priority.rawValue), staleDate: plan.deadline, relevanceScore: Double(5 - plan.priority.rawValue) / 4)
    }
}
