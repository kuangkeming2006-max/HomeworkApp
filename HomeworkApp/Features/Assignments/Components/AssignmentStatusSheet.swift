import SwiftUI
import HomeworkDomain

struct AssignmentStatusSheet: View {
    let assignment: Assignment
    let store: AssignmentStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        card
        .presentationDetents([.custom(AssignmentActionDetent.self)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(30)
        .background(SheetOutsideTapDismissal { dismiss() }.frame(width: 0, height: 0))
        .accessibilityAction(.escape) { dismiss() }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(assignment.title).font(.title3.weight(.semibold)).lineLimit(2)
            VStack(spacing: 12) {
                if assignment.status == .active {
                    action("Complete", symbol: "checkmark", color: Color(red: 0.10, green: 0.55, blue: 0.25)) {
                        store.setStatus(assignment.id, to: .completed)
                    }
                    action("Abandon", symbol: "minus.circle", color: Color(uiColor: .systemGray)) {
                        store.setStatus(assignment.id, to: .abandoned)
                    }
                } else {
                    action("Restore", symbol: "arrow.uturn.backward", color: Color(red: 0.10, green: 0.55, blue: 0.25)) {
                        store.setStatus(assignment.id, to: .active)
                    }
                    action("Delete", symbol: "trash.fill", color: .red) { store.delete(assignment.id) }
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("assignment.status.sheet")
    }

    private func action(_ title: String, symbol: String, color: Color, perform: @escaping () -> Void) -> some View {
        Button {
            dismiss()
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.28), perform)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: symbol).font(.title3.weight(.semibold))
                Text(title).font(.headline).lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 36)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle(radius: 16))
        .controlSize(.large)
        .tint(color)
        .accessibilityIdentifier("assignment.status.\(title.lowercased())")
    }
}

private struct AssignmentActionDetent: CustomPresentationDetent {
    static func height(in context: Context) -> CGFloat? {
        min(context.maxDetentValue, context.dynamicTypeSize.isAccessibilitySize ? 420 : 280)
    }
}
