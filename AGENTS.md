# HomeworkApp contributor rules

## Architecture
- The app is native SwiftUI, iOS/iPadOS 26 minimum, built with stable Xcode 27.
- `Packages/HomeworkDomain` contains Foundation-only values, policies and service protocols. It must compile on Linux and Windows; never import SwiftUI, SwiftData, UIKit or Security there.
- `HomeworkApp/App` is the composition root. Feature views receive dependencies; views must not perform networking, file operations or persistence themselves.
- `HomeworkApp/Features/<Feature>` owns its views, observable presentation models and components. Features depend on domain protocols, not other features' internals.
- `HomeworkApp/Core` owns platform adapters, persistence schema and shared design primitives. `HomeworkApp/Services` implements external boundaries. Avoid cyclic dependencies, service locators and large catch-all types.
- Add platform-specific packages only when a concrete need justifies them. No runtime third-party dependency is currently required.

## Product and safety
- All user-visible strings are English. Use native system navigation, forms, typography, SF Symbols and appearance. Adapt to available width, not device model.
- Ordinary task management remains offline. AI is optional and always requires preview and explicit confirmation before saving.
- Keys live only in Keychain with device-local protection. Never log keys, request bodies, private attachments or personal data. HTTPS and system TLS validation are mandatory.
- Future persistence uses versioned SwiftData schemas, UUIDs, timestamps and tombstones. Never delete stores on a migration or startup error.
- Never use unjustified force unwraps, deprecated APIs or unchecked concurrency workarounds. Use protocols, dependency injection, async/await and explicit isolation.

## Development gates
- The current redesign request requires screenshot review again. Preserve the v0.1.0 baseline and its data; implement and verify redesign phases A–E incrementally.
- Follow `docs/STATUS.md`. Real device compilation, simulator launch and UI navigation have been verified. The user subsequently directed feature development to proceed without waiting on screenshot refinements. Keep screenshot checks in CI, but do not block feature implementation on screenshot-only issues. A configured workflow is not verified CI.
- Commit each phase independently after relevant checks pass. Fix real logs and actual screenshots; never remove tests or weaken assertions to get a pass.
- The canonical project source is `project.yml`. Run `python3 scripts/install_xcodegen.py` and `.tools/bin/xcodegen generate`; do not hand-edit generated projects. Preserve XcodeGen's adjacent `share` settings resources when installing.
- Run `python -m unittest discover -s scripts/tests -v` for CI tooling and `swift test --package-path Packages/HomeworkDomain` for domain changes.
- Apple validation is `.github/workflows/apple.yml`. It inventories Xcode/SDKs/simulators, selects real destinations and retains diagnostics on failure.
- Use synthetic launch fixtures for UI tests. Stable accessibility identifiers belong on major controls. Never call a real LLM in CI.
- Screenshots must cover iPhone portrait, iPad portrait/landscape, Light and Dark Mode. Inspect PNGs from the actual run before claiming visual acceptance.
- Current delivery priority is iPhone. Keep iPad functional and adaptive, but do not block delivery on further iPad visual refinement. Manual `coverage=iphone`, `tests=all` runs the complete iPhone regression in both appearances; retain `coverage=full` for the complete iPad matrix and report each scope accurately.
- Keep an unsigned arm64 iPhoneOS build separate from simulator builds. Unsigned IPA packaging does not mean installable or signed. No paid certificate or backend is required.
- Free-account installation, actual notification delivery, file sharing and re-signing data retention require a physical-device checklist.
- Avoid endless retries. If an environment or permissions block occurs, state the exact missing capability and leave stages unverified.

## Redesign contracts
- Freeze `HomeworkSchemaV1.AssignmentEntity`. V2 migration must be tested using a real V1 disk store, preserving IDs, timestamps, attachments, revisions and tombstones. Decode old version-one backups.
- `AssignmentStatus` owns active/completed/abandoned. Deletion is separate. Terminal-to-terminal transitions require restoration first. Status/timestamp validation is mandatory.
- Undo restores disposition fields only, within five seconds. Guard with an action generation so later legitimate status changes cannot be overwritten, even if fields return to identical values. Revisions always increase.
- Keep row swipes native. The compact category header/empty area owns paging; rows own action gestures. Disable destructive full swipes. Respect Reduce Motion and accessible text sizes.
- Stage new-task attachments without database writes, clean canceled drafts, preserve files after successful creation, and keep original picker URLs out of persistence. Resize/cache thumbnails off the main actor.
- Calendar cells read a prebuilt day index. Share one clock per screen; never create periodic work in every row. Cache ordering separately from search filtering.
- Reconcile deadline and briefing requests incrementally under one total notification budget. Do not cancel and rebuild unchanged requests. Report content is based on last known local data; history stores observed snapshots only.
- `LiveActivityCoordinator` manages at most one activity in a four-hour final window. `start:` scheduling and `.pending` were typechecked on actual Xcode 27 / iOS 26 minimum. Never use deprecated `startDate:` or require APNs. The system controls presentation/delivery.
- Build/embed the widget through `project.yml`; validate built plist/extension/deep-link contracts. Keep an extension-free unsigned fallback with the same app identity. Simulator evidence cannot certify free signing, real notification delivery or Dynamic Island expansion.
