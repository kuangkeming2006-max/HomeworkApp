import ActivityKit
import SwiftUI
import WidgetKit

@main
struct HomeworkWidgets: WidgetBundle {
    var body: some Widget { HomeworkDeadlineActivity() }
}

struct HomeworkDeadlineActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: HomeworkActivityAttributes.self) { context in
            DeadlineActivityContent(state: context.state)
                .padding().activityBackgroundTint(.black).activitySystemActionForegroundColor(.white)
                .widgetURL(deepLink(context.attributes.assignmentID))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("Deadline", systemImage: "doc.badge.clock").font(.caption.weight(.semibold))
                }
                DynamicIslandExpandedRegion(.trailing) { Text("P\(context.state.priority)").font(.caption.bold()) }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.title).font(.headline).lineLimit(2)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.state.course ?? "Keep going").font(.caption).lineLimit(1)
                        Spacer()
                        DeadlineCountdown(deadline: context.state.deadline).font(.title2.monospacedDigit().bold())
                    }
                }
            } compactLeading: {
                Image(systemName: "doc.badge.clock").foregroundStyle(.white)
            } compactTrailing: {
                DeadlineCountdown(deadline: context.state.deadline).font(.caption.monospacedDigit()).frame(maxWidth: 64)
            } minimal: {
                Image(systemName: "clock").foregroundStyle(.white)
            }
            .widgetURL(deepLink(context.attributes.assignmentID)).keylineTint(.white)
        }
    }

    private func deepLink(_ id: UUID) -> URL? { URL(string: "homework://assignment/\(id.uuidString)") }
}

#Preview("Lock Screen", as: .content, using: HomeworkActivityAttributes(assignmentID: UUID())) {
    HomeworkDeadlineActivity()
} contentStates: {
    HomeworkActivityAttributes.ContentState(title: "Networking lab report", course: "Computer networks",
                                            deadline: .now.addingTimeInterval(3600), start: .now, priority: 1)
}
