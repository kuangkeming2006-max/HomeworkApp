import SwiftUI
import UIKit

/// Uses the public interactive UIKit subtitle view, rather than a decorative
/// SwiftUI title-placement host that can expose controls without accepting taps.
struct InteractiveNavigationSubtitle<Content: View>: UIViewControllerRepresentable {
    let content: Content

    func makeUIViewController(context: Context) -> NavigationSubtitleController {
        NavigationSubtitleController()
    }

    func updateUIViewController(_ controller: NavigationSubtitleController, context: Context) {
        controller.update(AnyView(content.environment(\.self, context.environment)))
    }

    static func dismantleUIViewController(_ controller: NavigationSubtitleController, coordinator: ()) {
        controller.detach()
    }
}

@MainActor
final class NavigationSubtitleController: UIViewController {
    private let host = UIHostingController(rootView: AnyView(EmptyView()))
    private lazy var subtitle = NavigationSubtitleView(host: host)
    private weak var item: UINavigationItem?
    private var pending = false

    override func loadView() {
        view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        host.safeAreaRegions = []
        host.view.backgroundColor = .clear
        addChild(host)
        subtitle.addSubview(host.view)
        host.didMove(toParent: self)
    }

    func update(_ content: AnyView) {
        host.rootView = content
        scheduleInstallation()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scheduleInstallation()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scheduleInstallation()
    }

    private func scheduleInstallation() {
        guard !pending else { return }
        pending = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.pending = false
            guard self.isViewLoaded, self.view.window != nil,
                  let navigation = self.navigationController,
                  let top = navigation.topViewController else { return }
            var owner: UIViewController = self
            while let parent = owner.parent, !(parent is UINavigationController) { owner = parent }
            guard top === owner else { return }
            let item = top.navigationItem
            if let previous = self.item, previous !== item,
               previous.largeSubtitleView === self.subtitle { previous.largeSubtitleView = nil }
            self.item = item
            self.subtitle.measure(width: max(1, navigation.navigationBar.bounds.width - 32))
            if item.largeSubtitleView !== self.subtitle { item.largeSubtitleView = self.subtitle }
        }
    }

    func detach() {
        if item?.largeSubtitleView === subtitle { item?.largeSubtitleView = nil }
        item = nil
    }
}

@MainActor
private final class NavigationSubtitleView: UIView {
    private let host: UIHostingController<AnyView>
    private var measuredSize = CGSize.zero

    init(host: UIHostingController<AnyView>) {
        self.host = host
        super.init(frame: .zero)
        backgroundColor = .clear
        isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) { return nil }

    func measure(width: CGFloat) {
        let size = host.sizeThatFits(in: CGSize(width: width, height: 1_000))
        let next = CGSize(width: width, height: size.height)
        if next != measuredSize {
            measuredSize = next
            frame.size = next
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    override var intrinsicContentSize: CGSize { measuredSize }
    override func layoutSubviews() {
        super.layoutSubviews()
        host.view.frame = bounds
    }
}
