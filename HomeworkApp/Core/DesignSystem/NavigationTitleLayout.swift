import SwiftUI
import UIKit
import Observation

/// Reads native bar layout; it never changes category selection or the scroll position.
@Observable @MainActor
final class NavigationTitleLayout {
    private(set) var isCompact = false
    @ObservationIgnored private weak var bar: UINavigationBar?
    @ObservationIgnored private var active = false
    @ObservationIgnored private var pending = false

    func attach(_ bar: UINavigationBar?) { self.bar = bar; refresh() }
    func activate() { active = true; refresh() }
    func deactivate() { active = false; isCompact = false }

    func refresh() {
        guard active, !pending else { return }
        pending = true
        // UIKit completes bar layout after its scroll callback. No timer or display link.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.pending = false
            guard self.active, let bar = self.bar else { return }
            // A collapsed iPhone bar is 44 points (32 in compact-height landscape).
            let compact = bar.bounds.height <= 44.5
            if compact != self.isCompact { self.isCompact = compact }
        }
    }
}

struct NavigationTitleLayoutReader: UIViewControllerRepresentable {
    let layout: NavigationTitleLayout
    func makeUIViewController(context: Context) -> Controller {
        let controller = Controller(); controller.layout = layout; return controller
    }
    func updateUIViewController(_ controller: Controller, context: Context) { controller.refresh() }

    final class Controller: UIViewController {
        var layout: NavigationTitleLayout?
        override func loadView() { view = UIView(); view.isUserInteractionEnabled = false }
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated); refresh(); layout?.activate()
        }
        override func viewDidLayoutSubviews() { super.viewDidLayoutSubviews(); refresh() }
        func refresh() { layout?.attach(navigationController?.navigationBar) }
    }
}
