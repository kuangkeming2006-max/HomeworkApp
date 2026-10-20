import XCTest
import UniformTypeIdentifiers
import HomeworkDomain
@testable import HomeworkApp

@MainActor
final class AttachmentTests: XCTestCase {
    func testCopiedAttachmentSurvivesRemovalOfOriginalAndCanBeRemoved() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("original.txt")
        let data = Data("Synthetic attachment".utf8)
        try data.write(to: source)
        let service = try LocalAttachmentService(directory: root.appendingPathComponent("persistent"))
        let reference = try await service.importFile(from: source)
        try FileManager.default.removeItem(at: source)
        let stored = try await service.url(for: reference)
        XCTAssertEqual(try Data(contentsOf: stored), data)
        XCTAssertEqual(reference.byteCount, data.count)
        XCTAssertEqual(reference.sha256.count, 64)
        try await service.remove(reference)
        XCTAssertFalse(FileManager.default.fileExists(atPath: stored.path))
    }

    func testTraversalAndEmptyFilesAreRejected() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let service = try LocalAttachmentService(directory: root)
        defer { try? FileManager.default.removeItem(at: root) }
        do {
            _ = try await service.importData(Data(), name: "empty", contentType: UTType.data.identifier)
            XCTFail("Empty attachment must fail")
        } catch { XCTAssertTrue(error is AssignmentError) }
        let invalid = AttachmentReference(name: "bad", relativePath: "../outside", contentType: "public.data", byteCount: 1, sha256: "bad")
        do { _ = try await service.url(for: invalid); XCTFail("Traversal must fail") }
        catch { XCTAssertTrue(error is AssignmentError) }
    }
}
