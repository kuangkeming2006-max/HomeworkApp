# Redesign status — in progress

The v0.1.0 delivery below is preserved. Redesign phases A–E are being implemented without changing `com.kkm.homework`, attachment storage or Keychain identifiers.

- [Installed SDK probe](https://github.com/kuangkeming2006-max/HomeworkApp/actions/runs/39418822424) passed: stable Xcode 27 typechecks the modern ActivityKit `start:` overload, alert configuration and pending state with an iOS 26 deployment minimum.
- Real V1 SQLite migration, disposition undo, search/status domain tests and unsigned device builds have passed. UI runs identified adaptive scrolling/control hit-region issues; fixes preserve the original assertions. No final redesign acceptance is claimed yet.
- [Current calendar and regression validation](https://github.com/kuangkeming2006-max/HomeworkApp/actions/runs/39426889977) is running. Notifications, Live Activities and Briefing are prepared for their subsequent validation stage.

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
