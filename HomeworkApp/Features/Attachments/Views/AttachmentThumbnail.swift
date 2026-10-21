import SwiftUI
import UniformTypeIdentifiers
import HomeworkDomain

struct AttachmentThumbnail: View {
    let reference: AttachmentReference
    var size: CGFloat = 48
    var wide = false
    @Environment(\.attachmentService) private var service
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image { Image(uiImage: image).resizable().scaledToFill() }
            else { Image(systemName: UTType(reference.contentType)?.conforms(to: .image) == true ? "photo" : "doc.text")
                .font(.system(size: size * 0.5)).foregroundStyle(.secondary).frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.quaternary) }
        }
        .frame(width: wide ? nil : size, height: size)
        .frame(maxWidth: wide ? .infinity : nil).clipped().clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityLabel("Image preview")
        .task(id: "\(reference.sha256).\(size)") {
            guard let service else { return }
            if let data = await AttachmentThumbnailCache.shared.thumbnail(reference, service: service, pixels: wide ? 1080 : Int(size * 3)) {
                guard !Task.isCancelled else { return }; image = UIImage(data: data)
            }
        }
    }
}
