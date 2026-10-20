# Homework

Native SwiftUI homework deadline manager for iPhone and iPad. Development happens on Windows/Linux; GitHub Actions provides Xcode 27 and iOS 27 simulators. The deployment minimum is iOS/iPadOS 26. See [verified delivery status](docs/STATUS.md).

## Features

- Offline SwiftData assignments with active/completed/abandoned states, guarded Undo, category search, automatic editing and priority/deadline sorting. V1 records/backups are preserved through V2 migration.
- Indexed month calendar with distinct status dots, direct month/year selection and creation for the selected day; adaptive tabs, sidebar and list/detail panes.
- Independent reminders, notification actions/deep links, incremental scheduling and a shared pending-request budget.
- Local scheduled Live Activities with compact/minimal/expanded/Lock Screen layouts and an ordinary-notification fallback; no server/APNs requirement.
- Offline Briefing with daily workload/progress, observed history and optional finite scheduled reports.
- Persistent Photos/Files attachments, creation-time staging/cancellation, resized cached thumbnails and Quick Look.
- Optional custom HTTPS Chat Completions provider, Keychain API key, text/image recognition and mandatory editable confirmation. Ambiguous dates cannot be silently saved.
- Versioned local backup/restore including attachments, integrity validation and preservation of existing assignments.

No login, VPS, cloud synchronization or runtime third-party dependency. Only optional AI requests use the network. See the [user guide](docs/USER_GUIDE.md).

Based on [hoangnd107/ios-swiftui-app-template](https://github.com/hoangnd107/ios-swiftui-app-template) at `ee99d6508ce6d3a75a12b0c3fff8ac5089edf0f2`. Its XcodeGen, unsigned iPhoneOS build, Payload packaging and tag release design are retained and extended. MIT attribution is preserved in [LICENSE](LICENSE). See [integration decisions](docs/TEMPLATE.md).

## Work from Windows or Arch Linux

1. Clone this repository and open it in VS Code. No Xcode, paid Apple membership or server is needed locally.
2. Edit Swift sources and `project.yml`. The generated `.xcodeproj` stays out of Git.
3. Run `python -m unittest discover -s scripts/tests -v`. With Swift 6 installed, also run `swift test --package-path Packages/HomeworkDomain`.
4. Commit and push. The **Apple build and screenshots** workflow runs portable tests, Apple tests and an unsigned device build.
5. Use `gh run list`, `gh run view RUN_ID --log-failed`, then `gh run download RUN_ID --dir artifacts/RUN_ID`. Fix actual compiler/test errors and inspect actual screenshots before marking UI acceptance complete.

`python scripts/inspect_ci.py` shows the latest run; add `--run RUN_ID --download` after completion to save run metadata, raw Actions logs, test summary JSON and all artifacts together. It performs no retries or source changes.

The workflow discovers stable Xcode 27 and available iOS 27 simulator UDIDs. Missing SDKs/runtimes cause explicit failures, with available discovery output uploaded. It never silently switches to an older toolchain.

Manual workflow dispatch supports `coverage=focused` (iPhone portrait + iPad landscape) for incremental debugging; pushes and default dispatch run the full six-configuration matrix. `SDK capability probe` records actual ActivityKit declarations and typechecks modern scheduled starts at the iOS 26 minimum.

For a short attachment/accessibility investigation, dispatch with `coverage=focused` and `tests=interfaces`. This runs only the native picker/preview and large-text/scrolling UI classes, and records that scope in device metadata. Debug and complete test scopes have separate concurrency groups so diagnostics can finish independently. It is a debugging aid, not final acceptance: retain `tests=all` for the complete hosted/UI regression and `coverage=full` for release verification.

## Outputs

- `domain-linux-*`: raw portable Swift test output.
- `simulator-<family>-<appearance>-<orientation>-*`: raw `xcodebuild.log`, warnings, `.xcresult`, PNG attachments, selected device/SDK metadata and available app crash logs.
- `review-<family>-<appearance>-<orientation>-*`: compact build/errors/performance logs, test summary, device metadata, screenshot manifest, accessibility trees and PNGs. Failing UI tests explicitly retain a screenshot/tree. App logs/crashes remain in the full artifact; whole-system XCTest diagnostic collection is disabled because it previously stalled for 600 seconds.
- `unsigned-device-*`: arm64 `.app.zip`, full unsigned IPA with its embedded widget, an extension-free unsigned IPA with the same app identity, built-bundle validation and installation notes. Simulator apps cannot be installed on a device.

The six simulator jobs cover phone portrait and tablet portrait/landscape in both appearances. Tests cover persistence, backup/file integrity, reminder reconciliation, AI requests/parsing/confirmation, task workflows, sorting, calendar and settings. CI uses synthetic inputs only and never calls a real LLM. Artifacts expire after 14 days. This repository is public with the owner's approval, so standard hosted-runner execution is free under [GitHub's public-repository policy](https://docs.github.com/en/billing/concepts/product-billing/github-actions). Private forks use their account's included quotas. Concurrency and timeouts are bounded.

## Releases and installation

Push a verified `v*` semantic version tag to build a **draft** GitHub Release, or dispatch the release workflow using that existing tag as the ref and input. It reuses `ios-build.yml`; no duplicated signing/build recipe is maintained. Review the draft and CI before publication.

See [installation](docs/INSTALLATION.md), [architecture](docs/ARCHITECTURE.md), [contributor instructions](AGENTS.md) and [device checks](docs/DEVICE_TESTS.md).
