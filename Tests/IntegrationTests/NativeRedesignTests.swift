import XCTest
import HomeworkDomain
@testable import HomeworkApp

@MainActor
final class NativeRedesignTests: XCTestCase {
    func testHeadingIgnoresMenuLayoutAndInsetChanges() {
        let layout = AssignmentHeadingLayout()
        layout.update(offset: -200, topInset: 200)
        layout.update(offset: -120, topInset: 200)
        XCTAssertFalse(layout.isCompact, "Idle layout changes must not replace an open menu's host")
        layout.setScrolling(true)
        layout.update(offset: -20, topInset: 200)
        XCTAssertTrue(layout.isCompact)
        layout.update(offset: 40, topInset: 100)
        XCTAssertTrue(layout.isCompact, "Collapsing the native bar must not reverse the title change")
        layout.update(offset: 30, topInset: 100)
        XCTAssertTrue(layout.isCompact)
        layout.update(offset: -100, topInset: 100)
        XCTAssertFalse(layout.isCompact)
        layout.setScrolling(false)
        layout.update(offset: 500, topInset: 100)
        XCTAssertFalse(layout.isCompact)
        layout.reset()
        XCTAssertFalse(layout.isCompact)
        layout.setScrolling(true)
        layout.update(offset: 0, topInset: 100)
        layout.update(offset: -120, topInset: 100)
        layout.update(offset: 0, topInset: 100)
        XCTAssertFalse(layout.isCompact, "Pull-to-search spring-back must not collapse a title at the top")
    }

    private func makeStore(_ values: [Assignment]) throws -> AssignmentStore {
        let repository = SwiftDataAssignmentRepository(container: try SwiftDataAssignmentRepository.makeContainer(inMemory: true))
        try repository.save(values)
        return try AssignmentStore(repository: repository)
    }

    func testFiveFiltersAndStableAllMovement() {
        let now = Date()
        var completed = Assignment(title: "Completed", dueDate: now)
        completed.transition(to: .completed, at: now)
        var abandoned = Assignment(title: "Abandoned", dueDate: now)
        abandoned.transition(to: .abandoned, at: now)
        var deleted = completed; deleted.id = UUID(); deleted.deletedAt = now
        let active = Assignment(title: "Upcoming", dueDate: now)
        let values = [active, completed, abandoned, deleted]
        XCTAssertEqual(AssignmentFilter.allCases.map(\.rawValue), ["All", "Upcoming", "Completed", "Abandoned", "Deleted"])
        XCTAssertEqual(AssignmentQuery.apply(values, filter: .all).count, 3)
        XCTAssertEqual(AssignmentQuery.apply(values, filter: .upcoming).map(\.id), [active.id])
        XCTAssertEqual(AssignmentQuery.apply(values, filter: .completed).map(\.id), [completed.id])
        XCTAssertEqual(AssignmentQuery.apply(values, filter: .abandoned).map(\.id), [abandoned.id])
        XCTAssertEqual(AssignmentQuery.apply(values, filter: .deleted).map(\.id), [deleted.id])
        let projection = AssignmentListProjection()
        projection.rebuild(values, sort: .deadline, filter: .all, search: "")
        let identity = projection.entries.first { $0.id == active.id.uuidString }?.id
        var changed = active; changed.transition(to: .completed, at: now)
        projection.rebuild([changed, completed, abandoned, deleted], sort: .deadline, filter: .all, search: "")
        XCTAssertEqual(projection.entries.filter { $0.id == identity }.count, 1)
        let heading = projection.entries.firstIndex { $0.id == "section.completed" }
        let row = projection.entries.firstIndex { $0.id == identity }
        XCTAssertGreaterThan(row ?? -1, heading ?? Int.max)
    }

