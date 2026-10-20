# Delivery status

## Phase 1 — infrastructure

Implemented locally: template integration, modular minimal app, adaptive navigation, domain package, XcodeGen specification, Linux/domain tests, hosted Apple integration/UI tests, six screenshot configurations, unsigned device packaging and draft release workflow.

Verification in progress: nine Windows/Linux build-tool tests and the portable Swift test pass. The real Xcode 27/iOS 27 arm64 device build succeeds, with iOS 26 deployment and both device families confirmed from the built Info.plist. Run `39380747774` passed hosted integration and UI navigation tests in all six configurations. The four portrait jobs also passed PNG validation; their actual screenshots were reviewed. The two landscape jobs correctly failed the independent pixel-orientation check: scheme environment macros had no expansion target. This is being fixed in `project.yml`, with an explicit test assertion rejecting unresolved parameters. Phase 1 remains incomplete until real landscape PNGs pass inspection. Physical-device installation is unverified.

## Required next gates

1. Finish remaining screenshot automation checks in CI. Device compilation, simulator launch, hosted tests and navigation are verified. The user has explicitly prioritized feature implementation over further screenshot refinement, so Phase 2 proceeds now.
2. Phase 2: versioned SwiftData, domain models, CRUD, filters/sorting, interactive calendar, sync interface.
3. Phase 3: independent reminder policy/scheduling, attachment storage and preview.
4. Phase 4: Keychain, custom HTTPS provider, strict text/image parsing and confirmation.
5. Phase 5: backup/restore, accessibility, responsive layout review and complete regression/device checklists.

Each phase requires its own Git commit and relevant passing checks. The placeholder screens in Phase 1 do not satisfy the full app acceptance criteria.

## Phase 2 — verified

Implemented: complete domain assignment values and service boundaries; versioned SwiftData schema and migration plan; transactional validated batch saves; create/edit with debounced auto-save; completion, restoration and tombstone deletion; Upcoming/Completed/All filters; priority/deadline sorting; interactive month grid with task markers, day selection and date-based creation; adaptive list/detail panes at available widths. Repository, editor, DST, filtering, sorting and month-grid tests pass. Real CI run `39384598013` is fully successful for commit `bbcc08b`, including Linux, unsigned arm64 device build and all six iPhone/iPad configurations.

## Phase 3 — implementation submitted for CI

Independent per-task reminders, preset/custom lead amounts, new-task defaults, explicit notification permission controls, serialized bounded scheduling (60 slots, preserving unrelated requests), completion/deletion cancellation and foreground/time-change reconciliation are implemented. Past reminder times are skipped and deferred reminders are exposed in Settings. Attachments use persistent copied files, security-scoped imports, size limits, SHA-256 duplicate detection per task, PhotosPicker, Files import, Quick Look preview, explicit removal and delayed orphan cleanup. Notification and file lifecycle integration tests have been added. Physical notification delivery remains a device check.
