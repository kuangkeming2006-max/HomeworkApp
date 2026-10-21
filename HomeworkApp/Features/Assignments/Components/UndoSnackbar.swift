import SwiftUI

struct UndoSnackbar: View {
    let coordinator: UndoCoordinator
    let undo: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var displayedAction: UndoCoordinator.Action?
    @State private var visible = false
    @State private var generation = UUID()
    var body: some View {
      ZStack(alignment: .bottom) {
        if let action = displayedAction {
            HStack(spacing: 12) {
                TimelineView(.periodic(from: action.expiresAt.addingTimeInterval(-5), by: 1)) { context in
                    let seconds = max(0, min(5, ceil(action.expiresAt.timeIntervalSince(context.date))))
                    ZStack {
                        Circle().stroke(.primary.opacity(0.18), lineWidth: 2)
                        Circle().trim(from: 0, to: seconds / 5)
                            .stroke(.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(reduceMotion ? nil : .easeInOut(duration: 0.32), value: seconds)
                        Text("\(Int(seconds))").font(.system(size: 10, weight: .semibold)).monospacedDigit()
                    }.frame(width: 24, height: 24)
                }.id(action.id).accessibilityHidden(true)
                Text(action.message).font(.subheadline).frame(maxWidth: .infinity, alignment: .leading)
                Button("Undo", action: undo).fontWeight(.semibold).accessibilityIdentifier("assignments.undo")
                    .disabled(coordinator.latest?.id != action.id)
            }
            .padding().glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
            .frame(maxWidth: 600)
            .padding(.horizontal).padding(.bottom, 6)
            .accessibilityElement(children: .contain)
            .opacity(visible ? 1 : 0)
            .offset(y: visible || reduceMotion ? 0 : 28)
            .scaleEffect(visible || reduceMotion ? 1 : 0.96, anchor: .bottom)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
      }
      .frame(maxWidth: .infinity)
      .allowsHitTesting(visible)
      .onChange(of: coordinator.latest?.id, initial: true) { _, _ in synchronize() }
    }

    private func synchronize() {
        let token = UUID()
        generation = token
        if let action = coordinator.latest {
            withAnimation(reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.88)) {
                displayedAction = action
                visible = true
            }
        } else {
            // Retain the last message until its exit completes, including timer expiry.
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.24), completionCriteria: .removed) {
                visible = false
            } completion: {
                guard generation == token else { return }
                displayedAction = nil
            }
        }
    }
}
