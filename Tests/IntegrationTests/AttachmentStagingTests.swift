import Foundation
import XCTest
import HomeworkDomain
@testable import HomeworkApp

@MainActor
final class AttachmentStagingTests: XCTestCase {
    func testDismissedDraftReleasesSessionAndCleansItsFiles() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let source = directory.appendingPathComponent("notes.txt")
        try Data("Synthetic draft".utf8).write(to: source)
        let service = try LocalAttachmentService(directory: directory.appendingPathComponent("storage"))
        var model: AttachmentViewModel? = AttachmentViewModel(service: service) { _ in }
        await model?.importFiles(.success([source]))
        let reference = try XCTUnwrap(model?.references.first)
        let url = try await service.url(for: reference)
        weak var released = model
        model = nil
        XCTAssertNil(released)
        for _ in 0..<100 where FileManager.default.fileExists(atPath: url.path) { try await Task.sleep(for: .milliseconds(10)) }
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }
    func testDraftImportDeduplicatesAndCancelCleansOnlyOwnedCopies() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let source = directory.appendingPathComponent("report.pdf")
        try Data("%PDF-1.4 synthetic fixture".utf8).write(to: source)
        let service = try LocalAttachmentService(directory: directory.appendingPathComponent("storage"))
        var references: [AttachmentReference] = []
        let model = AttachmentViewModel(service: service) { references = $0 }
        await model.importFiles(.success([source, source]))
        XCTAssertNil(model.errorMessage); XCTAssertEqual(references.count, 1)
        let reference = try XCTUnwrap(references.first)
        XCTAssertEqual(reference.contentType, "com.adobe.pdf")
        let url = try await service.url(for: reference)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        await model.close()
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
    }

    func testValidationFailureRetainsDraftAndSuccessfulCreatePreservesFiles() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let source = directory.appendingPathComponent("notes.txt")
        try Data("Notes".utf8).write(to: source)
        let service = try LocalAttachmentService(directory: directory.appendingPathComponent("storage"))
        let repository = SwiftDataAssignmentRepository(container: try SwiftDataAssignmentRepository.makeContainer(inMemory: true))
        let store = try AssignmentStore(repository: repository)
        let editor = AssignmentEditor(assignment: store.makeDraft(), isNew: true, store: store)
        let model = AttachmentViewModel(service: service) { editor.set(\.attachments, $0) }
        await model.importFiles(.success([source]))
        XCTAssertFalse(editor.create()); XCTAssertEqual(model.references.count, 1)
        editor.set(\.title, "Report"); XCTAssertTrue(editor.create())
        model.markCommitted(); await model.close()
        let saved = try XCTUnwrap(store.assignments.first?.attachments.first)
        let url = try await service.url(for: saved)
        XCTAssertEqual(try String(contentsOf: url, encoding: .utf8), "Notes")
    }
}
