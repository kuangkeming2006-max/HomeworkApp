import Foundation
import SwiftData
import XCTest
import HomeworkDomain
@testable import HomeworkApp

@MainActor
final class StatusMigrationTests: XCTestCase {
    func testActualV1DiskStoreMigratesWithoutChangingRecordsOrAttachments() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("legacy.store")
        let ids = [UUID(), UUID(), UUID()]
        let now = Date(timeIntervalSince1970: 1_790_000_000)
        let attachment = AttachmentReference(name: "report.pdf", relativePath: "legacy.pdf", contentType: "com.adobe.pdf",
                                             byteCount: 10, sha256: String(repeating: "a", count: 64), createdAt: now)
        // Create a genuine V1 SQLite fixture using the unchanged old model, then close it.
        do {
            let schema = Schema(versionedSchema: HomeworkSchemaV1.self)
            let container = try ModelContainer(for: schema, configurations: [ModelConfiguration("Homework", schema: schema, url: url, cloudKitDatabase: .none)])
            let context = ModelContext(container)
            for (index, id) in ids.enumerated() {
                let entity = HomeworkSchemaV1.AssignmentEntity(id: id, title: "Legacy \(index)", dueDate: now, now: now)
                entity.isCompleted = index == 1; entity.completedAt = index == 1 ? now : nil
                entity.deletedAt = index == 2 ? now : nil
                entity.attachmentsData = try JSONEncoder().encode([attachment])
                entity.localRevision = 7
                context.insert(entity)
            }
            try context.save()
        }
        let repository = SwiftDataAssignmentRepository(container: try SwiftDataAssignmentRepository.makeContainer(url: url))
        let values = try repository.fetchAll()
        XCTAssertEqual(Set(values.map(\.id)), Set(ids))
        for value in values {
            XCTAssertEqual(value.status, value.id == ids[1] ? .completed : .active)
            XCTAssertEqual(value.attachments, [attachment]); XCTAssertEqual(value.localRevision, 7)
            XCTAssertEqual(value.createdAt, now); XCTAssertNil(value.abandonedAt)
            XCTAssertEqual(value.deletedAt, value.id == ids[2] ? now : nil)
        }
    }

    func testUndoPreservesConcurrentContentAndMonotonicRevisions() throws {
        let repository = SwiftDataAssignmentRepository(container: try SwiftDataAssignmentRepository.makeContainer(inMemory: true))
        let value = Assignment(title: "Report", dueDate: Date())
        try repository.save([value])
        let store = try AssignmentStore(repository: repository)
        store.setStatus(value.id, to: .abandoned)
        try store.update(value.id) { $0.notes = "Newer notes" }
        store.undoLatest()
        let restored = try XCTUnwrap(store.assignment(value.id))
        XCTAssertEqual(restored.status, .active); XCTAssertNil(restored.abandonedAt)
        XCTAssertEqual(restored.notes, "Newer notes"); XCTAssertEqual(restored.localRevision, 4)
        store.setStatus(value.id, to: .completed)
        let completedAt = store.assignment(value.id)?.completedAt
        store.delete(value.id); XCTAssertNil(store.assignment(value.id))
        store.undoLatest(); XCTAssertEqual(store.assignment(value.id)?.completedAt, completedAt)
        store.undoLatest(); XCTAssertEqual(store.assignment(value.id)?.status, .active)
        store.setStatus(value.id, to: .abandoned)
        try store.update(value.id) { $0.transition(to: .completed, at: Date()) }
        store.undoLatest()
        XCTAssertEqual(store.assignment(value.id)?.status, .completed)
        XCTAssertEqual(try repository.fetchAll().count, 1)
    }
}
