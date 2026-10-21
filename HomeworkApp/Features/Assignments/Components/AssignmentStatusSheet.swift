import SwiftUI
import HomeworkDomain

struct AssignmentStatusSheet: View {
    let assignment: Assignment
    let store: AssignmentStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.appAccent) private var accent

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(assignment.title).font(.headline).lineLimit(2)
            HStack(spacing: 12) {
                if assignment.status == .active {
                    action("Complete", symbol: "checkmark.circle.fill", color: .green) {
                        store.setStatus(assignment.id, to: .completed)
                    }
                    action("Abandon", symbol: "minus.circle.fill", color: .secondary) {
                        store.setStatus(assignment.id, to: .abandoned)
                    }
                } else {
                    action("Restore", symbol: "arrow.uturn.backward.circle.fill", color: accent) {
                        store.setStatus(assignment.id, to: .active)
                    }
                    action("Delete", symbol: "trash.fill", color: .red) { store.delete(assignment.id) }
                }
                action("Cancel", symbol: "xmark.circle.fill", color: .secondary) {}
            }
        }
        .padding(20).padding(.top, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .presentationDetents([.height(230)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(20)
    }

    private func action(_ title: String, symbol: String, color: Color, perform: @escaping () -> Void) -> some View {
        Button {
            dismiss()
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.28), perform)
        } label: {
            VStack(spacing: 10) {
                Image(systemName: symbol).font(.title)
                Text(title).font(.subheadline.weight(.semibold)).lineLimit(2).minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, minHeight: 100)
            .foregroundStyle(color)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("assignment.status.\(title.lowercased())")
    }
}
