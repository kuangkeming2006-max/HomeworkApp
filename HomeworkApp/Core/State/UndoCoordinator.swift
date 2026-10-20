import Foundation
import Observation
import HomeworkDomain

@Observable @MainActor
final class UndoCoordinator {
    struct Action: Identifiable {
        let id = UUID()
        let assignmentID: UUID
        let before: AssignmentDisposition
        let after: AssignmentDisposition
        let message: String
        let expiresAt: Date
    }
    private(set) var actions: [Action] = []
    var latest: Action? { actions.last }
    private var expiration: Task<Void, Never>?

    func record(id: UUID, before: AssignmentDisposition, after: AssignmentDisposition, message: String) {
        prune()
        actions.append(Action(assignmentID: id, before: before, after: after, message: message,
                              expiresAt: Date().addingTimeInterval(5)))
        scheduleExpiry()
    }

    func takeLatest() -> Action? {
        prune()
        let action = actions.popLast()
        scheduleExpiry()
        return action
    }

    private func prune() { actions.removeAll { $0.expiresAt <= Date() } }
    private func scheduleExpiry() {
        expiration?.cancel()
        guard let first = actions.first else { return }
        let delay = max(0, first.expiresAt.timeIntervalSinceNow)
        expiration = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            self?.prune(); self?.scheduleExpiry()
        }
    }
}
