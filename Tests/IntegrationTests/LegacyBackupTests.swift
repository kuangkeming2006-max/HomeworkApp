import Foundation
import XCTest
import HomeworkDomain
@testable import HomeworkApp

@MainActor
final class LegacyBackupTests: XCTestCase {
    func testVersionOneBackupRestoresCompletionAndAttachmentBytes() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let source = try LocalAttachmentService(directory: root.appendingPathComponent("source"))
        let bytes = Data("Legacy attachment".utf8)
        var task = Assignment(title: "Legacy coursework", dueDate: Date())
        task.transition(to: .completed, at: Date())
        task.attachments = [try await source.importData(bytes, name: "legacy.txt", contentType: "public.plain-text")]
        let exported = try await LocalBackupService(attachments: source).export([task])
        var archive = try XCTUnwrap(JSONSerialization.jsonObject(with: exported) as? [String: Any])
        var records = try XCTUnwrap(archive["assignments"] as? [[String: Any]])
        for index in records.indices { records[index].removeValue(forKey: "status"); records[index].removeValue(forKey: "abandonedAt") }
        archive["assignments"] = records
        let url = root.appendingPathComponent("v1.homeworkbackup")
        try JSONSerialization.data(withJSONObject: archive).write(to: url)
        let files = try LocalAttachmentService(directory: root.appendingPathComponent("restored"))
        let store = try AssignmentStore(repository: SwiftDataAssignmentRepository(container: SwiftDataAssignmentRepository.makeContainer(inMemory: true)))
        let model = BackupViewModel(store: store, service: LocalBackupService(attachments: files))
        await model.read(url); XCTAssertEqual(model.newCount, 1)
        await model.restore()
        let restored = try XCTUnwrap(store.assignment(task.id))
        XCTAssertEqual(restored.status, .completed); XCTAssertEqual(restored.completedAt, task.completedAt)
        let attachment = try XCTUnwrap(restored.attachments.first)
        let copied = try await files.url(for: attachment)
        XCTAssertEqual(try Data(contentsOf: copied), bytes)
    }
}
