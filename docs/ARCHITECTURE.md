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

Domain protocols permit replacing persistence, attachments, backups, notifications, HTTP transport, providers and future sync independently. SwiftData uses an explicit versioned schema; an error never authorizes deleting user stores. Editor changes are field patches against the latest stored record so editing in another window does not overwrite unrelated fields.

The deployment target is iOS/iPadOS 26. System SwiftUI navigation, lists and forms inherit the current system appearance when built with the Xcode 27 SDK. Any later iOS 27-only API must have an availability guard and a viable iOS 26 path. No blur-overlay imitation of Liquid Glass is used.

Compact-width navigation uses tabs; regular-width navigation uses a sidebar. Task list/detail columns appear when the remaining available width is at least 720 points. Width and horizontal size class determine composition, allowing resized iPad windows to fall back to a navigation stack.

Each sidebar destination has its own stable navigation identity. The task workspace uses Apple's [type-erased NavigationPath](https://developer.apple.com/documentation/swiftui/navigationpath) so split-column transitions can reconcile navigation data of different types. A UUID-only array must not be shared with the sidebar's destination path. Switching away from a pushed assignment is covered by the large-text UI regression.

Accessibility text sizes use the wider stack instead of a narrow third column. Deadline metadata can move onto separate lines without splitting each word into a vertical column. Calendar dates retain a seven-column grid, with single-line scaling limited to date numbers and weekday abbreviations; full date/status descriptions remain available to VoiceOver.

Backup format version 1 is a JSON document with `formatVersion`, `exportedAt`, `assignments` and `files`. Dates use Swift Codable's seconds since 2001-01-01 UTC; file contents are base64 and linked by attachment UUID, with length and SHA-256 checked. The file is bounded to 100 MB. Import validates everything before staging unique attachment copies, then saves missing task UUIDs in a single repository transaction. A failed transaction removes only its newly staged files. Reimport preserves existing tasks and tombstones; backup does not serve as a synchronization merge engine. Provider settings and secrets are excluded.

## Redesign data and service boundaries

The original `HomeworkSchemaV1.AssignmentEntity` stays frozen. V2 adds optional status/abandonment columns, then backfills status from the original completion flag in a custom migration. A hosted test creates a real V1 SQLite store and reopens it through the migration plan. Status is authoritative in domain values; the persisted legacy completion flag and encoded backup Boolean remain consistent compatibility mirrors. The store name, attachment directory, bundle ID, preference keys and Keychain identity are preserved.

Undo records only status, completion/abandonment timestamps and deletion state. An action-generation token rejects an obsolete undo even if subsequent status changes return to identical fields. Content edits survive undo, and revisions always increase. Store mutations merge changed records without fetching the entire database. List ordering is cached separately from search filtering; calendar cells read a day index rebuilt for changed records or the screen's shared minute clock.

New-task attachments belong to an editing session until Create succeeds. Cancellation/deinitialization removes only session-owned files. File copying/hashing and cached ImageIO downsampling run in isolated services. Photos and Files are separate native controls; Quick Look is presented by the stable editor Form rather than a virtualized section.

`NotificationCoordinator` incrementally reconciles individual reminders and up to seven finite reports under one total budget of 60 pending requests. Notification actions finish persistence, activity reconciliation and reminder cancellation before returning the system completion callback. Report content uses last known data, and history stores only observed snapshots with their local time zone.

`LiveActivityCoordinator` reconciles at most one final-window countdown through a replaceable client. `ActivityKitClient` uses the installed-SDK-verified `start:` request and handles `.pending`; opaque SDK handles stay inside their async operations. The extension receives Sendable value content and uses native timer views. It never reads the task database and needs no App Group, APNs or backend. Bundle validation checks extension embedding, version alignment and deep links. The extension-free package disables Live Activities while retaining the same app identity and ordinary reminders. Signing, delivery and system-controlled presentation still require the physical checklist.
