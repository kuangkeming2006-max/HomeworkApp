import Foundation
import Observation
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import HomeworkDomain

@Observable @MainActor
final class AttachmentViewModel {
    private let assignmentID: UUID
    private let store: AssignmentStore
    private let service: any AttachmentService
    private(set) var busy = false
    var errorMessage: String?
    var previewURL: URL?
    var references: [AttachmentReference] { store.assignment(assignmentID)?.attachments ?? [] }

    init(assignmentID: UUID, store: AssignmentStore, service: any AttachmentService) {
        self.assignmentID = assignmentID; self.store = store; self.service = service
    }

    func importFiles(_ result: Result<[URL], Error>) async {
        guard !busy else { return }
        busy = true; defer { busy = false }
        do {
            for url in try result.get() {
                let reference = try await service.importFile(from: url)
                try await commit(reference)
            }
        } catch { errorMessage = error.localizedDescription }
    }

    func importPhotos(_ items: [PhotosPickerItem]) async {
        guard !busy, !items.isEmpty else { return }
        busy = true; defer { busy = false }
        do {
            for item in items {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    throw AssignmentError.invalid("This image could not be loaded.")
                }
                let type = item.supportedContentTypes.first ?? .image
                let reference = try await service.importData(data, name: "Image.\(type.preferredFilenameExtension ?? "img")",
                                                              contentType: type.identifier)
                try await commit(reference)
            }
        } catch { errorMessage = error.localizedDescription }
    }

    private func commit(_ reference: AttachmentReference) async throws {
        do {
            if references.contains(where: { $0.sha256 == reference.sha256 }) {
                try await service.remove(reference)
                return
            }
            try store.update(assignmentID) { $0.attachments.append(reference) }
        } catch {
            try? await service.remove(reference)
            throw error
        }
    }

    func preview(_ reference: AttachmentReference) async {
        do { previewURL = try await service.url(for: reference) }
        catch { errorMessage = error.localizedDescription }
    }

    func remove(_ reference: AttachmentReference) async {
        do {
            try store.update(assignmentID) { $0.attachments.removeAll { $0.id == reference.id } }
            let stillReferenced = store.assignments.contains { $0.deletedAt == nil && $0.attachments.contains { $0.relativePath == reference.relativePath } }
            if !stillReferenced { try await service.remove(reference) }
        } catch { errorMessage = error.localizedDescription }
    }
}
