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

Domain protocols permit replacing persistence, attachments, backups, notifications, HTTP transport, providers and future sync independently. SwiftData uses an explicit versioned schema; an error never authorizes deleting user stores. Editor changes are field patches against the latest stored record so editing in another window does not overwrite unrelated fields.

The deployment target is iOS/iPadOS 26. System SwiftUI navigation, lists and forms inherit the current system appearance when built with the Xcode 27 SDK. Any later iOS 27-only API must have an availability guard and a viable iOS 26 path. No blur-overlay imitation of Liquid Glass is used.

Compact-width navigation uses tabs; regular-width navigation uses a sidebar. Task list/detail columns appear when the remaining available width is at least 720 points. Width and horizontal size class determine composition, allowing resized iPad windows to fall back to a navigation stack.

Backup format version 1 is a JSON document with `formatVersion`, `exportedAt`, `assignments` and `files`. Dates use Swift Codable's seconds since 2001-01-01 UTC; file contents are base64 and linked by attachment UUID, with length and SHA-256 checked. The file is bounded to 100 MB. Import validates everything before staging unique attachment copies, then saves missing task UUIDs in a single repository transaction. A failed transaction removes only its newly staged files. Reimport preserves existing tasks and tombstones; backup does not serve as a synchronization merge engine. Provider settings and secrets are excluded.
