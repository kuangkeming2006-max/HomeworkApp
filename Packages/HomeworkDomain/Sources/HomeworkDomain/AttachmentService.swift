import Foundation

public protocol AttachmentService: Sendable {
    func importFile(from url: URL) async throws -> AttachmentReference
    func importData(_ data: Data, name: String, contentType: String) async throws -> AttachmentReference
    func url(for reference: AttachmentReference) async throws -> URL
    func remove(_ reference: AttachmentReference) async throws
    func pruneOrphans(keeping paths: Set<String>, now: Date) async throws
}
