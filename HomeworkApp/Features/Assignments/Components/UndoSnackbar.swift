import SwiftUI

struct UndoSnackbar: View {
    let coordinator: UndoCoordinator
    let undo: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        if let action = coordinator.latest {
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
            }
            .padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            .frame(maxWidth: 600)
            .padding(.horizontal).padding(.bottom, 6)
            .accessibilityElement(children: .contain)
            .transition(.move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.96, anchor: .bottom)))
        }
    }
}
