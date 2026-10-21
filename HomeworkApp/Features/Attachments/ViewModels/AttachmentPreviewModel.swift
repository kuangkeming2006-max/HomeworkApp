import SwiftUI
import Observation
import UniformTypeIdentifiers
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
