import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import HomeworkDomain

struct AttachmentList: View {
    @State private var model: AttachmentViewModel
    @State private var importing = false
    @State private var photos: [PhotosPickerItem] = []

    init(assignmentID: UUID, store: AssignmentStore, service: any AttachmentService) {
        _model = State(initialValue: AttachmentViewModel(assignmentID: assignmentID, store: store, service: service))
    }

    init(model: AttachmentViewModel) { _model = State(initialValue: model) }

    var body: some View {
        Section("Attachments") {
            ForEach(model.references) { reference in
                HStack {
                    Button { Task { await model.preview(reference) } } label: {
                        HStack(spacing: 12) {
                            AttachmentThumbnail(reference: reference, size: 72)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(reference.name).lineLimit(2)
                                Text(ByteCountFormatter.string(fromByteCount: Int64(reference.byteCount), countStyle: .file))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                        }.frame(maxWidth: .infinity, alignment: .leading)
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
            // Separate borderless controls prevent Form's automatic row-wide button activation
            // from opening both pickers when Files is tapped.
                PhotosPicker(selection: $photos, maxSelectionCount: 5, matching: .images) {
                    Label("Photos", systemImage: "photo.badge.plus")
                }
                .buttonStyle(.borderless).disabled(model.busy)
                .accessibilityIdentifier("attachments.photos")
                Button("Files", systemImage: "folder.badge.plus") { importing = true }
                    .buttonStyle(.borderless).disabled(model.busy)
                    .accessibilityIdentifier("attachments.files")
            if model.busy { ProgressView("Importing…") }
            if let message = model.errorMessage { Text(message).foregroundStyle(.red) }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.item], allowsMultipleSelection: true) { result in
            Task { await model.importFiles(result) }
        }
        .onChange(of: photos) { _, items in Task { await model.importPhotos(items); photos = [] } }
    }
}
