import SwiftUI
import HomeworkDomain

struct AssignmentRow: View {
    let assignment: Assignment
    var now: Date = .now
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
            let classification = DeadlineClassification.classify(assignment, now: now)
            let overdue = classification == .overdue
            VStack(alignment: .leading, spacing: 5) {
                Text(assignment.title).font(.body.weight(.semibold))
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                    .strikethrough(assignment.isCompleted)
                if let course = assignment.course, !course.isEmpty {
                    Text(course).font(.subheadline).foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Group {
                    if typeSize.isAccessibilitySize {
                        VStack(alignment: .leading, spacing: 5) {
                            deadline(overdue: overdue)
                            HStack { status(classification); Spacer(minLength: 0); indicators }
                        }
                    } else {
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 8) {
                                deadline(overdue: overdue).fixedSize()
                                status(classification).fixedSize()
                                Spacer(minLength: 0)
                                indicators.fixedSize()
                            }
                            VStack(alignment: .leading, spacing: 5) {
                                deadline(overdue: overdue)
                                HStack { status(classification); Spacer(minLength: 0); indicators }
                            }
                        }
                    }
                }.font(.caption)
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

    private func deadline(overdue: Bool) -> some View {
        Text(assignment.dueDate, format: .dateTime.month(.abbreviated).day().hour().minute())
            .foregroundStyle(overdue ? .red : .secondary).lineLimit(2)
    }

    @ViewBuilder private func status(_ classification: DeadlineClassification) -> some View {
        switch classification {
        case .overdue: Text("Overdue").foregroundStyle(.red)
        case .reminderReached: Text("Reminder reached").foregroundStyle(.orange)
        case .dueSoon: Text("Due soon").foregroundStyle(.secondary)
        case .abandoned: Text("Abandoned").foregroundStyle(.secondary)
        case .completed, .upcoming: EmptyView()
        }
    }

    private var indicators: some View {
        HStack(spacing: 8) {
            if !assignment.attachments.isEmpty {
                Label("\(assignment.attachments.count)", systemImage: "paperclip").lineLimit(1)
            }
            Text("P\(assignment.priority.rawValue)").fontWeight(.semibold)
                .foregroundStyle(assignment.priority == .urgent ? .red : .secondary)
                .accessibilityLabel(assignment.priority.label)
        }
    }
}
