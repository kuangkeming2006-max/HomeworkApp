import XCTest
@testable import HomeworkDomain

final class BackupTests: XCTestCase {
    func testRoundTripIncludesFilesAndSkipsExistingIDs() throws {
        var value = Assignment(title: "Report", dueDate: Date())
        let reference = AttachmentReference(name: "report.txt", relativePath: "file.txt", contentType: "public.plain-text",
                                            byteCount: 3, sha256: String(repeating: "a", count: 64))
        value.attachments = [reference]
        let archive = BackupArchive(assignments: [value], files: [.init(attachmentID: reference.id, data: Data([1, 2, 3]))])
        let restored = try JSONDecoder().decode(BackupArchive.self, from: JSONEncoder().encode(archive))
        try restored.validate()
        XCTAssertEqual(restored.assignments, [value])
        XCTAssertTrue(restored.newAssignments(existingIDs: [value.id]).isEmpty)
        XCTAssertEqual(restored.newAssignments(existingIDs: []).count, 1)
    }

    func testMissingDuplicateAndMismatchedFilesAreRejected() throws {
        var value = Assignment(title: "Report", dueDate: Date())
        value.attachments = [AttachmentReference(name: "a", relativePath: "a.bin", contentType: "public.data",
                                                 byteCount: 3, sha256: String(repeating: "a", count: 64))]
        XCTAssertThrowsError(try BackupArchive(assignments: [value], files: []).validate())
        let file = BackupArchive.File(attachmentID: value.attachments[0].id, data: Data([1]))
        XCTAssertThrowsError(try BackupArchive(assignments: [value], files: [file]).validate())
        XCTAssertThrowsError(try BackupArchive(assignments: [], files: [file, file]).validate())
        value.attachments[0].relativePath = "../escape"
        XCTAssertThrowsError(try value.validate())
        XCTAssertThrowsError(try BackupArchive(assignments: [value, value], files: []).validate())
    }
}
