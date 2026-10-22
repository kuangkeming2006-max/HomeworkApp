import Foundation
import Observation
import HomeworkDomain

@Observable @MainActor
final class AssignmentEditor {
    private(set) var draft: Assignment
    private(set) var isNew: Bool
    private(set) var saving = false
    var validationMessage: String?
    private var base: Assignment
    // Local edits stay separate from the externally refreshed display.
    private var local: Assignment
    private let store: AssignmentStore

    init(assignment: Assignment, isNew: Bool, store: AssignmentStore) {
        draft = assignment; base = assignment; local = assignment
        self.isNew = isNew; self.store = store
    }

    var canSave: Bool { !saving && (try? draft.validate()) != nil }
    var hasChanges: Bool { local != base }

    func set<Value>(_ path: WritableKeyPath<Assignment, Value>, _ value: Value) {
        local[keyPath: path] = value
        draft[keyPath: path] = value
        validationMessage = nil
    }

    func setCompleted(_ completed: Bool) { setStatus(completed ? .completed : .active) }

    func setStatus(_ status: AssignmentStatus) {
        guard draft.status.canTransition(to: status), draft.status != status else { return }
        let date = Date()
        set(\.status, status)
        set(\.completedAt, status == .completed ? max(date, draft.createdAt) : nil)
        set(\.abandonedAt, status == .abandoned ? max(date, draft.createdAt) : nil)
    }

    func reconcile(_ value: Assignment) {
        guard !isNew, value.id == draft.id else { return }
        draft = AssignmentDraftMerge.displaying(base: base, draft: local, latest: value)
    }

    @discardableResult
    func save() -> Bool {
        guard !saving else { return false }
        saving = true; defer { saving = false }
        do {
            if isNew {
                try local.validate()
                try store.save([local])
            } else {
                guard let latest = store.assignment(draft.id) else { throw AssignmentError.notFound }
                let merged = try AssignmentDraftMerge.merge(base: base, draft: local, latest: latest)
                if merged != latest {
                    let message = merged.status != latest.status ? "Assignment \(merged.status == .active ? "restored" : merged.status.rawValue)" : nil
                    try store.update(draft.id, undoMessage: message) { $0 = merged }
                }
            }
            isNew = false
            if let saved = store.assignment(draft.id) { base = saved; local = saved; draft = saved }
            validationMessage = nil
            return true
        } catch { validationMessage = error.localizedDescription; return false }
    }

    // Compatibility for existing integrations; these are explicit commits, never timers.
    @discardableResult func create() -> Bool { save() }
    func flush() { save() }
}
