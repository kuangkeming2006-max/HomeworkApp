# Redesign status — iPhone delivery

The v0.1.0 delivery below is preserved. Redesign phases A–E are implemented without changing `com.kkm.homework`, attachment storage, existing preferences or Keychain identifiers. Version 0.2.0/build 2 is available as a draft release with full and extension-free unsigned IPAs. iPhone verification uses the complete runs and test-only correction recorded below; no physical signing or delivery certification is claimed. The user's latest direction prioritizes iPhone delivery; further iPad visual refinement does not block this release.

| Phase | Implemented change |
| --- | --- |
| A | Explicit active/completed/abandoned status, frozen V1 → V2 disk migration, legacy backups, guarded disposition Undo, category search and native row actions. |
| B | Centered completion controls, countdown Undo, bounded list text, staged creation attachments, separate native pickers, resized thumbnail cache and stable editor-root Quick Look. |
| C | Indexed month navigation, direct month/year selection, preserved/clamped days, shared classification and one distinct dot per state/day. |
| D | Permission explanation, incremental individual/summary notifications, persisted Complete/deep links, verified local scheduled ActivityKit starts, embedded WidgetKit extension and offline Briefing/history. |
| E | Monochrome Light/Dark/Tinted icons, adaptive large text/navigation, measured calendar/store improvements, expanded native-interface/600-task tests, full and extension-free unsigned packages. |

