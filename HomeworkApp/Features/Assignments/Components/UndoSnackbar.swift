import SwiftUI

struct UndoSnackbar: View {
    let coordinator: UndoCoordinator
    let undo: () -> Void
    var body: some View {
        if let action = coordinator.latest {
            HStack(spacing: 12) {
                TimelineView(.animation(minimumInterval: 0.1)) { context in
                    Circle().trim(from: 0, to: max(0, min(1, action.expiresAt.timeIntervalSince(context.date) / 5)))
                        .stroke(.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .rotationEffect(.degrees(-90)).frame(width: 18, height: 18)
                }.accessibilityHidden(true)
                Text(action.message).font(.subheadline).frame(maxWidth: .infinity, alignment: .leading)
                Button("Undo", action: undo).fontWeight(.semibold).accessibilityIdentifier("assignments.undo")
            }
            .padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
            .padding(.horizontal).padding(.bottom, 6)
            .accessibilityElement(children: .contain)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
