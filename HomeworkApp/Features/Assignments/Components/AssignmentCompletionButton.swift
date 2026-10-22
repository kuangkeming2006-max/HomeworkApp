import SwiftUI
import HomeworkDomain

/// A finite, local SF Symbol reaction; no timer or per-row animation loop.
struct AssignmentCompletionButton: View {
    let assignment: Assignment
    let action: () -> Void
    @Environment(\.appReduceMotion) private var reduceMotion
    @State private var reaction = 0

    var body: some View {
        Button {
            if assignment.status == .active, !reduceMotion { reaction += 1 }
            action()
        } label: {
            Image(systemName: assignment.status == .abandoned ? "minus.circle.fill" :
                    assignment.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title2).contentTransition(.symbolEffect(.replace))
                .frame(minWidth: 32, minHeight: 44)
                .overlay {
                    Color.clear.keyframeAnimator(initialValue: CGFloat.zero, trigger: reaction) { _, progress in
                        ZStack {
                            ForEach(0..<8) { index in
                                Capsule().fill(index.isMultiple(of: 2) ? Color.green : Color.yellow)
                                    .frame(width: 3, height: 5)
                                    .offset(y: -7 - progress * 20)
                                    .rotationEffect(.degrees(Double(index) * 45))
                                    .scaleEffect(1 - progress * 0.8).opacity(1 - progress)
                            }
                        }.opacity(reduceMotion || reaction == 0 ? 0 : 1)
                    } keyframes: { _ in
                        MoveKeyframe(CGFloat.zero)
                        CubicKeyframe(CGFloat(1), duration: 0.45)
                    }
                    .allowsHitTesting(false).accessibilityHidden(true)
                }
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(assignment.status == .active ? "Complete assignment" : "Restore assignment")
        .accessibilityValue(assignment.status.label)
    }
}
