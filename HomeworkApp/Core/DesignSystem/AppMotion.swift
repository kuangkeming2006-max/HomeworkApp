import SwiftUI

private struct AppReduceMotionKey: EnvironmentKey { static let defaultValue = false }

extension EnvironmentValues {
    /// The system value remains authoritative; a synthetic preview can also reduce app motion.
    var appReduceMotion: Bool {
        get { accessibilityReduceMotion || self[AppReduceMotionKey.self] }
        set { self[AppReduceMotionKey.self] = newValue }
    }
}
