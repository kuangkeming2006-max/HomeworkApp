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
    @Environment(\.appReduceMotion) private var reduceMotion
    @State private var model = AttachmentImagePreviewModel()
    @State private var drag: CGFloat = 0
    @State private var zoom: CGFloat = 1
    @State private var pan: CGSize = .zero
    @State private var translation: CGSize = .zero
    @State private var zoomedDrag = false
    @GestureState private var pinching = false
    @GestureState private var magnification: CGFloat = 1

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                Color.black.opacity(1 - min(drag / max(geometry.size.height, 1), 0.7)).ignoresSafeArea()
                Group {
                    if let image = model.image {
                        Image(uiImage: image).resizable().scaledToFit()
                            .scaleEffect(zoom * magnification * (reduceMotion ? 1 : 1 - min(drag / 1600, 0.2)))
                            .offset(x: pan.width + translation.width, y: pan.height + translation.height + drag)
                            .accessibilityLabel("Image preview")
                            .accessibilityIdentifier("attachment.image.content")
                    } else if model.failed {
                        ContentUnavailableView("Unable to open image", systemImage: "photo.badge.exclamationmark")
                            .foregroundStyle(.white)
                    } else { ProgressView().tint(.white) }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 12)
                    .onChanged { value in
                        if zoom * magnification > 1.01 || pinching || zoomedDrag {
                            zoomedDrag = true; drag = 0
                            let proposed = CGSize(width: pan.width + value.translation.width, height: pan.height + value.translation.height)
                            let limited = constrained(proposed, scale: zoom * magnification, viewport: geometry.size, rubberBand: true)
                            translation = CGSize(width: limited.width - pan.width, height: limited.height - pan.height)
                            return
                        }
                        guard abs(value.translation.height) > abs(value.translation.width) * 1.2 else { return }
                        drag = max(0, value.translation.height)
                    }
                    .onEnded { value in
                        if zoomedDrag || zoom > 1.01 || pinching {
                            let proposed = CGSize(width: pan.width + translation.width, height: pan.height + translation.height)
                            pan = proposed; translation = .zero; zoomedDrag = false; drag = 0
                            withAnimation(spring) { pan = constrained(proposed, scale: zoom, viewport: geometry.size) }
                            return
                        }
                        if drag > 100 || (drag > 30 && value.predictedEndTranslation.height > 230) {
                            dismiss()
                        } else {
                            withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.86)) { drag = 0 }
                        }
                    })
                .simultaneousGesture(MagnifyGesture()
                    .updating($magnification) { value, state, _ in state = value.magnification }
                    .updating($pinching) { _, state, _ in state = true }
                    .onChanged { _ in zoomedDrag = true; drag = 0 }
                    .onEnded { value in
                        withAnimation(spring) {
                            zoom = min(5, max(1, zoom * value.magnification))
                            pan = constrained(pan, scale: zoom, viewport: geometry.size)
                            if zoom == 1 { pan = .zero; translation = .zero }
                        }
                        zoomedDrag = zoom > 1.01
                    })
                .onTapGesture(count: 2) {
                    withAnimation(spring) { zoom = zoom > 1 ? 1 : 2; pan = .zero; translation = .zero; drag = 0; zoomedDrag = zoom > 1.01 }
                }
                HStack {
                    Group {
                        if let url = model.shareURL {
                            ShareLink(item: url) { Label("Share image", systemImage: "square.and.arrow.up") }
                        } else {
                            Button("Share image", systemImage: "square.and.arrow.up") {}.disabled(true)
                        }
                    }
                    .accessibilityIdentifier("attachment.image.share")
                    Spacer()
                    Button("Close image", systemImage: "xmark") { dismiss() }
                        .accessibilityIdentifier("attachment.image.close")
                }
                .labelStyle(.iconOnly).font(.title3.weight(.semibold))
                .buttonStyle(.glass).buttonBorderShape(.circle).tint(.white)
                .padding()
            }
        }
        .statusBarHidden()
        .onChange(of: pinching) { _, active in
            if !active, zoom <= 1.01 { zoomedDrag = false; pan = .zero; translation = .zero }
        }
        .accessibilityAction(.escape) { dismiss() }
        .task(id: reference.id) {
            await model.load(reference, service: service)
        }
    }

    private var spring: Animation? { reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.86) }

    private func constrained(_ offset: CGSize, scale: CGFloat, viewport: CGSize, rubberBand: Bool = false) -> CGSize {
        guard let image = model.image, image.size.width > 0, image.size.height > 0 else { return .zero }
        let fit = min(viewport.width / image.size.width, viewport.height / image.size.height)
        let horizontal = max(0, (image.size.width * fit * scale - viewport.width) / 2)
        let vertical = max(0, (image.size.height * fit * scale - viewport.height) / 2)
        func limit(_ value: CGFloat, _ bound: CGFloat) -> CGFloat {
            let clamped = min(bound, max(-bound, value))
            return clamped + (rubberBand ? (value - clamped) * 0.2 : 0)
        }
        return CGSize(width: limit(offset.width, horizontal), height: limit(offset.height, vertical))
    }
}
