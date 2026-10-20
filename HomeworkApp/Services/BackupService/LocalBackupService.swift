import Foundation
import CryptoKit
import HomeworkDomain

actor LocalBackupService: BackupService {
    private let attachments: any AttachmentService
    init(attachments: any AttachmentService) { self.attachments = attachments }

    func export(_ assignments: [Assignment]) async throws -> Data {
        let values = assignments.filter { $0.deletedAt == nil }
        var files: [BackupArchive.File] = []
        var seen = Set<UUID>()
        var bytes = 0
        for value in values {
            try value.validate()
            for reference in value.attachments where seen.insert(reference.id).inserted {
                let url = try await attachments.url(for: reference)
                let data = try readBounded(url, limit: 25 * 1024 * 1024)
                guard data.count == reference.byteCount, digest(data) == reference.sha256.lowercased() else { throw BackupError.integrity }
                bytes += data.count
                guard bytes <= 75 * 1024 * 1024 else { throw BackupError.tooLarge }
                files.append(.init(attachmentID: reference.id, data: data))
            }
        }
        let archive = BackupArchive(assignments: values, files: files)
        try archive.validate()
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(archive)
        guard data.count <= BackupArchive.maximumDocumentBytes else { throw BackupError.tooLarge }
        return data
    }

    func read(from url: URL) throws -> BackupArchive {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        return try decode(readBounded(url, limit: BackupArchive.maximumDocumentBytes))
    }

    func decode(_ data: Data) throws -> BackupArchive {
        guard data.count <= BackupArchive.maximumDocumentBytes else { throw BackupError.tooLarge }
        let archive: BackupArchive
        do { archive = try JSONDecoder().decode(BackupArchive.self, from: data) }
        catch { throw BackupError.invalid }
        try archive.validate()
        let references = Dictionary(archive.assignments.flatMap(\.attachments).map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        for file in archive.files {
            guard let reference = references[file.attachmentID], digest(file.data) == reference.sha256.lowercased() else { throw BackupError.integrity }
        }
        return archive
    }

    /// Writes unique copies first. The caller commits the complete batch in one repository transaction.
    func stage(_ archive: BackupArchive, excluding existingIDs: Set<UUID>) async throws -> RestoredBatch {
        try archive.validate()
        let values = archive.newAssignments(existingIDs: existingIDs)
        let needed = Set(values.flatMap(\.attachments).map(\.id))
        let references = Dictionary(values.flatMap(\.attachments).map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var imported: [UUID: AttachmentReference] = [:]
        do {
            for file in archive.files where needed.contains(file.attachmentID) {
                guard let reference = references[file.attachmentID], digest(file.data) == reference.sha256.lowercased() else { throw BackupError.integrity }
                var copy = try await attachments.importData(file.data, name: reference.name, contentType: reference.contentType)
                copy.createdAt = reference.createdAt
                imported[file.attachmentID] = copy
            }
            let restored = try values.map { value in
                var record = value
                record.attachments = try value.attachments.map { reference in
                    guard let copy = imported[reference.id] else { throw BackupError.invalid }
                    return copy
                }
                return record
            }
            return RestoredBatch(assignments: restored, createdFiles: Array(imported.values))
        } catch {
            await discard(Array(imported.values))
            throw error
        }
    }

    func discard(_ files: [AttachmentReference]) async {
        for file in files { try? await attachments.remove(file) }
    }

    private func readBounded(_ url: URL, limit: Int) throws -> Data {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var data = Data()
        while let chunk = try handle.read(upToCount: min(1_048_576, limit + 1 - data.count)), !chunk.isEmpty {
            data.append(chunk)
            if data.count > limit { throw BackupError.tooLarge }
        }
        return data
    }

    private func digest(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
