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
    @ObservationIgnored private var positions: [UUID: Int]

    init(repository: any AssignmentRepository) throws {
        self.repository = repository
        let loaded = try repository.fetchAll()
        assignments = loaded
        positions = Dictionary(uniqueKeysWithValues: loaded.enumerated().map { ($0.element.id, $0.offset) })
    }

    func assignment(_ id: UUID) -> Assignment? {
        guard let value = record(id), value.deletedAt == nil else { return nil }
        return value
    }

    private func record(_ id: UUID) -> Assignment? {
        guard let index = positions[id] else { return nil }
        return assignments[index]
    }

    func makeDraft(on day: Date? = nil) -> Assignment {
        let calendar = Calendar.current
        let target = day ?? calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let due = calendar.date(bySettingHour: 23, minute: 59, second: 0, of: target) ?? target
        return Assignment(dueDate: due, reminder: defaultReminder)
    }

    func save(_ values: [Assignment]) throws {
        guard Set(values.map(\.id)).count == values.count else {
            throw AssignmentError.invalid("A save batch contains duplicate assignment identifiers.")
        }
        try repository.save(values)
        for value in values {
            if let prior = record(value.id), AssignmentDisposition(prior) != AssignmentDisposition(value) {
                dispositionTokens[value.id] = UUID()
            }
        }
        let changes = Dictionary(uniqueKeysWithValues: values.map { ($0.id, $0) })
        let existing = Set(assignments.map(\.id))
        assignments = assignments.map { changes[$0.id] ?? $0 } + values.filter { !existing.contains($0.id) }
        positions = Dictionary(uniqueKeysWithValues: assignments.enumerated().map { ($0.element.id, $0.offset) })
        didChange?()
    }

    func update(_ id: UUID, undoMessage: String? = nil, change: (inout Assignment) -> Void) throws {
        guard var value = assignment(id) else { throw AssignmentError.notFound }
        let before = AssignmentDisposition(value)
        let priorToken = dispositionTokens[id] ?? UUID()
        dispositionTokens[id] = priorToken
        change(&value)
        value.updatedAt = max(Date(), value.updatedAt.addingTimeInterval(0.001))
        value.localRevision += 1
        try save([value])
        if let undoMessage, AssignmentDisposition(value) != before {
            undo.record(id: id, before: before, after: AssignmentDisposition(value), message: undoMessage,
                        previousToken: priorToken, resultingToken: dispositionTokens[id] ?? priorToken)
        }
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
        perform { try update(id, undoMessage: message, change: change) }
    }

    func undoLatest() {
        guard let action = undo.takeLatest(),
              var current = record(action.assignmentID) else { return }
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
