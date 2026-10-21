import SwiftUI
import UIKit

/// Adds outside-tap dismissal to a native sheet without replacing its material,
/// geometry, dimming view or presentation animation.
struct SheetOutsideTapDismissal: UIViewRepresentable {
    let dismiss: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(dismiss: dismiss) }

    func makeUIView(context: Context) -> Probe {
        let view = Probe()
        view.install = { [weak coordinator = context.coordinator] view in coordinator?.install(from: view) }
        return view
    }

    func updateUIView(_ view: Probe, context: Context) {
        context.coordinator.dismiss = dismiss
        context.coordinator.install(from: view)
    }

    static func dismantleUIView(_ view: Probe, coordinator: Coordinator) { coordinator.remove() }

    final class Probe: UIView {
        var install: ((UIView) -> Void)?
        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard window != nil else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                install?(self)
            }
        }
    }

    @MainActor final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var dismiss: () -> Void
        private weak var container: UIView?
        private weak var presented: UIView?
        private var gesture: UITapGestureRecognizer?

        init(dismiss: @escaping () -> Void) { self.dismiss = dismiss }

        func install(from view: UIView) {
            var responder: UIResponder? = view
            while let current = responder {
                if let controller = current as? UIViewController,
                   controller.presentingViewController != nil,
                   let presentation = controller.presentationController,
                   let container = presentation.containerView,
                   let presented = presentation.presentedView {
                    guard self.container !== container else { return }
                    remove()
                    self.container = container
                    self.presented = presented
                    let gesture = UITapGestureRecognizer(target: self, action: #selector(tappedOutside))
                    gesture.delegate = self
                    gesture.cancelsTouchesInView = false
                    container.addGestureRecognizer(gesture)
                    self.gesture = gesture
                    return
                }
                responder = current.next
            }
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            guard let container, let presented else { return false }
            return !presented.convert(presented.bounds, to: container).contains(touch.location(in: container))
        }

        @objc private func tappedOutside() { dismiss() }

        func remove() {
            if let gesture { container?.removeGestureRecognizer(gesture) }
            gesture = nil
            container = nil
            presented = nil
        }
    }
}
