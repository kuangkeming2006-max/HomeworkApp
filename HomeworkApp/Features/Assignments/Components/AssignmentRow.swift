import SwiftUI
import HomeworkDomain

struct AssignmentRow: View {
    let assignment: Assignment

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let overdue = !assignment.isCompleted && assignment.dueDate < context.date
            VStack(alignment: .leading, spacing: 5) {
                Text(assignment.title).font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .strikethrough(assignment.isCompleted)
                if let course = assignment.course, !course.isEmpty {
                    Text(course).font(.subheadline).foregroundStyle(.secondary)
                }
                HStack(spacing: 8) {
                    Text(assignment.dueDate, format: .dateTime.month(.abbreviated).day().hour().minute())
                        .foregroundColor(overdue ? .red : .secondary)
                    if overdue { Text("Overdue").foregroundStyle(.red) }
                    else if !assignment.isCompleted, assignment.dueDate.timeIntervalSince(context.date) < 86_400 {
                        Text("Due soon").foregroundStyle(.orange)
                    }
                    Spacer(minLength: 0)
                    if !assignment.attachments.isEmpty {
                        Label("\(assignment.attachments.count)", systemImage: "paperclip")
                    }
                    Text("P\(assignment.priority.rawValue)")
                        .fontWeight(.semibold)
                        .foregroundColor(assignment.priority == .urgent ? .red : .secondary)
                        .accessibilityLabel(assignment.priority.label)
                }
                .font(.caption)
            }
            .accessibilityElement(children: .combine)
        }
    }
}
