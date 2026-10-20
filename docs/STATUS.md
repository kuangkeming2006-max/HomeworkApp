# Delivery status

## Phase 1 — infrastructure

Implemented locally: template integration, modular minimal app, adaptive navigation, domain package, XcodeGen specification, Linux/domain tests, hosted Apple integration/UI tests, six screenshot configurations, unsigned device packaging and draft release workflow.

Verified: real Xcode 27/iOS 27 arm64 device compilation, simulator launch, hosted tests, six appearance/orientation configurations, diagnostics and unsigned IPA packaging. Run `39384598013` passed every job. Screenshot-only refinements no longer gate feature work, per the user's instruction. Physical-device installation is unverified.

## Required next gates

1. Preserve passing infrastructure while implementing functionality. Keep automatic screenshot collection without blocking feature work on visual refinements.
2. Phase 2: versioned SwiftData, domain models, CRUD, filters/sorting, interactive calendar, sync interface.
3. Phase 3: independent reminder policy/scheduling, attachment storage and preview.
4. Phase 4: Keychain, custom HTTPS provider, strict text/image parsing and confirmation.
5. Phase 5: backup/restore, accessibility, responsive layout review and complete regression/device checklists.

Each phase has its own Git commit and relevant checks. Current functionality replaces the initial placeholder screens.

## Phase 2 — verified

Implemented: complete domain assignment values and service boundaries; versioned SwiftData schema and migration plan; transactional validated batch saves; create/edit with debounced auto-save; completion, restoration and tombstone deletion; Upcoming/Completed/All filters; priority/deadline sorting; interactive month grid with task markers, day selection and date-based creation; adaptive list/detail panes at available widths. Repository, editor, DST, filtering, sorting and month-grid tests pass. Real CI run `39384598013` is fully successful for commit `bbcc08b`, including Linux, unsigned arm64 device build and all six iPhone/iPad configurations.

## Phase 3 — verified

Independent per-task reminders, preset/custom lead amounts, new-task defaults, explicit notification permission controls, serialized bounded scheduling (60 slots, preserving unrelated requests), completion/deletion cancellation and foreground/time-change reconciliation are implemented. Past reminder times are skipped and deferred reminders are exposed in Settings. Attachments use persistent copied files, security-scoped imports, size limits, SHA-256 duplicate detection per task, PhotosPicker, Files import, Quick Look preview, explicit removal and delayed orphan cleanup. Notification and file lifecycle integration tests have been added. Physical notification delivery remains a device check.

Real CI run `39386661203` passed all nine jobs for commit `424d652`, including all six simulator configurations and unsigned iPhoneOS packaging.

## Phase 4 — implementation submitted for CI

Device-local Keychain storage, custom HTTPS Chat Completions endpoint/model configuration, optional image/JSON capability settings and a connection test are implemented. Text and bounded JPEG image inputs produce strictly validated candidates. Current date/time zone are supplied explicitly; missing/past dates and contradictory offsets require confirmation. The preview supports editing and selecting multiple assignments, and nothing is persisted before explicit confirmation. Requests use ephemeral URLSession, system TLS, timeouts, size bounds and no redirects. CI uses a deterministic mock provider through the real parser; no external LLM or private credentials are used. Tooling tests pass locally; Apple and Linux validation are pending.

## Phase 5 — implementation submitted for CI

Versioned 100 MB JSON backups include task records and attachments, validate all metadata/lengths/SHA-256 checksums before import, preview missing/duplicate UUID counts, preserve existing tasks and tombstones, stage unique file copies and restore in one repository transaction. Failures clean only newly staged copies. Domain and integration tests cover corrupted backups, full restore, duplicate import and failed-save cleanup. AI photos use ImageIO downsampling. Additional UI tests cover priority/deadline order, deletion, reminders, attachment controls and provider/backup settings. English user, maintenance and free-account installation documentation is included. Full final regression is pending; physical-device signing, actual delivery, external file-provider sharing, accessibility and resized windows remain device checks.
