# Native iPhone interactions — 0.3.0

The app uses the native SwiftUI TabView, NavigationStack, toolbar, Menu/Picker, Form and alert presentations on an iOS/iPadOS 26 deployment minimum. Xcode 27 and the discovered iOS 27 runtime provide the system's current Liquid Glass design. No third-party UI dependency is added.

## Native controls and motion

- Sort restores the anchored Menu containing a Picker from v0.1.0. Category uses the same native selection mechanism, ordered All, Upcoming, Completed, Abandoned, Deleted. Its borderless accented label sits to the right of Assignments in a large-type List heading row; the compact pair uses the system's leading toolbar position without a shared background. There is no gray category rail. Workspace toolbar actions use adaptive primary foreground.
- The large heading is actual scroll content and naturally leaves with the list. AssignmentHeadingLayout compares its measured bottom with the viewport's visible safe-area edge; only a compact Boolean changes. The native navigation bar keeps a fixed inline mode and receives ordinary leading title text after the large heading has left. NavigationTitle retains the semantic Back label. There are no title controller bridges, cumulative scroll estimates, bar-height mutations, timers or category changes driven by scrolling. A small geometric hysteresis avoids flicker at the edge, and pull-to-search returns the real heading to view.
- The heading section sets vertical listSectionMargins to zero and explicit edge-specific listRowInsets for its title and search rows. The outer Menu retains a 44-point target. Actual accessibility geometry distinguished row padding from menu size; no negative offsets are used. Search uses a standard minimal UISearchBar below the heading, revealed by pulling the heading beyond its resting edge. A noninteractive zero-size view reads the existing UIScrollView's dragging/decelerating state through public parent views; it adds no recognizer. Filtering or layout alone cannot reveal search. The native text field drives the cached query, and a named accessibility action on the ordinary heading offers Search without a drag. The visible edge avoids double-counted navigation height. Compact text uses intrinsic width and normal navigation-bar type sizing.
- All has three colored status headings in a flat, stable-ID List. Other categories truly filter the cached ordering and omit headings. There is no segmented control, scroll-to synchronization or horizontal category gesture.
- A circle immediately toggles completion/restoration. The symbol replaces natively, a finite 0.45-second keyframe burst surrounds a completed circle, and the store supplies the existing success haptic. Upcoming retains a completed row for at most five seconds; a single cancellable presentation task expires rows, and leaving the tab clears them. Undo/restoration invalidates pending visibility. All moves the same UUID between status headings immediately.
- Native toolbar item identifiers, a fresh activation generation on every tab change, scoped scale/opacity springs and symbol bounce keep repeated transitions responsive. Pages never wait for animation completion. The shared Add item has the same toolbar ID on both workspaces.
- Detail and Settings destinations hide the tab bar at destination scope. Theme selection uses matched native zoom. Both new and existing editors use native push/pop so Back and its interactive gestures share the same draft protection; creation has no separate sheet-dismiss path. Clean navigation keeps the system's interactive back gesture. Dirty editors intercept the public navigation-item Back action and both public pop gestures to show a centered native Save / Discard Changes / Keep Editing alert.
- Calendar pages use absolute month IDs and absolute day IDs. The selected background belongs only to the current page and exact date; its geometry is not implicitly animated between reused cells. Month translation remains animated. Commits happen immediately, and generation-guarded completion callbacks cannot overwrite newer interactions.
- A public UIGestureRecognizerRepresentable wraps a horizontal-only native pan. It rejects vertical motion before recognition so the surrounding ScrollView can scroll; real date Buttons retain native tap cancellation when a pan wins. A horizontal manual gesture hides retained day details with blur/opacity; a cancellable 200 ms reveal follows settling. Arrows, Today, month selection and day taps cancel pending reveals immediately and overlap old/new details through the native blur-replace transition.
- A fullscreen image uses one drag gesture: at 1x it can dismiss downward; above 1x it pans with image-fit bounds and spring edge correction. Pinch and double tap change scale, Close remains independent, and sharing uses the original file.
- Reduce Motion removes app-controlled particles/bounce/spring translations and substitutes short opacity transitions. Native navigation remains under the system's accessibility policy. The app reads the system accessibility value; DEBUG synthetic captures can additionally request reduced app motion through its own environment key.

## Draft and deletion integrity

Deleted is a query dimension over deletedAt, not a new AssignmentStatus. Restoration clears only the deletion timestamp, preserves disposition/content/attachments, increments revision and remains undoable. Attachment pruning retains paths from every persisted record, including tombstones.

New and existing editors both stage field and attachment changes locally. Save validates the complete result and commits once. A three-way merge preserves independently changed fields and external attachment additions; conflicting changes fail visibly with the draft retained. Discard removes only newly imported files. Previously attached files are removed only after a successful commit and only when no persisted record references them.

Frozen SchemaV1, migration, backup decoding, IDs, reminder reconciliation, AI confirmation and widget identity are unchanged.

## Public Apple references

- [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass)
- [Landmarks sample](https://developer.apple.com/documentation/swiftui/landmarks-building-an-app-with-liquid-glass)
- [Build a SwiftUI app with the new design](https://developer.apple.com/videos/play/wwdc2025/323/)
- [Native tab accessory](https://developer.apple.com/documentation/swiftui/view/tabviewbottomaccessory(isenabled:content:))
- [Navigation item Back action](https://developer.apple.com/documentation/uikit/uinavigationitem/backaction)
- [Interactive edge pop](https://developer.apple.com/documentation/uikit/uinavigationcontroller/interactivepopgesturerecognizer)
- [Interactive content pop](https://developer.apple.com/documentation/uikit/uinavigationcontroller/interactivecontentpopgesturerecognizer)
- [Blur-replace transition](https://developer.apple.com/documentation/swiftui/blurreplacetransition)
- [Type-erased native transition](https://developer.apple.com/documentation/swiftui/anytransition/init(_:))
- [UIKit gesture recognizers in SwiftUI](https://developer.apple.com/documentation/swiftui/uigesturerecognizerrepresentable)
- [Native gesture priority](https://developer.apple.com/documentation/uikit/preferring-one-gesture-over-another)
- [Native section margins](https://developer.apple.com/documentation/swiftui/view/listsectionmargins%28_%3A_%3A%29)
- [Native row edge insets](https://developer.apple.com/documentation/swiftui/view/listrowinsets%28_%3A_%3A%29)
- [iOS 26 release notes — vertical row inset behavior](https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-26-release-notes)

Runtime acceptance and any failures are recorded in STATUS.md. Screenshots establish layout and state evidence, not physical-device haptic feel or frame-rate guarantees.
