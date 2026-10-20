import Foundation
import XCTest
import HomeworkDomain
@testable import HomeworkApp

@MainActor
final class EditorReconciliationTests: XCTestCase {
    func testEditorCompletionIsUndoableWithoutRevertingContentEdits() throws {
        let repository = SwiftDataAssignmentRepository(container: try SwiftDataAssignmentRepository.makeContainer(inMemory: true))
        let task = Assignment(title: "Report", dueDate: Date())
        try repository.save([task])
        let store = try AssignmentStore(repository: repository)
        let editor = AssignmentEditor(assignment: task, isNew: false, store: store)
        editor.set(\.notes, "Keep these notes"); editor.setStatus(.completed); editor.flush()
        XCTAssertEqual(store.assignment(task.id)?.status, .completed)
        store.undoLatest()
        XCTAssertEqual(store.assignment(task.id)?.status, .active)
        XCTAssertEqual(store.assignment(task.id)?.notes, "Keep these notes")
    }
    func testExternalStatusAppearsWithoutLosingPendingNotes() throws {
        let repository = SwiftDataAssignmentRepository(container: try SwiftDataAssignmentRepository.makeContainer(inMemory: true))
        let task = Assignment(title: "Report", dueDate: Date())
        try repository.save([task])
        let store = try AssignmentStore(repository: repository)
        let editor = AssignmentEditor(assignment: task, isNew: false, store: store)
        editor.set(\.notes, "Pending notes")
        store.setStatus(task.id, to: .abandoned)
        editor.reconcile(try XCTUnwrap(store.assignment(task.id)))
        XCTAssertEqual(editor.draft.status, .abandoned); XCTAssertEqual(editor.draft.notes, "Pending notes")
        editor.flush()
        XCTAssertEqual(store.assignment(task.id)?.status, .abandoned)
        XCTAssertEqual(store.assignment(task.id)?.notes, "Pending notes")
    }

    func testStaleEditorCannotSwitchBetweenTwoTerminalStates() throws {
        let repository = SwiftDataAssignmentRepository(container: try SwiftDataAssignmentRepository.makeContainer(inMemory: true))
        let task = Assignment(title: "Report", dueDate: Date())
        try repository.save([task])
        let store = try AssignmentStore(repository: repository)
        let editor = AssignmentEditor(assignment: task, isNew: false, store: store)
        editor.setStatus(.completed)
        store.setStatus(task.id, to: .abandoned)
        editor.flush()
        XCTAssertNotNil(editor.validationMessage)
        XCTAssertEqual(store.assignment(task.id)?.status, .abandoned)
    }
}
