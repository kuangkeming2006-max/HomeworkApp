import Foundation
import Observation
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import HomeworkDomain

@Observable @MainActor
final class AttachmentViewModel {
    private let assignmentID: UUID?
    private let store: AssignmentStore?
    private let service: any AttachmentService
    private var draftReferences: [AttachmentReference] = []
    private var draftChanged: (([AttachmentReference]) -> Void)?
    private var staged: [AttachmentReference] = []
    private var closed = false
    private(set) var busy = false
    var errorMessage: String?
    let previewPresentation = AttachmentPreviewModel()
    var references: [AttachmentReference] {
        if let store, let assignmentID { return store.assignment(assignmentID)?.attachments ?? [] }
        return draftReferences
    }

    init(assignmentID: UUID, store: AssignmentStore, service: any AttachmentService) {
        self.assignmentID = assignmentID; self.store = store; self.service = service
    }

    init(service: any AttachmentService, draftChanged: @escaping ([AttachmentReference]) -> Void) {
        self.service = service; self.draftChanged = draftChanged
        assignmentID = nil; store = nil
    }

    isolated deinit {
        let files = staged
        let storage = service
        Task { for reference in files { try? await storage.remove(reference) } }
    }

    func markCommitted() { staged.removeAll(); draftChanged = nil }

    func close() async {
        closed = true
        let files = staged; staged.removeAll()
        for reference in files { try? await service.remove(reference) }
    }

    func importFiles(_ result: Result<[URL], Error>) async {
        guard !busy else { return }
        busy = true; errorMessage = nil; defer { busy = false }
        do {
            for url in try result.get() {
                let reference = try await service.importFile(from: url)
                try await commit(reference)
            }
        } catch {
            if (error as? CocoaError)?.code != .userCancelled { errorMessage = error.localizedDescription }
        }
    }

    func importPhotos(_ items: [PhotosPickerItem]) async {
        guard !busy, !items.isEmpty else { return }
        busy = true; errorMessage = nil; defer { busy = false }
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
            guard !closed else { try await service.remove(reference); return }
            guard references.count < 100 else { throw AssignmentError.invalid("An assignment can contain up to 100 attachments.") }
            if references.contains(where: { $0.sha256 == reference.sha256 }) {
                try await service.remove(reference)
                return
            }
            if let store, let assignmentID {
                try store.update(assignmentID) { $0.attachments.append(reference) }
            } else {
                staged.append(reference); draftReferences.append(reference); draftChanged?(draftReferences)
            }
        } catch {
            try? await service.remove(reference)
            throw error
        }
    }

    func preview(_ reference: AttachmentReference) async {
        await previewPresentation.open(reference, service: service)
    }

    func remove(_ reference: AttachmentReference) async {
        do {
            if let store, let assignmentID {
                try store.update(assignmentID) { $0.attachments.removeAll { $0.id == reference.id } }
            } else {
                draftReferences.removeAll { $0.id == reference.id }; staged.removeAll { $0.id == reference.id }
                draftChanged?(draftReferences)
            }
            let stillReferenced = store?.assignments.contains { $0.deletedAt == nil && $0.attachments.contains { $0.relativePath == reference.relativePath } } ?? false
            if !stillReferenced { try await service.remove(reference) }
        } catch { errorMessage = error.localizedDescription }
    }
}
