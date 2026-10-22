import SwiftUI
import UIKit

/// SwiftUI has no attempted-pop callback. Intercept only dirty editors using public UIKit hooks;
/// the system's Back button, navigation controller and clean interactive gestures remain native.
struct EditorDismissalGuard: UIViewControllerRepresentable {
    let needsConfirmation: Bool
    let onAttempt: () -> Void

    func makeUIViewController(context: Context) -> Controller { Controller() }
    func updateUIViewController(_ controller: Controller, context: Context) {
        controller.needsConfirmation = needsConfirmation
        controller.onAttempt = onAttempt
        controller.install()
    }
    static func dismantleUIViewController(_ controller: Controller, coordinator: ()) { controller.restore() }

    final class Controller: UIViewController, UIGestureRecognizerDelegate, UIAdaptivePresentationControllerDelegate {
        var needsConfirmation = false
        var onAttempt: () -> Void = {}
        private weak var owner: UIViewController?
        private var priorBack: UIAction?
        private var gestures: [(UIGestureRecognizer, (any UIGestureRecognizerDelegate)?)] = []
        private weak var presentation: UIPresentationController?
        private weak var priorPresentation: (any UIAdaptivePresentationControllerDelegate)?

        override func loadView() { view = UIView(); view.isUserInteractionEnabled = false }
        override func viewDidAppear(_ animated: Bool) { super.viewDidAppear(animated); install() }
        override func viewWillDisappear(_ animated: Bool) { restore(); super.viewWillDisappear(animated) }

        func install() {
            guard isViewLoaded, view.window != nil, let navigation = navigationController,
                  let top = navigation.topViewController, view.isDescendant(of: top.view) else { return }
            guard needsConfirmation else { restore(); return }
            if owner == nil {
                owner = top; priorBack = top.navigationItem.backAction
                top.navigationItem.backAction = UIAction(title: "Back", image: UIImage(systemName: "chevron.backward")) { [weak self] _ in
                    self?.onAttempt()
                }
                for gesture in [navigation.interactivePopGestureRecognizer, navigation.interactiveContentPopGestureRecognizer].compactMap({ $0 }) {
                    gestures.append((gesture, gesture.delegate)); gesture.delegate = self
                }
                if let presenter = navigation.presentationController {
                    presentation = presenter; priorPresentation = presenter.delegate; presenter.delegate = self
                }
            }
        }

        func restore() {
            owner?.navigationItem.backAction = priorBack
            for (gesture, delegate) in gestures where gesture.delegate === self { gesture.delegate = delegate }
            if presentation?.delegate === self { presentation?.delegate = priorPresentation }
            gestures.removeAll(); owner = nil; presentation = nil
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard needsConfirmation, navigationController?.topViewController === owner else { return true }
            onAttempt(); return false
        }
        func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool { !needsConfirmation }
        func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) { onAttempt() }
    }
}
