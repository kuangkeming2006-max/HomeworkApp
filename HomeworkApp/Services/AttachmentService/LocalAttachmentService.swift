import Foundation
import CryptoKit
import UniformTypeIdentifiers
import HomeworkDomain

actor LocalAttachmentService: AttachmentService {
    private let directory: URL
    private let maximumBytes = 25 * 1024 * 1024

    init(directory: URL? = nil) throws {
        let root: URL
        if let directory { root = directory }
        else {
            root = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                               appropriateFor: nil, create: true)
                .appendingPathComponent("Attachments", isDirectory: true)
        }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        self.directory = root.standardizedFileURL.resolvingSymlinksInPath()
    }

    func importFile(from url: URL) throws -> AttachmentReference {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var data = Data()
        while let chunk = try handle.read(upToCount: min(1_048_576, maximumBytes + 1 - data.count)), !chunk.isEmpty {
            data.append(chunk)
            if data.count > maximumBytes { throw AssignmentError.invalid("Choose a file smaller than 25 MB.") }
        }
        let type = (try? url.resourceValues(forKeys: [.contentTypeKey]).contentType)
            ?? UTType(filenameExtension: url.pathExtension) ?? .data
        return try importData(data, name: url.lastPathComponent, contentType: type.identifier)
    }

    func importData(_ data: Data, name: String, contentType: String) throws -> AttachmentReference {
        guard !data.isEmpty, data.count <= maximumBytes else {
            throw AssignmentError.invalid("Choose a nonempty file smaller than 25 MB.")
        }
        let type = UTType(contentType) ?? .data
        let id = UUID()
        let path = id.uuidString + "." + (type.preferredFilenameExtension ?? "bin")
        let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        try data.write(to: directory.appendingPathComponent(path), options: .atomic)
        return AttachmentReference(id: id, name: String(name.prefix(255)), relativePath: path,
                                   contentType: type.identifier, byteCount: data.count, sha256: digest)
    }

    func url(for reference: AttachmentReference) throws -> URL {
        let result = try validatedURL(reference.relativePath)
        guard FileManager.default.fileExists(atPath: result.path) else {
            throw AssignmentError.invalid("This attachment is missing. Import the file again.")
        }
        return result
    }

    func remove(_ reference: AttachmentReference) throws {
        let url = try validatedURL(reference.relativePath)
        if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
    }

    func pruneOrphans(keeping paths: Set<String>, now: Date) throws {
        let files = try FileManager.default.contentsOfDirectory(at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey], options: [.skipsHiddenFiles])
        for file in files where !paths.contains(file.lastPathComponent) {
            let values = try file.resourceValues(forKeys: [.contentModificationDateKey, .isRegularFileKey])
            // A grace period protects imports still awaiting their database transaction in another window.
            if values.isRegularFile == true, let changed = values.contentModificationDate,
               now.timeIntervalSince(changed) > 86_400 {
                try FileManager.default.removeItem(at: file)
            }
        }
    }

    private func validatedURL(_ path: String) throws -> URL {
        guard !path.isEmpty, !path.contains("/"), !path.contains("\\"), path != ".", path != ".." else {
            throw AssignmentError.invalid("The attachment reference is invalid.")
        }
        let url = directory.appendingPathComponent(path).standardizedFileURL.resolvingSymlinksInPath()
        guard url.deletingLastPathComponent() == directory else {
            throw AssignmentError.invalid("The attachment reference is outside this app's storage.")
        }
        return url
    }
}
