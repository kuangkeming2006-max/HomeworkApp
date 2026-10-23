import Foundation
import Observation

/// Measures the actual scrolling heading against the native bar's visible edge.
@Observable @MainActor
final class AssignmentHeadingLayout {
    private(set) var isCompact = false
    func update(headerBottom: CGFloat, visibleTop: CGFloat) {
        let remaining = headerBottom - visibleTop
        if isCompact {
            if remaining > 8 { isCompact = false }
        } else if remaining < 0 { isCompact = true }
    }
}
