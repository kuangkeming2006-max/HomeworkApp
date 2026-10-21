# Native iPhone layout

The 0.2.3 revision restores the native navigation structure used in 0.1.0. Building with Xcode 27 lets system tab bars, navigation bars, toolbar buttons and partial-height sheets adopt the current Liquid Glass appearance.

References used:

- [Apple: Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass): use standard components and avoid custom backgrounds that interfere with their materials and scroll-edge behavior.
- [Apple: Tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars): use a stable system navigation layer and audit content safe areas.
- [Apple: Landmarks sample](https://developer.apple.com/documentation/swiftui/landmarks-building-an-app-with-liquid-glass) and [Build a SwiftUI app with the new design](https://developer.apple.com/videos/play/wwdc2025/323/): native toolbar grouping, partial-height sheets and bottom accessories.
- [Apple: Tab view bottom accessory](https://developer.apple.com/documentation/swiftui/view/tabviewbottomaccessory(isenabled:content:)): let the system position temporary status immediately above the tab bar.

## Implementation

- The system TabView owns all four navigation items, its glass, hit targets, selection feedback and safe-area layout. There is no replacement HStack, hidden tab bar or fixed-height overlay.
- Pages switch immediately through native tab containment. The sequential fade-to-blank, toolbar-completion wait and hit-testing lock are removed. Native toolbar buttons and a scoped symbol bounce provide feedback without blocking selection.
- Assignments uses the same native large navigation-title layout as Calendar. The hand-drawn List title row is removed; the system collapses the title during scrolling. Search uses the automatic navigation drawer rather than being forced visible.
- A category tap owns the selected segment until the next deliberate scroll. Intermediate geometry callbacks cannot restore the previously visible category. Colored separators are ordinary native list rows and are the jump targets; they cannot pin over the first assignment's title. Short sections clamp to the available content naturally, without a viewport-sized empty tail.
- Status actions use a real native sheet with one short detent, native prominent vertical buttons and the system sheet background/presentation. An outside-tap recognizer closes the native presentation without replacing its dimming view, safe areas or animation.
- Undo uses the system tab accessory on iOS 26.1 and later, with the iOS 26.0 safe-area fallback retained. Its content has no second glass layer or hard-coded tab-bar-height padding.

## Runtime inspection

The focused preview requests the exact **iPhone 15 Pro** device type on an installed iOS 27 runtime, creating the simulator if necessary. It captures the initial title/tab placement, repeated category returns, pull-to-search, compact heading, all four pages, active/terminal status sheets, Undo and the bottom of the editor.

The capture also retains native tab/item frames, checks that the final row clears the tab bar, and compares Assignments/Calendar title positions. These screenshots establish layout evidence; they do not certify physical-device haptic feel or animation frame rate.
