import SwiftUI
import UIKit

@MainActor
final class AssignmentScrollInteraction {
    weak var scrollView: UIScrollView?
    var isUserScrolling: Bool { scrollView?.isDragging == true || scrollView?.isDecelerating == true }
}

/// Reads the existing native scroll view; it adds no gesture recognizer.
struct AssignmentScrollProbe: UIViewRepresentable {
    let interaction: AssignmentScrollInteraction
    func makeUIView(context: Context) -> Probe { Probe(interaction: interaction) }
    func updateUIView(_ view: Probe, context: Context) { view.connect() }

    final class Probe: UIView {
        let interaction: AssignmentScrollInteraction
        init(interaction: AssignmentScrollInteraction) {
            self.interaction = interaction
            super.init(frame: .zero)
            isUserInteractionEnabled = false
            isAccessibilityElement = false
        }
        required init?(coder: NSCoder) { return nil }
        override func didMoveToWindow() { super.didMoveToWindow(); connect() }
        override func didMoveToSuperview() { super.didMoveToSuperview(); connect() }
        func connect() {
            var ancestor = superview
            while let view = ancestor {
                if let scroll = view as? UIScrollView { interaction.scrollView = scroll; return }
                ancestor = view.superview
            }
        }
    }
}

struct AssignmentSearchField: UIViewRepresentable {
    @Binding var text: String
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> UISearchBar {
        let bar = UISearchBar()
        bar.searchBarStyle = .minimal
        bar.placeholder = "Search title, course or notes"
        bar.searchTextField.accessibilityLabel = "Search assignments"
        bar.searchTextField.accessibilityIdentifier = "assignments.search"
        bar.searchTextField.adjustsFontForContentSizeCategory = true
        bar.delegate = context.coordinator
        return bar
    }

    func updateUIView(_ bar: UISearchBar, context: Context) {
        context.coordinator.parent = self
        if bar.text != text { bar.text = text }
        bar.tintColor = UIColor(context.environment.appAccent)
    }

    @MainActor
    final class Coordinator: NSObject, UISearchBarDelegate {
        var parent: AssignmentSearchField
        init(parent: AssignmentSearchField) { self.parent = parent }
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) { parent.text = searchText }
        func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) { searchBar.setShowsCancelButton(true, animated: true) }
        func searchBarTextDidEndEditing(_ searchBar: UISearchBar) { searchBar.setShowsCancelButton(false, animated: true) }
        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) { searchBar.resignFirstResponder() }
        func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            parent.text = ""
            searchBar.resignFirstResponder()
            parent.onCancel()
        }
    }
}
