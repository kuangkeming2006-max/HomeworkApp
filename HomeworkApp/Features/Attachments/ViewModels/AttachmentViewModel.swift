import Foundation
import Observation
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import HomeworkDomain

@Observable @MainActor
final class AttachmentViewModel {
    private let service: any AttachmentService
    private var draftReferences: [AttachmentReference]
    private let original: [AttachmentReference]
    private var draftChanged: (([AttachmentReference]) -> Void)?
    private var staged: [AttachmentReference] = []
    private var closed = false
    private(set) var busy = false
    var errorMessage: String?
    var pendingRemoval: AttachmentReference?
    let previewPresentation = AttachmentPreviewModel()
    var references: [AttachmentReference] { draftReferences }

    init(service: any AttachmentService, references: [AttachmentReference] = [],
         draftChanged: @escaping ([AttachmentReference]) -> Void) {
        self.service = service; self.draftChanged = draftChanged
        original = references; draftReferences = references
    }

    isolated deinit {
        let files = staged, storage = service
        Task { for reference in files { try? await storage.remove(reference) } }
    }

    /// Only after the record commits may old, unreferenced files be removed.
    func finishCommit(retaining paths: Set<String>) async {
        closed = true
        let unused = (original + staged).filter { !paths.contains($0.relativePath) }
        staged.removeAll(); draftChanged = nil
        for reference in unused {
            do { try await service.remove(reference) }
            catch { errorMessage = "Saved, but an unused attachment could not be cleaned up: \(error.localizedDescription)" }
        }
    }

    func close() async {
        closed = true
        let files = staged; staged.removeAll()
        for reference in files { try? await service.remove(reference) }
    }

    func importFiles(_ result: Result<[URL], Error>) async {
        guard !busy, !closed else { return }
        busy = true; errorMessage = nil; defer { busy = false }
        do {
            for url in try result.get() {
                let reference = try await service.importFile(from: url)
                try await stage(reference)
            }
        } catch {
            if (error as? CocoaError)?.code != .userCancelled { errorMessage = error.localizedDescription }
        }
    }

    func importPhotos(_ items: [PhotosPickerItem]) async {
        guard !busy, !closed, !items.isEmpty else { return }
        busy = true; errorMessage = nil; defer { busy = false }
        do {
            for item in items {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    throw AssignmentError.invalid("This image could not be loaded.")
                }
                let type = item.supportedContentTypes.first ?? .image
                let reference = try await service.importData(data, name: "Image.\(type.preferredFilenameExtension ?? "img")",
                                                            contentType: type.identifier)
                try await stage(reference)
            }
        } catch { errorMessage = error.localizedDescription }
    }

    private func stage(_ reference: AttachmentReference) async throws {
        do {
            guard !closed else { try await service.remove(reference); return }
            guard references.count < 100 else { throw AssignmentError.invalid("An assignment can contain up to 100 attachments.") }
            if references.contains(where: { $0.sha256 == reference.sha256 }) {
                try await service.remove(reference); return
            }
            staged.append(reference); draftReferences.append(reference); draftChanged?(draftReferences)
        } catch { try? await service.remove(reference); throw error }
    }

    func preview(_ reference: AttachmentReference) async {
        await previewPresentation.open(reference, service: service)
    }

    func remove(_ reference: AttachmentReference) async {
        draftReferences.removeAll { $0.id == reference.id }
        draftChanged?(draftReferences)
        // Existing files remain untouched until Save. Newly imported files are owned by this draft.
        if staged.contains(where: { $0.id == reference.id }) {
            do {
                try await service.remove(reference)
                staged.removeAll { $0.id == reference.id }
            } catch { errorMessage = error.localizedDescription }
        }
    }
}
