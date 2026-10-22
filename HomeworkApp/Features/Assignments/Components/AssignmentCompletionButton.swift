import SwiftUI
import HomeworkDomain

/// A finite, local SF Symbol reaction; no timer or per-row animation loop.
struct AssignmentCompletionButton: View {
    let assignment: Assignment
    let action: () -> Void
    @Environment(\.appReduceMotion) private var reduceMotion
    @State private var burst = false
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
                    ForEach(0..<8) { index in
                        Capsule().fill(index.isMultiple(of: 2) ? Color.green : Color.yellow)
                            .frame(width: 3, height: 5)
                            .offset(y: burst ? -27 : -7)
                            .rotationEffect(.degrees(Double(index) * 45))
                            .scaleEffect(burst ? 0.2 : 1)
                            .opacity(burst ? 0 : 1)
                    }
                    .opacity(reaction == 0 ? 0 : 1)
                    .allowsHitTesting(false).accessibilityHidden(true)
                }
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(assignment.status == .active ? "Complete assignment" : "Restore assignment")
        .accessibilityValue(assignment.status.label)
        .task(id: reaction) {
            guard reaction > 0 else { return }
            var reset = Transaction(animation: nil); reset.disablesAnimations = true
            withTransaction(reset) { burst = false }
            withAnimation(.easeOut(duration: 0.45)) { burst = true }
        }
    }
}
