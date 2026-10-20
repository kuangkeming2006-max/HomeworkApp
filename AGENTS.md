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
- Follow `docs/STATUS.md`. Phase 1 must have a real successful device build, simulator launch, tests and screenshots before Phase 2. A configured workflow is not verified CI.
- Commit each phase independently after relevant checks pass. Fix real logs and actual screenshots; never remove tests or weaken assertions to get a pass.
- The canonical project source is `project.yml`. Run `python3 scripts/install_xcodegen.py` and `.tools/xcodegen generate`; do not hand-edit generated projects.
- Run `python -m unittest discover -s scripts/tests -v` for CI tooling and `swift test --package-path Packages/HomeworkDomain` for domain changes.
- Apple validation is `.github/workflows/apple.yml`. It inventories Xcode/SDKs/simulators, selects real destinations and retains diagnostics on failure.
- Use synthetic launch fixtures for UI tests. Stable accessibility identifiers belong on major controls. Never call a real LLM in CI.
- Screenshots must cover iPhone portrait, iPad portrait/landscape, Light and Dark Mode. Inspect PNGs from the actual run before claiming visual acceptance.
- Keep an unsigned arm64 iPhoneOS build separate from simulator builds. Unsigned IPA packaging does not mean installable or signed. No paid certificate or backend is required.
- Free-account installation, actual notification delivery, file sharing and re-signing data retention require a physical-device checklist.
- Avoid endless retries. If an environment or permissions block occurs, state the exact missing capability and leave stages unverified.
