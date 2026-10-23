# Module boundaries

`App → Features → HomeworkDomain`; `App → platform Services → HomeworkDomain`. Features do not know concrete storage, networking or file adapters. AppContainer constructs dependencies and owns app-wide lifetimes. Pure policy does not depend on UI or platform frameworks.

| Location | Responsibility | Stage |
| --- | --- | --- |
| `App` | App lifecycle, adaptive navigation, dependency composition | 1 |
| `Packages/HomeworkDomain` | Sendable value types, sorting, validation, calendar/reminder/AI policies, repository and service protocols | 1–4 |
| `Core/Persistence` | Versioned SwiftData models, migration plan, domain mapping | 2 |
| `Core/State` | Shared observable assignment state used by multiple features | 2 |
| `Features/Assignments` | List/detail presentation, editing and filtering | 2 |
| `Features/Calendar` | Interactive month grid and selection | 2 |
| `Services/AssignmentRepository` | SwiftData repository implementing the domain boundary | 2 |
| `Features/Reminders`, `Services/NotificationService` | Per-task settings and bounded scheduling reconciliation | 3 |
| `Features/Attachments`, `Services/AttachmentService` | Import, persistent relative references, previews and cleanup | 3 |
| `Features/AIImport`, domain `ChatCompletionsProvider`, `Core/Networking` | Optional text/image parsing, strict validation, mandatory confirmation and URLSession transport | 4 |
| `Services/KeychainService` | Device-local API secret storage | 4 |
| `Features/Settings` | Defaults, provider configuration and backups | 1–5 |
| Domain `SyncService` | Replaceable no-op boundary, no server or account | 2 |
| `Services/BackupService` | Validated versioned documents, checksum verification, staged file copies and atomic batch restore | 5 |
| `Core/State/UndoCoordinator`, domain status/search/classification | Five-second disposition undo, action generations and shared query/display rules | Redesign A–C |
| `Features/Briefing`, domain `BriefingService` | Separate completion metrics, finite report projections and observed daily snapshots | Redesign D |
| `Services/LiveActivityService`, `Shared`, `HomeworkWidgets` | Value-only activity contract, reconciliation and embedded WidgetKit extension | Redesign D |

Domain protocols replace persistence, attachments, backups, notifications, HTTP transport and providers independently. SwiftData uses a versioned schema and never deletes stores on errors. Editors keep local drafts until explicit Save. Foundation-only AssignmentDraftMerge performs a three-way merge against the latest record: unrelated changes survive; conflicting edits fail with the local draft retained.

The deployment target remains iOS/iPadOS 26, built with Xcode 27. Native Liquid Glass controls provide the iOS 27 appearance; navigation, lists and forms use the saved appearance preference (system by default). Any iOS 27-only API must have an availability guard and a viable iOS 26 path.

Compact-width navigation uses native TabView containment, safe areas and Liquid Glass. Stable native toolbar item IDs and a generation on every tab switch drive scoped spring/symbol feedback without delaying pages. Detail/settings destinations scope tab-bar hiding locally. New and existing drafts use the same native navigation destination. EditorDismissalGuard uses public UINavigationItem.backAction and interactive pop gestures only for dirty editors; clean navigation restores original native behavior. Undo retains the native tab accessory and iOS 26 fallback. Regular-width sidebar compatibility remains.

Each sidebar destination has its own stable navigation identity. The task workspace uses Apple's [type-erased NavigationPath](https://developer.apple.com/documentation/swiftui/navigationpath) so split-column transitions can reconcile navigation data of different types. A UUID-only array must not be shared with the sidebar's destination path. Switching away from a pushed assignment is covered by the large-text UI regression.

Accessibility text sizes use the wider stack instead of a narrow third column. Deadline metadata can move onto separate lines without splitting each word into a vertical column. Calendar dates retain a seven-column grid, with single-line scaling limited to date numbers and weekday abbreviations; full date/status descriptions remain available to VoiceOver.

Backup format version 1 is a JSON document with `formatVersion`, `exportedAt`, `assignments` and `files`. Dates use Swift Codable's seconds since 2001-01-01 UTC; file contents are base64 and linked by attachment UUID, with length and SHA-256 checked. The file is bounded to 100 MB. Import validates everything before staging unique attachment copies, then saves missing task UUIDs in a single repository transaction. A failed transaction removes only its newly staged files. Reimport preserves existing tasks and tombstones; backup does not serve as a synchronization merge engine. Provider settings and secrets are excluded.

## Redesign data and service boundaries

The original `HomeworkSchemaV1.AssignmentEntity` stays frozen. V2 adds optional status/abandonment columns, then backfills status from the original completion flag in a custom migration. A hosted test creates a real V1 SQLite store and reopens it through the migration plan. Status is authoritative in domain values; the persisted legacy completion flag and encoded backup Boolean remain consistent compatibility mirrors. The store name, attachment directory, bundle ID, preference keys and Keychain identity are preserved.

Undo records disposition only, guarded by action-generation tokens and increasing revisions. The cached list projection exposes five real filters; All is a flat list of stable assignment UUIDs with three colored heading IDs. Deleted queries deletedAt separately from AssignmentStatus and restores only the deletion dimension. A single cancellable presentation task retains Upcoming completions for five seconds, clears on tab exit and cancels on restoration. All moves UUIDs immediately. No status sheet or geometry-driven category synchronization remains.

Calendar cells read a prebuilt day index and a shared minute clock. The cached month strip identifies pages by absolute month and cells by absolute date, with selected backgrounds restricted to the current page. Month commits are immediate and completion callbacks generation-guarded. A public UIGestureRecognizerRepresentable accepts horizontal pans only, leaving vertical motion to the page ScrollView; native date Buttons cancel taps when a pan wins. Manual swiping hides retained details and schedules a cancellable 200 ms reveal; button/day changes cancel it and overlap native blur-replace transitions.

Both new and existing attachment edits belong to a draft session until Save. Cancellation/deinitialization removes only session-owned imports. Successful saves remove obsolete files only if no persisted record, including a tombstone, retains their path. File copying/hashing and bounded thumbnail decoding remain off the main actor. Photos/Files share one compact row; removal requires confirmation. Fullscreen images use one scale-aware drag for bounded panning or 1x downward dismissal, plus pinch/double tap and native sharing. Documents use Quick Look. Presentation remains at stable screen roots.

Theme preferences use UserDefaults separately from notification preferences, so appearance changes do not reschedule reminders. The dedicated color list renders actual filled swatches. Purple uses the original 0.2.0 lavender (RGB 0.55/0.45/0.96) by default; chosen accents replace the original themed controls without extending to new backgrounds or semantic actions. Category markers and status actions retain fixed colors; destructive actions remain red.

`NotificationCoordinator` incrementally reconciles individual reminders and up to seven finite reports under one total budget of 60 pending requests. Notification actions finish persistence, activity reconciliation and reminder cancellation before returning the system completion callback. Report content uses last known data, and history stores only observed snapshots with their local time zone.

`LiveActivityCoordinator` reconciles at most one final-window countdown through a replaceable client. `ActivityKitClient` uses the installed-SDK-verified `start:` request and handles `.pending`; opaque SDK handles stay inside their async operations. The extension receives Sendable value content and uses native timer views. It never reads the task database and needs no App Group, APNs or backend. Bundle validation checks extension embedding, version alignment and deep links. The extension-free package disables Live Activities while retaining the same app identity and ordinary reminders. Signing, delivery and system-controlled presentation still require the physical checklist.
