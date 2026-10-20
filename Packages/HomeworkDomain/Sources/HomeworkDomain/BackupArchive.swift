import Foundation

/// A versioned, self-contained JSON document. Credentials and provider settings are never included.
public struct BackupArchive: Codable, Sendable {
    public struct File: Codable, Sendable {
        public let attachmentID: UUID
        public let data: Data
        public init(attachmentID: UUID, data: Data) { self.attachmentID = attachmentID; self.data = data }
    }

    public let formatVersion: Int
    public let exportedAt: Date
    public let assignments: [Assignment]
    public let files: [File]
    public static let maximumDocumentBytes = 100 * 1024 * 1024

    public init(assignments: [Assignment], files: [File], exportedAt: Date = Date()) {
        formatVersion = 1; self.exportedAt = exportedAt; self.assignments = assignments; self.files = files
    }

    public func validate() throws {
        guard formatVersion == 1, exportedAt.timeIntervalSince1970.isFinite,
              assignments.count <= 10_000, files.count <= 1_000,
              Set(assignments.map(\.id)).count == assignments.count,
              Set(files.map(\.attachmentID)).count == files.count,
              files.reduce(0, { $0 + $1.data.count }) <= 75 * 1024 * 1024 else { throw BackupError.invalid }
        var references: [UUID: AttachmentReference] = [:]
        for assignment in assignments {
            try assignment.validate()
            for reference in assignment.attachments {
                if let previous = references[reference.id], previous != reference { throw BackupError.invalid }
                references[reference.id] = reference
            }
        }
        guard Set(files.map(\.attachmentID)) == Set(references.keys) else { throw BackupError.invalid }
        for file in files {
            guard let reference = references[file.attachmentID], file.data.count == reference.byteCount else { throw BackupError.invalid }
        }
    }

    public func newAssignments(existingIDs: Set<UUID>) -> [Assignment] {
        assignments.filter { !existingIDs.contains($0.id) }
    }
}

public enum BackupError: LocalizedError, Sendable {
    case invalid, tooLarge, integrity
    public var errorDescription: String? {
        switch self {
        case .invalid: "This backup has an invalid or unsupported format. Your existing assignments have not been changed."
        case .tooLarge: "Backups are limited to 100 MB, including encoded attachments. Export fewer or smaller attachments."
        case .integrity: "An attachment in this backup is damaged. Your existing assignments have not been changed."
        }
    }
}

public struct RestoredBatch: Sendable {
    public let assignments: [Assignment]
    public let createdFiles: [AttachmentReference]
    public init(assignments: [Assignment], createdFiles: [AttachmentReference]) {
        self.assignments = assignments; self.createdFiles = createdFiles
    }
}

public protocol BackupService: Sendable {
    func export(_ assignments: [Assignment]) async throws -> Data
    func read(from url: URL) async throws -> BackupArchive
    func stage(_ archive: BackupArchive, excluding existingIDs: Set<UUID>) async throws -> RestoredBatch
    func discard(_ files: [AttachmentReference]) async
}
