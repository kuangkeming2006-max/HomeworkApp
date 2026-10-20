import SwiftUI
import PhotosUI

struct AIImportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: AIImportViewModel
    @State private var selectedPhotos: [PhotosPickerItem] = []

    init(store: AssignmentStore, providerFactory: @escaping LLMProviderFactory) {
        _model = State(initialValue: AIImportViewModel(store: store, providerFactory: providerFactory))
    }

    var body: some View {
        Form {
            Section("Announcement or instructions") {
                TextEditor(text: $model.text).frame(minHeight: 180)
                    .accessibilityLabel("Assignment announcement").accessibilityIdentifier("ai.input")
            }
            Section("Images") {
                PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 4, matching: .images) {
                    Label("Choose screenshots or photos", systemImage: "photo.on.rectangle")
                }
                .accessibilityIdentifier("ai.photos")
                if !model.images.isEmpty {
                    Text("\(model.images.count) images selected")
                    Button("Remove images", role: .destructive) { model.clearImages(); selectedPhotos = [] }
                }
            }
            .disabled(model.busy)
            Section {
                if model.busy { ProgressView("Reading assignments…") }
                if let message = model.message { Text(message).accessibilityIdentifier("ai.feedback") }
            } footer: {
                Text("Only this text and the selected images are sent to your configured AI provider. You will review and confirm every assignment before anything is saved.")
            }
        }
        .navigationTitle("Add with AI")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { model.cancelAnalysis(); dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Review") { model.analyze() }
                    .disabled(model.busy).accessibilityIdentifier("ai.analyze")
            }
        }
        .navigationDestination(isPresented: $model.showPreview) {
            AIImportPreview(model: model) { dismiss() }
        }
        .onChange(of: selectedPhotos) { _, items in Task { await model.loadImages(items) } }
        .onDisappear { if !model.showPreview { model.cancelAnalysis() } }
    }
}
