import SwiftUI
import HomeworkDomain

struct AssignmentStatusSheet: View {
    let assignment: Assignment
    let store: AssignmentStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.28)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { dismiss() }
                .accessibilityHidden(true)

            card
                .frame(maxWidth: 560)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .presentationBackground(.clear)
        .interactiveDismissDisabled()
        .accessibilityAction(.escape) { dismiss() }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(assignment.title).font(.headline).lineLimit(2)
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
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 28))
        .contentShape(RoundedRectangle(cornerRadius: 28))
        // The card consumes taps in its title and padding; only the surrounding
        // backdrop dismisses. Descendant buttons retain their own actions.
        .onTapGesture {}
        .accessibilityElement(children: .contain)
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
            .frame(maxWidth: .infinity, minHeight: 56)
            .foregroundStyle(.white)
            .background(color, in: RoundedRectangle(cornerRadius: 14))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("assignment.status.\(title.lowercased())")
    }
}