    func testUpcomingDelayUndoRapidToggleAndSearch() throws {
        let task = Assignment(title: "Report", dueDate: Date())
        let store = try makeStore([task])
        let projection = AssignmentListProjection()
        let now = Date()
        projection.keepCompleted(task.id, until: now.addingTimeInterval(5))
        store.toggleCompletion(task.id)
        projection.rebuild(store.assignments, sort: .priority, filter: .upcoming, search: "")
        XCTAssertFalse(projection.isEmpty)
        XCTAssertEqual(store.assignment(task.id)?.status, .completed, "Persistence must not wait five seconds")
        XCTAssertTrue(projection.expire(at: now.addingTimeInterval(4.99)).isEmpty)
        projection.refilter(filter: .upcoming, search: "Unrelated")
        XCTAssertTrue(projection.isEmpty)
        projection.refilter(filter: .completed, search: "")
        XCTAssertFalse(projection.isEmpty)
        store.undoLatest()
        projection.rebuild(store.assignments, sort: .priority, filter: .upcoming, search: "")
        XCTAssertTrue(projection.pendingVisibility.isEmpty)
        for _ in 0..<6 { store.toggleCompletion(task.id) }
        XCTAssertEqual(store.assignment(task.id)?.status, .active)
        store.toggleCompletion(task.id)
        projection.keepCompleted(task.id, until: now.addingTimeInterval(5))
        XCTAssertEqual(projection.expire(at: now.addingTimeInterval(5)), [task.id])
        projection.rebuild(store.assignments, sort: .priority, filter: .upcoming, search: "")
        XCTAssertTrue(projection.isEmpty)
        projection.keepCompleted(task.id); projection.clearPending()
        XCTAssertNil(projection.nextExpiry)
    }

