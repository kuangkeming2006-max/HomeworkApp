import SwiftUI
import UIKit

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