- [Installed SDK probe](https://github.com/kuangkeming2006-max/HomeworkApp/actions/runs/39418822424) passed: stable Xcode 27 typechecks the modern ActivityKit `start:` overload, alert configuration and pending state with an iOS 26 deployment minimum.
- Real V1 SQLite migration, disposition undo, search/status domain tests and unsigned device builds have passed. UI runs identified adaptive scrolling/control hit-region issues; fixes preserve the original assertions. Physical signing, delivery and interaction checks remain separate.
- [Notification/Briefing regression](https://github.com/kuangkeming2006-max/HomeworkApp/actions/runs/39431025880) passed all 45 hosted/UI tests on both iPhone portrait and iPad landscape, plus Linux logic and the app/widget device build. Its iPad job remained red because cropped application screenshots carried inconsistent rotation metadata; phase E switches capture to system screenshots and keeps the orientation assertion.
- [Focused native-interface verification](https://github.com/kuangkeming2006-max/HomeworkApp/actions/runs/39469456934) passed all six jobs: four UI cases each on iPhone portrait and iPad landscape, Linux 22 tests, tooling 14 tests and the unsigned app/widget build. Actual PNGs confirm PDF rendering, large-text statistics/calendar and the repaired iPad navigation transition. This limited test scope is not the full regression.
- [Full-matrix regression attempt](https://github.com/kuangkeming2006-max/HomeworkApp/actions/runs/39475047121) tests commit `4954c8a`, with all 49 hosted/UI cases and six appearance/orientation configurations. This commit strengthens photo-picker cancellation to distinguish its native Cancel from the editor's underlying Cancel; application code is unchanged from the green focused run. iPhone Dark and iPad Light portrait passed all 49 cases; the latter's summary exporter timed out, so its result is verified against the raw successful XCTest log and retained `.xcresult`. iPhone Light passed 48/49: the first AI flow exceeded the 180-second overall allowance after an unusually slow initial simulator launch, while reaching the final save assertion. iPad Light landscape also passed 48/49, with a first-app launch timeout before AI interaction. The remaining iPad Dark jobs were canceled after the user's direction to prioritize iPhone. This attempt is not a green full-matrix result.
- [Complete iPhone regression](https://github.com/kuangkeming2006-max/HomeworkApp/actions/runs/39480607066) is the single bounded fresh-runner retry, covering all 49 cases in both appearances. Commit `869926c` adds manual `coverage=iphone` and independent coverage concurrency; application/test source and timeouts are unchanged from `4954c8a`. **Light passed 49/49**. Dark passed 48/49: its AI flow's five-second predicate wait expired while a single accessibility query took over four seconds; the retained screenshot/tree shows the second candidate deselected and Save selected available. The overall workflow is red, not a complete green run. The original full-matrix option remains available.
- [AI confirmation test verification](https://github.com/kuangkeming2006-max/HomeworkApp/actions/runs/39483702439) checks test-only commit `2e56dee` in both iPhone appearances. It scopes the Save query to the observed navigation bar, stops redundant visibility queries after finding the switch, uses the native element-state wait with a 15-second bound, and captures input/confirmation/saved-result screenshots. All mandatory-confirmation, deselection and saved-content assertions and the overall 180-second case allowance are retained. The other 48 cases were not changed; production source is identical to the release tag. **The corrected AI case passed in both appearances.** Light's first attempt ran zero cases because the XCTest runner crashed while bootstrapping, before executing app assertions; one fresh-runner retry passed with identical source in 36.24 seconds. This targeted scope is one case per appearance, not another full 49-case run.
- [v0.2.0 release workflow](https://github.com/kuangkeming2006-max/HomeworkApp/actions/runs/39480792441) passed and created a draft release from tag `v0.2.0` / commit `869926c13c110c408cdaca2b10e477e3df22d3c0`. Both downloaded unsigned IPAs match GitHub's SHA-256 asset digests. Their arm64 binaries, 0.2.0/build 2 metadata, stable app identifier, extension variant and absence of provisioning/signatures were checked locally. The release remains a draft pending physical-device checks.

The 49-case Light and Dark passes are separate invocations with identical application source. Together with the corrected AI test, they provide the iPhone delivery evidence; no single all-green six-configuration redesign run is claimed. Portable domain tests (22) and build-tool tests (14) also passed. Raw logs, per-scope summaries, screenshots and failed-attempt diagnostics are retained alongside the local build handoff as well as in Actions artifacts.

## Verification limits

The retained simulator benchmark for 2,000 assignments over 42 calendar days measured 0.0934 seconds for repeated full scans and 0.0151 seconds for index construction plus lookups (about 6.2× faster in this synthetic run). One hundred mutations of a 1,000-task store used one initial full fetch and incremental merges, taking 0.315 seconds. Six automated scroll gestures over 600 tasks took 18.63 seconds including XCTest synchronization; that duration is not an animation frame-rate measurement.

Actual SDK probing and compilation cover the iOS 26 deployment minimum; simulator execution uses iOS 27. Simulator operation timings and automated scrolling are not a certification of 60/120 Hz interaction. Native shared Live Activity layout screenshots exercise the same content views as the extension, but do not prove system-controlled Dynamic Island expansion or background delivery. SideStore/free-account extension signing, installed-data retention, third-party file providers, notification delivery and Stage Manager/VoiceOver behavior remain on the [physical checklist](DEVICE_TESTS.md).

## Previous delivery — v0.1.0

Application source/tag: `97691288b0f91caaa6d655e626a920ceb92b6da2` / `v0.1.0`.

[Final Apple CI run](https://github.com/kuangkeming2006-max/HomeworkApp/actions/runs/39391550713) completed successfully on 2026-10-20, attempt 2. All nine jobs passed. [The actual release workflow](https://github.com/kuangkeming2006-max/HomeworkApp/actions/runs/39393572075) also passed and created a draft release containing the unsigned IPA.

## Implemented stages

| Stage | Delivered functionality |
| --- | --- |
| 1 — Infrastructure | Inspected/pinned upstream template; retained MIT attribution, XcodeGen and unsigned packaging/release design; canonical project.yml; real SDK/simulator discovery; diagnostics and screenshot artifacts. |
| 2 — Core | Foundation-only domain package; versioned SwiftData; transactional CRUD; debounced field-patch editing; completion/restoration/tombstones; priority/deadline sorting; interactive calendar; adaptive tabs/sidebar/list-detail panes; replaceable sync boundary. |
| 3 — Reminders/attachments | Independent presets/custom lead times and defaults; explicit permission handling; bounded earliest-first scheduling; cancellation/reconciliation; security-scoped copied files; duplicate detection, Quick Look, removal and delayed orphan cleanup. |
| 4 — AI | Device-local Keychain key; custom HTTPS endpoint/model; text/image requests; bounded downsampled images; strict JSON/schema/date validation; editable multiple candidates and explicit confirmation; optional JSON/vision settings and connection feedback. |
| 5 — Refinement/backup | Versioned self-contained backups with attachment hashes; import preview; preservation of existing UUIDs/tombstones; staged copies and transactional restore/cleanup; expanded regression tests; English documentation and free-account installation instructions. |

Every stage has its own Git commit. Ordinary task management stays offline; no account, backend or paid Apple membership is required by the app.

## Actual verification

- 13 build-tool tests passed on Windows and CI.
- 15 portable Swift tests passed on Linux, covering sorting/filtering, validation, calendar/DST, reminders, AI request/parsing and backup structure.
- Each of six simulator configurations passed 19 hosted integration/UI tests: iPhone portrait and iPad portrait/landscape, Light/Dark. Main-page navigation/screenshot capture explicitly sets the requested orientation. Full Stage Manager resizing, VoiceOver and Dynamic Type review remain device checks.
- Hosted tests cover disk persistence, merging editor changes, auto-save, file lifecycle/traversal, notification reconciliation, AI confirmation, secret/config separation, backup restore, corrupt imports, duplicate import and failed-save cleanup.
- UI tests cover creation, editing, completion/restoration, deletion, sorting, calendar navigation, reminder/attachment controls, AI preview/selection/save and settings.
- Stable Xcode 27.0 (`27A266a`), iOS 27.0 SDK and arm64 iPhoneOS build succeeded with no build warnings. Built Info.plist confirms deployment minimum 26.0, both device families and multiple-scene support. iOS 26 runtime execution was not performed.
- PNGs, device metadata, raw logs, test summaries, .xcresult and available crash diagnostics are in Actions artifacts. Screenshot-only refinement was deprioritized at the user's request; this is not a pixel-perfect visual certification.

Attempt 1 had one failure in the final explicit simulator-app termination call after the task-edit flow. No app crash report was available; other configurations passed. A single rerun of that failed job on a clean runner passed all 19 tests with identical source and assertions. Track this simulator termination flake if it recurs. There were no automatic unbounded retries.

## Installation and remaining physical checks

Use the unsigned IPA from the matching Actions artifact or the v0.1.0 draft release, then follow [installation](INSTALLATION.md). Unsigned packaging is verified; free-account signing/refresh, actual notification delivery, third-party file-provider sharing, real provider recognition and window/accessibility behavior still require [physical checks](DEVICE_TESTS.md). CI uses only synthetic data and no real API key or private attachments.

The repository was made public with the user's explicit approval after GitHub blocked private-repository jobs for account payment/spending limits. Standard public Actions execution then resumed. Sources, build scripts and diagnostics remain reviewable from Windows/Linux.
