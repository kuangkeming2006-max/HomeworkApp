# Module boundaries

`App → Features → HomeworkDomain`; `App → platform Services → HomeworkDomain`. Features do not know concrete storage, networking or file adapters. AppContainer constructs dependencies and owns app-wide lifetimes. Pure policy does not depend on UI or platform frameworks.

| Location | Responsibility | Stage |
| --- | --- | --- |
| `App` | App lifecycle, adaptive navigation, dependency composition | 1 |
| `Packages/HomeworkDomain` | Sendable value types, sorting, validation, calendar/reminder/AI policies, repository and service protocols | 1–4 |
| `Core/Persistence` | Versioned SwiftData models, migration plan, domain mapping | 2 |
| `Features/Assignments` | List/detail presentation, editing and filtering | 2 |
| `Features/Calendar` | Interactive month grid and selection | 2 |
| `Services/AssignmentRepository` | SwiftData repository implementing the domain boundary | 2 |
| `Features/Reminders`, `Services/NotificationService` | Per-task settings and bounded scheduling reconciliation | 3 |
| `Features/Attachments`, `Services/AttachmentService` | Import, persistent relative references, previews and cleanup | 3 |
| `Features/AIImport`, `Services/LLMService` | Optional text/image parsing, strict validation, mandatory confirmation | 4 |
| `Services/KeychainService` | Device-local API secret storage | 4 |
| `Features/Settings` | Defaults, provider configuration and backups | 1–5 |
| `Services/SyncService` | Replaceable no-op boundary, no server or account | 2 |

Future directories are created when implementation begins. No empty framework or fake implementation is introduced just to match a diagram. Domain protocols permit replacing persistence, providers and future sync independently. SwiftData migration is explicit; an error never authorizes deleting user stores.

The deployment target is iOS/iPadOS 26. System SwiftUI navigation, lists and forms inherit the current system appearance when built with the Xcode 27 SDK. Any later iOS 27-only API must have an availability guard and a viable iOS 26 path. No blur-overlay imitation of Liquid Glass is used.

Phase 1 compact-width navigation uses tabs; regular-width navigation uses a sidebar and content pane. Phase 2 will add task list/detail columns. Horizontal size class, rather than device identity, determines composition.
