# Homework

Native SwiftUI homework deadline manager for iPhone and iPad. Development happens on Windows/Linux; GitHub Actions provides Xcode 27 and iOS 27 simulators. The deployment minimum is iOS/iPadOS 26. See [verified delivery status](docs/STATUS.md).

## Features

- Offline SwiftData assignments with automatic editing, completion/restoration, deletion, course/notes and priority/deadline sorting.
- Interactive month calendar, day markers and creation for the selected day; adaptive tabs, sidebar and list/detail panes.
- Independent preset/custom reminders, a new-task default, notification permission controls and bounded scheduling.
- Copied persistent Photos/Files attachments, duplicate detection, Quick Look preview and removal.
- Optional custom HTTPS Chat Completions provider, Keychain API key, text/image recognition and mandatory editable confirmation. Ambiguous dates cannot be silently saved.
- Versioned local backup/restore including attachments, integrity validation and preservation of existing assignments.

No login, VPS, cloud synchronization or runtime third-party dependency. Only optional AI requests use the network. See the [user guide](docs/USER_GUIDE.md).

Based on [hoangnd107/ios-swiftui-app-template](https://github.com/hoangnd107/ios-swiftui-app-template) at `ee99d6508ce6d3a75a12b0c3fff8ac5089edf0f2`. Its XcodeGen, unsigned iPhoneOS build, Payload packaging and tag release design are retained and extended. MIT attribution is preserved in [LICENSE](LICENSE). See [integration decisions](docs/TEMPLATE.md).

## Work from Windows or Arch Linux

1. Clone this repository and open it in VS Code. No Xcode, paid Apple membership or server is needed locally.
2. Edit Swift sources and `project.yml`. The generated `.xcodeproj` stays out of Git.
3. Run `python -m unittest discover -s scripts/tests -v`. With Swift 6 installed, also run `swift test --package-path Packages/HomeworkDomain`.
4. Commit and push. The **Apple build and screenshots** workflow runs portable tests, Apple tests and an unsigned device build.
5. Use `gh run list`, `gh run view RUN_ID --log-failed`, then `gh run download RUN_ID --dir artifacts/RUN_ID`. Fix actual compiler/test errors before rerunning. Screenshots are collected automatically; feature work need not wait for cosmetic refinement.

`python scripts/inspect_ci.py` shows the latest run; add `--run RUN_ID --download` after completion to save run metadata, raw Actions logs, test summary JSON and all artifacts together. It performs no retries or source changes.

The workflow discovers stable Xcode 27 and available iOS 27 simulator UDIDs. Missing SDKs/runtimes cause explicit failures, with available discovery output uploaded. It never silently switches to an older toolchain.

## Outputs

- `domain-linux-*`: raw portable Swift test output.
- `simulator-<family>-<appearance>-<orientation>-*`: raw `xcodebuild.log`, warnings, `.xcresult`, PNG attachments, selected device/SDK metadata and available app crash logs.
- `review-<family>-<appearance>-<orientation>-*`: compact build log, test summary, device metadata and PNGs for quick debugging without downloading the full result bundle. App logs and available crash reports are collected separately; XCTest's whole-system diagnostic archive is disabled because it timed out for 600 seconds after otherwise finished failing tests.
- `unsigned-device-*`: arm64 iPhoneOS `.app.zip` and `Payload`-structured unsigned `.ipa`, raw build log and installation notes. Simulator apps cannot be installed on a device.

The six simulator jobs cover phone portrait and tablet portrait/landscape in both appearances. Tests cover persistence, backup/file integrity, reminder reconciliation, AI requests/parsing/confirmation, task workflows, sorting, calendar and settings. CI uses synthetic inputs only and never calls a real LLM. Artifacts expire after 14 days. This repository is public with the owner's approval, so standard hosted-runner execution is free under [GitHub's public-repository policy](https://docs.github.com/en/billing/concepts/product-billing/github-actions). Private forks use their account's included quotas. Concurrency and timeouts are bounded.

## Releases and installation

Push a verified `v*` semantic version tag to build a **draft** GitHub Release, or dispatch the release workflow using that existing tag as the ref and input. It reuses `ios-build.yml`; no duplicated signing/build recipe is maintained. Review the draft and CI before publication.

See [installation](docs/INSTALLATION.md), [architecture](docs/ARCHITECTURE.md), [contributor instructions](AGENTS.md) and [device checks](docs/DEVICE_TESTS.md).
