import SwiftUI
import QuickLook
import HomeworkDomain

extension View {
    func attachmentPreview(_ model: AttachmentPreviewModel) -> some View {
        modifier(AttachmentPreviewPresentation(model: model))
    }
}

private struct AttachmentPreviewPresentation: ViewModifier {
    @Bindable var model: AttachmentPreviewModel
    func body(content: Content) -> some View {
        content
            .fullScreenCover(item: $model.image) { reference in
                FullScreenImagePreview(reference: reference).presentationBackground(.clear)
            }
            .quickLookPreview($model.documentURL)
            .alert("Unable to open attachment", isPresented: Binding(
                get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })) {
                    Button("OK", role: .cancel) { model.errorMessage = nil }
                } message: { Text(model.errorMessage ?? "Please try again.") }
    }
}

private struct FullScreenImagePreview: View {
    let reference: AttachmentReference
    @Environment(\.dismiss) private var dismiss
    @Environment(\.attachmentService) private var service
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var image: UIImage?
    @State private var failed = false
    @State private var drag: CGFloat = 0
    @State private var zoom: CGFloat = 1
    @GestureState private var magnification: CGFloat = 1

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                Color.black.opacity(1 - min(drag / max(geometry.size.height, 1), 0.7)).ignoresSafeArea()
                Group {
                    if let image {
                        Image(uiImage: image).resizable().scaledToFit()
                            .scaleEffect(zoom * magnification * (reduceMotion ? 1 : 1 - min(drag / 1600, 0.2)))
                            .offset(y: drag)
                            .accessibilityLabel("Image preview")
                            .accessibilityIdentifier("attachment.image.content")
                    } else if failed {
                        ContentUnavailableView("Unable to open image", systemImage: "photo.badge.exclamationmark")
                            .foregroundStyle(.white)
                    } else { ProgressView().tint(.white) }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 12)
                    .onChanged { value in
                        guard abs(value.translation.height) > abs(value.translation.width) * 1.2 else { return }
                        drag = max(0, value.translation.height)
                    }
                    .onEnded { value in
                        if drag > 100 || (drag > 30 && value.predictedEndTranslation.height > 230) {
                            dismiss()
                        } else {
                            withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.86)) { drag = 0 }
                        }
                    })
                .simultaneousGesture(MagnifyGesture()
                    .updating($magnification) { value, state, _ in state = value.magnification }
                    .onEnded { value in zoom = min(3, max(1, zoom * value.magnification)) })
                .onTapGesture(count: 2) {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.22)) { zoom = zoom > 1 ? 1 : 2 }
                }
                Button("Close image", systemImage: "xmark") { dismiss() }
                    .labelStyle(.iconOnly).font(.title3.weight(.semibold))
                    .foregroundStyle(.white).padding(12)
                    .background(.black.opacity(0.5), in: Circle()).padding()
                    .accessibilityIdentifier("attachment.image.close")
            }
        }
        .statusBarHidden()
        .accessibilityAction(.escape) { dismiss() }
        .task(id: reference.id) {
            guard let service,
                  let data = await AttachmentThumbnailCache.shared.thumbnail(reference, service: service, pixels: 2560),
                  !Task.isCancelled else { failed = true; return }
            image = UIImage(data: data)
            failed = image == nil
        }
    }
}
