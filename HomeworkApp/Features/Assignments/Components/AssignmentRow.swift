import SwiftUI
import HomeworkDomain

struct AssignmentRow: View {
    let assignment: Assignment
    var now: Date = .now

    var body: some View {
            let overdue = assignment.status == .active && assignment.dueDate < now
            VStack(alignment: .leading, spacing: 5) {
                Text(assignment.title).font(.body.weight(.semibold))
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                    .strikethrough(assignment.isCompleted)
                if let course = assignment.course, !course.isEmpty {
                    Text(course).font(.subheadline).foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                HStack(spacing: 8) {
                    Text(assignment.dueDate, format: .dateTime.month(.abbreviated).day().hour().minute())
                        .foregroundColor(overdue ? .red : .secondary)
                    if overdue { Text("Overdue").foregroundStyle(.red) }
                    else if assignment.status == .active, assignment.dueDate.timeIntervalSince(now) < 86_400 {
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
                if !assignment.attachments.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(Array(assignment.attachments.prefix(4))) { reference in
                            AttachmentThumbnail(reference: reference, size: 40)
                        }
                        if assignment.attachments.count > 4 {
                            Text("+\(assignment.attachments.count - 4)").font(.caption).foregroundStyle(.secondary)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading).clipped()
                }
            }
            .accessibilityElement(children: .combine)
    }
}
