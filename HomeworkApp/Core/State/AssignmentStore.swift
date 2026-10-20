import Foundation
import Observation
import HomeworkDomain

@Observable @MainActor
final class AssignmentStore {
    private(set) var assignments: [Assignment]
    var errorMessage: String?
    private let repository: any AssignmentRepository
    var didChange: (@MainActor () -> Void)?
    var defaultReminder: ReminderConfiguration = .none
    let undo = UndoCoordinator()
    private var dispositionTokens: [UUID: UUID] = [:]

    init(repository: any AssignmentRepository) throws {
        self.repository = repository
        assignments = try repository.fetchAll()
    }

    func assignment(_ id: UUID) -> Assignment? {
        assignments.first { $0.id == id && $0.deletedAt == nil }
    }

    func makeDraft(on day: Date? = nil) -> Assignment {
        let calendar = Calendar.current
        let target = day ?? calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let due = calendar.date(bySettingHour: 23, minute: 59, second: 0, of: target) ?? target
        return Assignment(dueDate: due, reminder: defaultReminder)
    }

    func save(_ values: [Assignment]) throws {
        try repository.save(values)
        for value in values {
            if let prior = assignments.first(where: { $0.id == value.id }), AssignmentDisposition(prior) != AssignmentDisposition(value) {
                dispositionTokens[value.id] = UUID()
            }
        }
        let changes = Dictionary(uniqueKeysWithValues: values.map { ($0.id, $0) })
        let existing = Set(assignments.map(\.id))
        assignments = assignments.map { changes[$0.id] ?? $0 } + values.filter { !existing.contains($0.id) }
        didChange?()
    }

    func update(_ id: UUID, change: (inout Assignment) -> Void) throws {
        guard var value = assignment(id) else { throw AssignmentError.notFound }
        change(&value)
        value.updatedAt = max(Date(), value.updatedAt.addingTimeInterval(0.001))
        value.localRevision += 1
        try save([value])
    }

    func toggleCompletion(_ id: UUID) {
        guard let value = assignment(id) else { return }
        setStatus(id, to: value.status == .active ? .completed : .active)
    }

    func setStatus(_ id: UUID, to status: AssignmentStatus) {
        guard let current = assignment(id), current.status != status,
              current.status == .active || status == .active else { return }
        action(id, message: status == .active ? "Assignment restored" : "Assignment \(status.rawValue)") {
            $0.transition(to: status, at: Date())
        }
    }

    func delete(_ id: UUID) {
        action(id, message: "Assignment deleted") { $0.deletedAt = max(Date(), $0.updatedAt) }
    }

    private func action(_ id: UUID, message: String, change: (inout Assignment) -> Void) {
        guard let before = assignment(id) else { return }
        let priorToken = dispositionTokens[id] ?? UUID()
        dispositionTokens[id] = priorToken
        perform {
            try update(id, change: change)
            guard let after = assignments.first(where: { $0.id == id }) else { return }
            undo.record(id: id, before: AssignmentDisposition(before), after: AssignmentDisposition(after), message: message,
                        previousToken: priorToken, resultingToken: dispositionTokens[id] ?? priorToken)
        }
    }

    func undoLatest() {
        guard let action = undo.takeLatest(),
              var current = assignments.first(where: { $0.id == action.assignmentID }) else { return }
        // Content edits in another window survive; newer disposition changes are never overwritten.
        guard dispositionTokens[current.id] == action.resultingToken, AssignmentDisposition(current) == action.after else { return }
        action.before.apply(to: &current)
        current.updatedAt = max(Date(), current.updatedAt.addingTimeInterval(0.001))
        current.localRevision += 1
        perform {
            try save([current])
            dispositionTokens[current.id] = action.previousToken
        }
    }

    func perform(_ work: () throws -> Void) {
        do { try work() } catch { errorMessage = error.localizedDescription }
    }
}
