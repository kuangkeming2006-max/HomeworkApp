import Foundation

/// Three-way merge: independent edits survive; conflicting edits never silently overwrite data.
public enum AssignmentDraftMerge {
    public static func merge(base: Assignment, draft: Assignment, latest: Assignment) throws -> Assignment {
        guard base.id == draft.id, base.id == latest.id, latest.deletedAt == nil else {
            throw AssignmentError.notFound
        }
        var result = latest
        func field<Value: Equatable>(_ path: WritableKeyPath<Assignment, Value>, _ name: String) throws {
            let original = base[keyPath: path], edited = draft[keyPath: path], current = latest[keyPath: path]
            guard edited != original else { return }
            guard current == original || current == edited else {
                throw AssignmentError.invalid("\(name) changed elsewhere. Your draft is still here; review the latest assignment before saving.")
            }
            result[keyPath: path] = edited
        }
        try field(\.title, "Title")
        try field(\.course, "Course")
        try field(\.notes, "Notes")
        try field(\.dueDate, "Deadline")
        try field(\.dueTimeZone, "Time zone")
        try field(\.priority, "Priority")
        try field(\.reminder, "Reminder")
        if draft.status != base.status {
            guard latest.status == base.status || latest.status == draft.status,
                  latest.status.canTransition(to: draft.status) else {
                throw AssignmentError.invalid("Status changed elsewhere. Restore the assignment before choosing another status.")
            }
            result.status = draft.status
            result.completedAt = draft.completedAt
            result.abandonedAt = draft.abandonedAt
        }
        let originalIDs = Set(base.attachments.map(\.id))
        let editedIDs = Set(draft.attachments.map(\.id))
        let removed = originalIDs.subtracting(editedIDs)
        result.attachments.removeAll { removed.contains($0.id) }
        for reference in draft.attachments where !originalIDs.contains(reference.id) {
            if !result.attachments.contains(where: { $0.id == reference.id || $0.sha256 == reference.sha256 }) {
                result.attachments.append(reference)
            }
        }
        try result.validate()
        return result
    }

    /// Reflect unrelated external edits without rebasing away conflict information.
    public static func displaying(base: Assignment, draft: Assignment, latest: Assignment) -> Assignment {
        var value = draft
        func field<Value: Equatable>(_ path: WritableKeyPath<Assignment, Value>) {
            if draft[keyPath: path] == base[keyPath: path] { value[keyPath: path] = latest[keyPath: path] }
        }
        field(\.title); field(\.course); field(\.notes); field(\.dueDate)
        field(\.dueTimeZone); field(\.priority); field(\.reminder)
        if draft.status == base.status {
            value.status = latest.status; value.completedAt = latest.completedAt; value.abandonedAt = latest.abandonedAt
        }
        return value
    }
}