    func testDeletedRestorePreservesEveryStatusAndAttachmentFiles() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let service = try LocalAttachmentService(directory: directory)
        defer { try? FileManager.default.removeItem(at: directory) }
        let reference = try await service.importData(Data("Retained".utf8), name: "notes.txt", contentType: "public.plain-text")
        for status in AssignmentStatus.allCases {
            var task = Assignment(title: "Retained", dueDate: Date())
            task.transition(to: status, at: Date()); task.attachments = [reference]
            let store = try makeStore([task])
            store.delete(task.id)
            let deleted = try XCTUnwrap(store.record(task.id))
            XCTAssertNil(store.assignment(task.id)); XCTAssertNotNil(deleted.deletedAt)
            XCTAssertTrue(store.retainedAttachmentPaths.contains(reference.relativePath))
            try await service.pruneOrphans(keeping: store.retainedAttachmentPaths, now: Date().addingTimeInterval(172800))
            _ = try await service.url(for: reference)
            store.restoreDeleted(task.id)
            let restored = try XCTUnwrap(store.assignment(task.id))
            XCTAssertEqual(restored.status, status)
            XCTAssertEqual(restored.attachments, task.attachments)
            XCTAssertEqual(restored.completedAt, task.completedAt)
            XCTAssertEqual(restored.abandonedAt, task.abandonedAt)
            XCTAssertGreaterThan(restored.localRevision, deleted.localRevision)
            store.undoLatest()
            XCTAssertNotNil(store.record(task.id)?.deletedAt)
        }
    }

    func testConflictingSaveRetainsDraftAndDoesNotOverwriteExternalEdit() throws {
        let task = Assignment(title: "Original", dueDate: Date())
        let store = try makeStore([task])
        let editor = AssignmentEditor(assignment: task, isNew: false, store: store)
        editor.set(\.title, "Local")
        try store.update(task.id) { $0.title = "External" }
        editor.reconcile(try XCTUnwrap(store.assignment(task.id)))
        XCTAssertFalse(editor.save())
        XCTAssertEqual(editor.draft.title, "Local")
        XCTAssertEqual(store.assignment(task.id)?.title, "External")
        XCTAssertTrue(editor.hasChanges)
        XCTAssertNotNil(editor.validationMessage)
    }

    func testExistingAttachmentEditsAreStagedAndDiscardKeepsOriginal() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let service = try LocalAttachmentService(directory: directory.appendingPathComponent("files"))
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let old = try await service.importData(Data("Old".utf8), name: "old.txt", contentType: "public.plain-text")
        let source = directory.appendingPathComponent("new.txt")
        try Data("New".utf8).write(to: source)
        var task = Assignment(title: "Report", dueDate: Date()); task.attachments = [old]
        let store = try makeStore([task])
        let editor = AssignmentEditor(assignment: task, isNew: false, store: store)
        let model = AttachmentViewModel(service: service, references: task.attachments) { editor.set(\.attachments, $0) }
        await model.remove(old); await model.importFiles(.success([source]))
        let staged = try XCTUnwrap(model.references.first)
        let stagedURL = try await service.url(for: staged)
        XCTAssertEqual(store.assignment(task.id)?.attachments, [old])
        _ = try await service.url(for: old)
        await model.close()
        XCTAssertFalse(FileManager.default.fileExists(atPath: stagedURL.path))
        _ = try await service.url(for: old)
        XCTAssertEqual(store.assignment(task.id)?.attachments, [old])
    }

    func testExistingAttachmentSavePreservesExternalAdditions() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let service = try LocalAttachmentService(directory: directory)
        defer { try? FileManager.default.removeItem(at: directory) }
        let old = try await service.importData(Data("Old".utf8), name: "old.txt", contentType: "public.plain-text")
        let other = try await service.importData(Data("Other".utf8), name: "other.txt", contentType: "public.plain-text")
        var task = Assignment(title: "Report", dueDate: Date()); task.attachments = [old]
        let store = try makeStore([task])
        let editor = AssignmentEditor(assignment: task, isNew: false, store: store)
        let model = AttachmentViewModel(service: service, references: task.attachments) { editor.set(\.attachments, $0) }
        await model.remove(old)
        try store.update(task.id) { $0.attachments.append(other) }
        XCTAssertTrue(editor.save())
        await model.finishCommit(retaining: store.retainedAttachmentPaths)
        XCTAssertEqual(store.assignment(task.id)?.attachments, [other])
        _ = try await service.url(for: other)
        let oldURL = directory.appendingPathComponent(old.relativePath)
        XCTAssertFalse(FileManager.default.fileExists(atPath: oldURL.path))
    }

    func testToolbarActivationIncludesIntermediateTabs() {
        let toolbar = WorkspaceToolbarModel()
        for section in ["Assignments", "Calendar", "Assignments", "Briefing", "Calendar", "Settings", "Assignments"] {
            let previous = toolbar.activation
            toolbar.activate(section)
            XCTAssertEqual(toolbar.activation, previous + 1)
            XCTAssertEqual(toolbar.selectedSection, section)
        }
    }

    func testReconciledFieldCanBeEditedBackToItsOriginalValue() throws {
        let task = Assignment(title: "Original", dueDate: Date())
        let store = try makeStore([task])
        let editor = AssignmentEditor(assignment: task, isNew: false, store: store)
        try store.update(task.id) { $0.title = "External" }
        editor.reconcile(try XCTUnwrap(store.assignment(task.id)))
        XCTAssertEqual(editor.draft.title, "External")
        XCTAssertFalse(editor.hasChanges)
        editor.set(\.title, "Original")
        XCTAssertTrue(editor.hasChanges)
        XCTAssertTrue(editor.save())
        XCTAssertEqual(store.assignment(task.id)?.title, "Original")
    }

    func testConcurrentIdenticalCompletionKeepsThePersistedTimestamp() throws {
        let task = Assignment(title: "Report", dueDate: Date())
        var draft = task; draft.transition(to: .completed, at: task.createdAt.addingTimeInterval(1))
        var latest = task; latest.transition(to: .completed, at: task.createdAt.addingTimeInterval(2))
        let merged = try AssignmentDraftMerge.merge(base: task, draft: draft, latest: latest)
        XCTAssertEqual(merged.completedAt, latest.completedAt)
    }

    func testRemovingExternallyModifiedAttachmentReportsConflict() throws {
        var task = Assignment(title: "Report", dueDate: Date())
        let original = AttachmentReference(name: "old.txt", relativePath: "old.txt", contentType: "public.plain-text", byteCount: 3, sha256: String(repeating: "a", count: 64))
        task.attachments = [original]
        var draft = task; draft.attachments = []
        var latest = task; latest.attachments[0].name = "Updated elsewhere.txt"
        XCTAssertThrowsError(try AssignmentDraftMerge.merge(base: task, draft: draft, latest: latest))
    }
}
