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
        // Install after SwiftUI has updated the native navigation item as well.
        DispatchQueue.main.async { [weak controller] in controller?.install() }
    }
    static func dismantleUIViewController(_ controller: Controller, coordinator: ()) { controller.restore() }

    final class Controller: UIViewController, UIGestureRecognizerDelegate {
        var needsConfirmation = false
        var onAttempt: () -> Void = {}
        private weak var owner: UIViewController?
        private var priorBack: UIAction?
        private var gestures: [(UIGestureRecognizer, (any UIGestureRecognizerDelegate)?)] = []

        override func loadView() { view = UIView(); view.isUserInteractionEnabled = false }
        override func viewDidAppear(_ animated: Bool) { super.viewDidAppear(animated); install() }
        override func viewWillDisappear(_ animated: Bool) { restore(); super.viewWillDisappear(animated) }

        func install() {
            guard isViewLoaded, view.window != nil, let navigation = navigationController,
                  let top = navigation.topViewController, view.isDescendant(of: top.view) else { return }
            guard needsConfirmation else { restore(); return }
            if owner == nil {
                owner = top; priorBack = top.navigationItem.backAction
                if navigation.viewControllers.count > 1 {
                    top.navigationItem.backAction = UIAction(title: "Back") { [weak self] _ in self?.onAttempt() }
                    for gesture in [navigation.interactivePopGestureRecognizer, navigation.interactiveContentPopGestureRecognizer].compactMap({ $0 }) {
                        gestures.append((gesture, gesture.delegate)); gesture.delegate = self
                    }
                }
            }
        }

        func restore() {
            owner?.navigationItem.backAction = priorBack
            for (gesture, delegate) in gestures where gesture.delegate === self { gesture.delegate = delegate }
            gestures.removeAll(); owner = nil
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard needsConfirmation, navigationController?.topViewController === owner else { return true }
            onAttempt(); return false
        }
    }
}
