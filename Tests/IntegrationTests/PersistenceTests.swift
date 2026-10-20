import Foundation
import XCTest
import HomeworkDomain
@testable import HomeworkApp

@MainActor
final class PersistenceTests: XCTestCase {
    func testDiskPersistenceRoundTripAndSoftDelete() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("test.store")
        var value = Assignment(title: "Persisted lab", dueDate: Date(), dueTimeZone: "Asia/Tokyo",
                               priority: .urgent, reminder: .init(amount: 3, unit: .hours))
        do {
            let repository = SwiftDataAssignmentRepository(container: try SwiftDataAssignmentRepository.makeContainer(url: url))
            try repository.save([value])
        }
        let repository = SwiftDataAssignmentRepository(container: try SwiftDataAssignmentRepository.makeContainer(url: url))
        XCTAssertEqual(try repository.fetchAll(), [value])
        let store = try AssignmentStore(repository: repository)
        store.toggleCompletion(value.id)
        XCTAssertTrue(try XCTUnwrap(store.assignment(value.id)).isCompleted)
        store.toggleCompletion(value.id)
        XCTAssertNil(try XCTUnwrap(store.assignment(value.id)).completedAt)
        store.delete(value.id)
        XCTAssertNil(store.assignment(value.id))
        value = try XCTUnwrap(repository.fetchAll().first)
        XCTAssertNotNil(value.deletedAt)
        XCTAssertGreaterThan(value.localRevision, 1)
    }

    func testInvalidBatchDoesNotDamageExistingAssignments() throws {
        let repository = SwiftDataAssignmentRepository(container: try SwiftDataAssignmentRepository.makeContainer(inMemory: true))
        let valid = Assignment(title: "Original", dueDate: Date())
        try repository.save([valid])
        var changed = valid; changed.title = "Changed"
        let invalid = Assignment(title: "", dueDate: Date())
        XCTAssertThrowsError(try repository.save([changed, invalid]))
        XCTAssertEqual(try repository.fetchAll(), [valid])
    }

    func testTwoEditorsMergeDifferentFieldsAndCompletionSurvives() throws {
        let repository = SwiftDataAssignmentRepository(container: try SwiftDataAssignmentRepository.makeContainer(inMemory: true))
        let assignment = Assignment(title: "Original", dueDate: Date())
        try repository.save([assignment])
        let store = try AssignmentStore(repository: repository)
        let first = AssignmentEditor(assignment: assignment, isNew: false, store: store)
        let second = AssignmentEditor(assignment: assignment, isNew: false, store: store)
        first.set(\.title, "Edited title"); first.flush()
        store.toggleCompletion(assignment.id)
        second.set(\.notes, "Edited in another window"); second.flush()
        let result = try XCTUnwrap(store.assignment(assignment.id))
        XCTAssertEqual(result.title, "Edited title")
        XCTAssertEqual(result.notes, "Edited in another window")
        XCTAssertTrue(result.isCompleted)
    }

    func testDebouncedEditsPersistWithoutSaveButton() async throws {
        let repository = SwiftDataAssignmentRepository(container: try SwiftDataAssignmentRepository.makeContainer(inMemory: true))
        let assignment = Assignment(title: "Report", dueDate: Date())
        try repository.save([assignment])
        let store = try AssignmentStore(repository: repository)
        let editor = AssignmentEditor(assignment: assignment, isNew: false, store: store)
        editor.set(\.notes, "Saved automatically")
        try await Task.sleep(for: .milliseconds(700))
        XCTAssertEqual(try repository.fetchAll().first?.notes, "Saved automatically")
    }
}
