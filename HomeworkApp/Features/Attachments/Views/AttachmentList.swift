import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import HomeworkDomain

struct AttachmentList: View {
    @State private var model: AttachmentViewModel
    @State private var importing = false
    @State private var photos: [PhotosPickerItem] = []

    init(model: AttachmentViewModel) { _model = State(initialValue: model) }

    var body: some View {
        Section("Attachments") {
            ForEach(model.references) { reference in
                Button { Task { await model.preview(reference) } } label: {
                    HStack(spacing: 12) {
                        if UTType(reference.contentType)?.conforms(to: .image) == true {
                            AttachmentThumbnail(reference: reference, size: 200, wide: true)
                        } else {
                            Image(systemName: "doc.text").font(.title).foregroundStyle(.secondary)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(reference.name).lineLimit(2)
                                Text(ByteCountFormatter.string(fromByteCount: Int64(reference.byteCount), countStyle: .file))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.borderless)
                .accessibilityIdentifier("attachment.preview.\(reference.id)")
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    // The destructive role belongs to the confirmation, so a swipe never
                    // optimistically removes the Form row before the user confirms.
                    Button { model.pendingRemoval = reference } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .tint(.red)
                    .accessibilityIdentifier("attachment.remove.\(reference.id)")
                }
            }
            // Both controls share a native Form row, while their independent hit areas
            // cover its left and right halves. Neither control uses row-wide activation.
            HStack(spacing: 0) {
                PhotosPicker(selection: $photos, maxSelectionCount: 5, matching: .images) {
                    Label("Photos", systemImage: "photo.badge.plus")
                        .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless).disabled(model.busy)
                .accessibilityIdentifier("attachments.photos")
                Button { importing = true } label: {
                    Label("Files", systemImage: "folder.badge.plus")
                        .frame(maxWidth: .infinity, minHeight: 24, alignment: .trailing)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless).disabled(model.busy)
                .accessibilityIdentifier("attachments.files")
            }
            .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
            if model.busy { ProgressView("Importing…") }
            if let message = model.errorMessage { Text(message).foregroundStyle(.red) }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.item], allowsMultipleSelection: true) { result in
            Task { await model.importFiles(result) }
        }
        .onChange(of: photos) { _, items in Task { await model.importPhotos(items); photos = [] } }
    }
}
