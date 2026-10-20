import XCTest
import HomeworkDomain
@testable import HomeworkApp

@MainActor
private final class RejectingBackupRepository: AssignmentRepository {
    let original: Assignment
    init(original: Assignment) { self.original = original }
    func fetchAll() throws -> [Assignment] { [original] }
    func save(_ assignments: [Assignment]) throws { throw AssignmentError.invalid("Synthetic transaction failure") }
}

@MainActor
final class BackupIntegrationTests: XCTestCase {
    func testRestorePersistsFilesAndPreservesExistingAssignments() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let source = try LocalAttachmentService(directory: root.appendingPathComponent("source"))
        let bytes = Data("Synthetic report attachment".utf8)
        let attachment = try await source.importData(bytes, name: "report.txt", contentType: "public.plain-text")
        var first = Assignment(title: "Original", dueDate: Date().addingTimeInterval(86_400), reminder: .init(amount: 3, unit: .hours))
        first.attachments = [attachment]
        let second = Assignment(title: "Existing", dueDate: Date())
        let exporter = LocalBackupService(attachments: source)
        let data = try await exporter.export([first, second])
        let url = root.appendingPathComponent("backup.json")
        try data.write(to: url)

        let destination = try LocalAttachmentService(directory: root.appendingPathComponent("destination"))
        let repository = SwiftDataAssignmentRepository(container: try SwiftDataAssignmentRepository.makeContainer(inMemory: true))
        let store = try AssignmentStore(repository: repository)
        var edited = second; edited.title = "Keep this edited title"
        try store.save([edited])
        let model = BackupViewModel(store: store, service: LocalBackupService(attachments: destination))
        await model.read(url)
        XCTAssertEqual(model.newCount, 1)
        XCTAssertEqual(model.skippedCount, 1)
        XCTAssertEqual(store.assignments.count, 1, "Reading a backup must not save anything")
        await model.restore()
        XCTAssertEqual(store.assignments.count, 2)
        XCTAssertEqual(store.assignment(second.id)?.title, edited.title)
        let restored = try XCTUnwrap(store.assignment(first.id))
        XCTAssertEqual(restored.reminder, first.reminder)
        let restoredFile = try XCTUnwrap(restored.attachments.first)
        XCTAssertNotEqual(restoredFile.relativePath, attachment.relativePath)
        let copiedURL = try await destination.url(for: restoredFile)
        XCTAssertEqual(try Data(contentsOf: copiedURL), bytes)
        await model.read(url)
        XCTAssertEqual(model.newCount, 0, "Reimporting a backup must not duplicate tasks")
    }

    func testCorruptBackupCannotModifyExistingData() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let attachments = try LocalAttachmentService(directory: root)
        let reference = try await attachments.importData(Data([1, 2, 3]), name: "test.bin", contentType: "public.data")
        var assignment = Assignment(title: "Safe", dueDate: Date()); assignment.attachments = [reference]
        let archive = BackupArchive(assignments: [assignment], files: [.init(attachmentID: reference.id, data: Data([9, 9, 9]))])
        let url = root.appendingPathComponent("damaged.json")
        try JSONEncoder().encode(archive).write(to: url)
        let store = try AssignmentStore(repository: SwiftDataAssignmentRepository(container: SwiftDataAssignmentRepository.makeContainer(inMemory: true)))
        try store.save([Assignment(title: "Keep", dueDate: Date())])
        let model = BackupViewModel(store: store, service: LocalBackupService(attachments: attachments))
        await model.read(url)
        XCTAssertNil(model.archive)
        XCTAssertNotNil(model.message)
        XCTAssertEqual(store.assignments.map(\.title), ["Keep"])
    }

    func testFailedDatabaseSaveCleansOnlyStagedFiles() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let source = try LocalAttachmentService(directory: root.appendingPathComponent("source"))
        var record = Assignment(title: "Import", dueDate: Date())
        record.attachments = [try await source.importData(Data([1, 2, 3]), name: "test.bin", contentType: "public.data")]
        let data = try await LocalBackupService(attachments: source).export([record])
        let url = root.appendingPathComponent("backup.json"); try data.write(to: url)
        let destinationURL = root.appendingPathComponent("destination")
        let destination = try LocalAttachmentService(directory: destinationURL)
        let existingFile = try await destination.importData(Data([4, 5]), name: "keep.bin", contentType: "public.data")
        var existing = Assignment(title: "Keep", dueDate: Date()); existing.attachments = [existingFile]
        let store = try AssignmentStore(repository: RejectingBackupRepository(original: existing))
        let model = BackupViewModel(store: store, service: LocalBackupService(attachments: destination))
        await model.read(url); XCTAssertEqual(model.newCount, 1)
        await model.restore()
        XCTAssertNotNil(model.message)
        XCTAssertEqual(store.assignments, [existing])
        let files = try FileManager.default.contentsOfDirectory(atPath: destinationURL.path)
        XCTAssertEqual(files, [existingFile.relativePath])
    }
}
