import Foundation
import Observation

/// Tracks user scrolling separately from navigation/search inset changes.
@Observable @MainActor
final class AssignmentHeadingLayout {
    private(set) var isCompact = false
    @ObservationIgnored private var scrolling = false
    @ObservationIgnored private var previousOffset: CGFloat?
    @ObservationIgnored private var previousInset: CGFloat?
    @ObservationIgnored private var distance: CGFloat = 0

    func setScrolling(_ value: Bool) {
        scrolling = value
        if !value { distance = max(0, distance) }
    }

    func update(offset: CGFloat, topInset: CGFloat) {
        defer { previousOffset = offset; previousInset = topInset }
        guard scrolling, let previousOffset, let previousInset,
              abs(topInset - previousInset) < 0.5 else { return }
        // Preserve negative overscroll until it springs back. Clamping each frame
        // would misread that return motion as scrolling upward into the list.
        distance += offset - previousOffset
        if isCompact {
            if distance < 8 { isCompact = false }
        } else if distance > 80 { isCompact = true }
    }

    func reset() {
        distance = 0; previousOffset = nil; previousInset = nil; isCompact = false
    }
}
