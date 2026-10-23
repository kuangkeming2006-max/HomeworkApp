import SwiftUI
import UIKit

/// Decide the axis before recognition so the surrounding native scroll view keeps vertical pans.
struct HorizontalCalendarPan: UIGestureRecognizerRepresentable {
    let onBegin: () -> Void
    let onChange: (CGFloat) -> Void
    let onEnd: (CGFloat, CGFloat) -> Void
    let onCancel: () -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator { Coordinator() }

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let recognizer = UIPanGestureRecognizer()
        recognizer.maximumNumberOfTouches = 1
        recognizer.cancelsTouchesInView = true
        recognizer.delegate = context.coordinator
        return recognizer
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        let translation = recognizer.translation(in: recognizer.view).x
        switch recognizer.state {
        case .began:
            context.coordinator.tracking = true
            onBegin(); onChange(translation)
        case .changed: onChange(translation)
        case .ended:
            context.coordinator.tracking = false
            onEnd(translation, recognizer.velocity(in: recognizer.view).x)
        case .cancelled, .failed:
            if context.coordinator.tracking { context.coordinator.tracking = false; onCancel() }
        default: break
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var tracking = false

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
            let velocity = pan.velocity(in: pan.view)
            return abs(velocity.x) > abs(velocity.y) * 1.2
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            // Only the containing scroll view waits for our horizontal/vertical decision.
            otherGestureRecognizer is UIPanGestureRecognizer && otherGestureRecognizer.view is UIScrollView
        }
    }
}
