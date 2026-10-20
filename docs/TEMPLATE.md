# Template integration record

Inspected upstream `ee99d6508ce6d3a75a12b0c3fff8ac5089edf0f2` before integration: both Swift source files, unit tests, `project.yml`, all three workflows, README, license and assets. The existing local infrastructure draft was inspected and retained; it was not overwritten with a second starter app.

Retained from the template:
- XcodeGen YAML as canonical project definition, generated project excluded from Git.
- Application and hosted XCTest target/scheme layout, generated Info.plist, resource catalogs and launch screen generation.
- Disabled signing (`CODE_SIGNING_ALLOWED`, `CODE_SIGNING_REQUIRED`, empty identity), generic iPhoneOS Release build and `Payload/<App>.app` ZIP format.
- App/scheme name derived from `project.yml` by the build driver.
- Separate tag-driven release workflow using the unsigned build; MIT license and supplied placeholder app icon/accent catalog.
- Windows-friendly LF source line endings.

Adapted deliberately:
- Swift 5 / iOS 17 → Swift 6 strict concurrency / iOS 26 deployment, Xcode 27 SDK.
- iPhone-only portrait → both families and supported portrait/landscape orientations.
- `macos-latest` + third-party selector → official `xcode-27` label and inspected, latest installed stable Xcode 27. Beta/RC paths are excluded, including symlinks to them.
- Unpinned Homebrew generator → official XcodeGen 2.46.0 ZIP with SHA-256 verified against release metadata.
- Arbitrary first iPhone name and guessed fallback → available simulator inventory, runtime and family validation, UDID destination.
- Separate duplicated release build → reusable `ios-build.yml` for CI and release.
- Unrestricted tag interpolation → validated semantic version/ref and subprocess argument arrays. Releases start as drafts for review.
- Toy arithmetic tests → domain serialization contract, actual composition, navigation, screenshot and build-tool policy tests.
- Missing failure artifacts → unconditional upload of existing logs, `.xcresult`, screenshots, SDK and destination metadata, warnings and available app crashes.
- Single starter screen → feature folders and Foundation-only local Swift Package; no third-party runtime dependencies.

The template's claim that an unsigned IPA is directly installable has been clarified: it requires signing by a sideloading tool and real-device verification. Hosted runner availability and free minute quotas are separate from Apple developer membership.
