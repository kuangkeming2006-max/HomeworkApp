import SwiftUI
import PhotosUI
import QuickLook
import UniformTypeIdentifiers
import HomeworkDomain

struct AttachmentList: View {
    @State private var model: AttachmentViewModel
    @State private var importing = false
    @State private var photos: [PhotosPickerItem] = []

    init(assignmentID: UUID, store: AssignmentStore, service: any AttachmentService) {
        _model = State(initialValue: AttachmentViewModel(assignmentID: assignmentID, store: store, service: service))
    }

    var body: some View {
        Section("Attachments") {
            ForEach(model.references) { reference in
                HStack {
                    Button { Task { await model.preview(reference) } } label: {
                        Label(reference.name, systemImage: reference.contentType.contains("image") ? "photo" : "doc")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityIdentifier("attachment.preview.\(reference.id)")
                    Button("Remove attachment", systemImage: "trash", role: .destructive) {
                        Task { await model.remove(reference) }
                    }
                    .labelStyle(.iconOnly).buttonStyle(.borderless)
                    .accessibilityIdentifier("attachment.remove.\(reference.id)")
                }
            }
            HStack {
                PhotosPicker(selection: $photos, maxSelectionCount: 5, matching: .images) {
                    Label("Photos", systemImage: "photo.badge.plus")
                }
                .accessibilityIdentifier("attachments.photos")
                Spacer()
                Button("Files", systemImage: "folder.badge.plus") { importing = true }
                    .accessibilityIdentifier("attachments.files")
            }
            .disabled(model.busy)
            if model.busy { ProgressView("Importing…") }
            if let message = model.errorMessage { Text(message).foregroundStyle(.red) }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.data], allowsMultipleSelection: true) { result in
            Task { await model.importFiles(result) }
        }
        .onChange(of: photos) { _, items in Task { await model.importPhotos(items); photos = [] } }
        .quickLookPreview($model.previewURL)
    }
}
