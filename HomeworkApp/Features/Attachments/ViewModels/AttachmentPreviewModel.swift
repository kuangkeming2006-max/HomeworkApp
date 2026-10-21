import SwiftUI
import Observation
import UniformTypeIdentifiers
import UIKit
import HomeworkDomain

@Observable @MainActor
final class AttachmentPreviewModel {
    var image: AttachmentReference?
    var documentURL: URL?
    var errorMessage: String?

    func open(_ reference: AttachmentReference, service: (any AttachmentService)?) async {
        if UTType(reference.contentType)?.conforms(to: .image) == true {
            image = reference
        } else {
            guard let service else { errorMessage = "Attachment storage is unavailable."; return }
            do { documentURL = try await service.url(for: reference) }
            catch { errorMessage = error.localizedDescription }
        }
    }
}

@Observable @MainActor
final class AttachmentImagePreviewModel {
    private(set) var image: UIImage?
    private(set) var shareURL: URL?
    private(set) var failed = false

    func load(_ reference: AttachmentReference, service: (any AttachmentService)?) async {
        image = nil; shareURL = nil; failed = false
        guard let service else { failed = true; return }
        do {
            let url = try await service.url(for: reference)
            guard !Task.isCancelled else { return }
            shareURL = url
            guard let data = await AttachmentThumbnailCache.shared.thumbnail(reference, service: service, pixels: 2560),
                  !Task.isCancelled else { failed = true; return }
            image = UIImage(data: data)
            failed = image == nil
        } catch { failed = true }
    }
}
