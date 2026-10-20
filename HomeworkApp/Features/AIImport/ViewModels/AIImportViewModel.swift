import Foundation
import Observation
import PhotosUI
import SwiftUI
import UIKit
import HomeworkDomain

@Observable @MainActor
final class AIImportViewModel {
    var text = ""
    private(set) var images: [LLMImage] = []
    var candidates: [ImportCandidate] = []
    var showPreview = false
    private(set) var busy = false
    var message: String?
    private let store: AssignmentStore
    private let providerFactory: LLMProviderFactory
    private var analysisTask: Task<Void, Never>?

    init(store: AssignmentStore, providerFactory: @escaping LLMProviderFactory) {
        self.store = store; self.providerFactory = providerFactory
    }

    var canConfirm: Bool {
        let selected = candidates.filter(\.selected)
        return !selected.isEmpty && selected.allSatisfy(\.ready)
    }

    func loadImages(_ items: [PhotosPickerItem]) async {
        guard !busy else { return }
        do {
            var selected: [LLMImage] = []
            for item in items.prefix(4) {
                guard let raw = try await item.loadTransferable(type: Data.self), raw.count <= 25 * 1024 * 1024,
                      let image = UIImage(data: raw) else { throw LLMError.input }
                let longest = max(image.size.width, image.size.height)
                let scale = min(1, 2000 / max(1, longest))
                let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
                let format = UIGraphicsImageRendererFormat(); format.scale = 1
                let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
                    image.draw(in: CGRect(origin: .zero, size: size))
                }
                guard let data = resized.jpegData(compressionQuality: 0.8) else { throw LLMError.input }
                selected.append(LLMImage(data: data, mimeType: "image/jpeg"))
            }
            if !selected.isEmpty { try LLMInput(text: text, images: selected).validate() }
            images = selected; message = nil
        } catch { message = error.localizedDescription }
    }

    func clearImages() { images = [] }

    func analyze() {
        guard !busy else { return }
        busy = true; message = nil
        analysisTask = Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.busy = false }
            do {
                let input = LLMInput(text: self.text, images: self.images)
                try input.validate()
                let provider = try self.providerFactory()
                let results = try await provider.extract(input, context: ImportContext(defaultReminder: self.store.defaultReminder))
                guard !Task.isCancelled else { return }
                self.candidates = results
                if results.isEmpty { self.message = "No assignments found. Try a clearer announcement or manual entry." }
                else { self.showPreview = true }
            } catch {
                if !Task.isCancelled { self.message = error.localizedDescription }
            }
        }
    }

    func cancelAnalysis() { analysisTask?.cancel() }

    @discardableResult
    func confirm() -> Bool {
        guard canConfirm else { message = "Check every selected title and confirm unclear deadlines."; return false }
        do {
            let values = candidates.filter(\.selected).map { candidate in
                var value = candidate.assignment
                value.updatedAt = max(Date(), value.createdAt)
                return value
            }
            try store.save(values)
            return true
        } catch { message = error.localizedDescription; return false }
    }
}
