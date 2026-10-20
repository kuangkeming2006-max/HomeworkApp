import SwiftUI
import UniformTypeIdentifiers
import HomeworkDomain

struct AttachmentThumbnail: View {
    let reference: AttachmentReference
    var size: CGFloat = 48
    @Environment(\.attachmentService) private var service
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image { Image(uiImage: image).resizable().scaledToFill() }
            else { Image(systemName: UTType(reference.contentType)?.conforms(to: .image) == true ? "photo" : "doc.text")
                .font(.title3).foregroundStyle(.secondary).frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.quaternary) }
        }
        .frame(width: size, height: size).clipped().clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityLabel(reference.name)
        .task(id: "\(reference.sha256).\(size)") {
            guard let service else { return }
            if let data = await AttachmentThumbnailCache.shared.thumbnail(reference, service: service, pixels: Int(size * 3)) {
                guard !Task.isCancelled else { return }; image = UIImage(data: data)
            }
        }
    }
}
