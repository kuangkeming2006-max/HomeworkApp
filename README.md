# Homework

Native SwiftUI homework deadline manager for iPhone and iPad. Development happens on Windows/Linux; GitHub Actions provides the Apple toolchain. **Currently Phase 1 infrastructure, not a finished task manager.** See [status](docs/STATUS.md).

Based on [hoangnd107/ios-swiftui-app-template](https://github.com/hoangnd107/ios-swiftui-app-template) at `ee99d6508ce6d3a75a12b0c3fff8ac5089edf0f2`. Its XcodeGen, unsigned iPhoneOS build, Payload packaging and tag release design are retained and extended. MIT attribution is preserved in [LICENSE](LICENSE). See [integration decisions](docs/TEMPLATE.md).

## Work from Windows or Arch Linux

1. Clone this repository and open it in VS Code. No Xcode, paid Apple membership or server is needed locally.
2. Edit Swift sources and `project.yml`. The generated `.xcodeproj` stays out of Git.
3. Run `python -m unittest discover -s scripts/tests -v`. With Swift 6 installed, also run `swift test --package-path Packages/HomeworkDomain`.
4. Commit and push. The **Apple build and screenshots** workflow runs portable tests, Apple tests and an unsigned device build.
5. Use `gh run list`, `gh run view RUN_ID --log-failed`, then `gh run download RUN_ID --dir artifacts/RUN_ID`. Inspect logs and real PNGs before claiming success.

The workflow discovers stable Xcode 27 and available iOS 27 simulator UDIDs. Missing SDKs/runtimes cause explicit failures, with available discovery output uploaded. It never silently switches to an older toolchain.

## Outputs

- `domain-linux-*`: raw portable Swift test output.
- `simulator-<family>-<appearance>-<orientation>-*`: raw `xcodebuild.log`, warnings, `.xcresult`, PNG attachments, selected device/SDK metadata and available app crash logs.
- `unsigned-device-*`: arm64 iPhoneOS `.app.zip` and `Payload`-structured unsigned `.ipa`, raw build log and installation notes. Simulator apps cannot be installed on a device.

The six screenshot jobs cover phone portrait and tablet portrait/landscape in both appearances. Builds use synthetic data only. Artifacts expire after 14 days. GitHub private-repository macOS minute quotas still apply; the workflow caps concurrency and timeouts.

## Releases and installation

Push a verified `v*` semantic version tag to build a **draft** GitHub Release, or dispatch the release workflow using that existing tag as the ref and input. It reuses `ios-build.yml`; no duplicated signing/build recipe is maintained. Review the draft and CI before publication.

See [installation](docs/INSTALLATION.md), [architecture](docs/ARCHITECTURE.md), [contributor instructions](AGENTS.md) and [device checks](docs/DEVICE_TESTS.md).
