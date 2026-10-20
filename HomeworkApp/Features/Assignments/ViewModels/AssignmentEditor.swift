import Foundation
import Observation
import HomeworkDomain

@Observable @MainActor
final class AssignmentEditor {
    private(set) var draft: Assignment
    private(set) var isNew: Bool
    var validationMessage: String?
    private let store: AssignmentStore
    private var pending: [(inout Assignment) -> Void] = []
    private var saveTask: Task<Void, Never>?
    private var pendingStatus: AssignmentStatus?

    init(assignment: Assignment, isNew: Bool, store: AssignmentStore) {
        draft = assignment; self.isNew = isNew; self.store = store
    }

    var canSave: Bool { (try? draft.validate()) != nil }

    func set<Value>(_ path: WritableKeyPath<Assignment, Value>, _ value: Value) {
        draft[keyPath: path] = value
        validationMessage = nil
        guard !isNew else { return }
        pending.append { $0[keyPath: path] = value }
        saveTask?.cancel()
        saveTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            self?.flush()
        }
    }

    func setCompleted(_ completed: Bool) {
        setStatus(completed ? .completed : .active)
    }

    func setStatus(_ status: AssignmentStatus) {
        guard draft.status.canTransition(to: status), draft.status != status else { return }
        if !isNew { pendingStatus = status }
        let date = Date()
        set(\.status, status)
        set(\.completedAt, status == .completed ? max(date, draft.createdAt) : nil)
        set(\.abandonedAt, status == .abandoned ? max(date, draft.createdAt) : nil)
    }

    func reconcile(_ value: Assignment) {
        guard !isNew, value.id == draft.id else { return }
        var merged = value
        for change in pending { change(&merged) }
        draft = merged
    }

    @discardableResult
    func create() -> Bool {
        do {
            try draft.validate()
            try store.save([draft])
            isNew = false
            return true
        } catch { validationMessage = error.localizedDescription; return false }
    }

    func flush() {
        saveTask?.cancel()
        guard !isNew, !pending.isEmpty else { return }
        do {
            try draft.validate()
            if let target = pendingStatus, let latest = store.assignment(draft.id), !latest.status.canTransition(to: target) {
                throw AssignmentError.invalid("This assignment's status changed in another window. Restore it before choosing a different status.")
            }
            let changes = pending
            let undoMessage = pendingStatus.map { $0 == .active ? "Assignment restored" : "Assignment \($0.rawValue)" }
            try store.update(draft.id, undoMessage: undoMessage) { value in
                for change in changes { change(&value) }
            }
            pending.removeAll()
            pendingStatus = nil
        } catch { validationMessage = error.localizedDescription }
    }
}
