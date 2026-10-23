# Using Homework

## Assignments and calendar

Use **+** for manual creation or **Add with AI** for assisted import. The borderless category menu beside the Assignments title offers All, Upcoming, Completed, Abandoned and Deleted, without a gray category strip. Tap or hold it for native menu selection. All groups non-deleted tasks under blue, green and gray status headings; individual categories filter without headings. Selection survives tab changes. Pull down to reveal search. Sort opens an anchored native menu with checked Priority/Deadline choices.

Tap a circle to complete active work immediately, or restore completed/abandoned work. Completion animates the checkmark with a short particle burst and success haptic. In Upcoming, the completed row stays for up to five seconds or until leaving the tab; in All it moves into Completed immediately. Undo or restoring cancels pending disappearance. Full swipes complete/restore or delete; context menus also offer Abandon. The five-second Undo restores disposition without reverting newer content edits. Deleted is a recoverable category: Restore preserves the prior status, data and attachments. No permanent-delete command is provided.

Open an assignment to edit a local draft. Nothing is written until the upper-right checkmark Save succeeds. New and existing drafts open as native navigation pages. Back with unsaved changes shows a centered Save / Discard Changes / Keep Editing alert, including interactive Back. Validation or conflicting external edits keep the draft open with an error; independent external changes are preserved. Secondary pages hide the tab bar. Choose a deadline's time zone explicitly; deadlines remain absolute instants.

The calendar grid tracks horizontal dragging and settles with a spring. Month browsing preserves the selected absolute date. Details blur away only during a manual horizontal swipe, then return after a cancellable 200 ms pause. Arrows, Today, month selection and deliberate date taps overlap outgoing/incoming details immediately. Only an actual date tap changes selection; vertical scrolling, blank cells and gaps do not. Highlights use absolute date/page identities. Motion respects Reduce Motion.

Calendar dots show distinct states, not one dot per task: red overdue, orange reminder threshold reached, yellow due within 24 hours, accent upcoming, green completed and gray abandoned. Terminal states take precedence over deadline urgency. VoiceOver reads the counts for each state.

## Reminders and attachments

Each assignment has its own reminder. Settings defines only the default copied into new tasks. None, presets and Custom are available. Hours/minutes are elapsed time; days/weeks preserve wall-clock time across daylight saving transitions in the task's time zone.

The first-launch explanation lets you enable notifications or continue without them. System permission is requested only while undetermined; denied permission can be changed in system Settings. Completed, abandoned and deleted tasks have their pending/delivered reminders cancelled; edits and restoration reconcile changed requests. Past reminder times are skipped. At most 60 requests are reserved in total, including briefings and unrelated requests; later task reminders are deferred. Reopen the app to replenish this finite schedule. View opens the task; the notification's Complete action saves completion.

Photos and Files share one compact native Form row with independent left/right controls. All imports and removals are staged until Save, for both new and existing tasks. Discard cleans only newly imported copies and preserves original attachments. Imports are private copies, up to 25 MB each and 100 per task, deduplicated by bytes within a task. Tap a thumbnail or cropped editor image for fullscreen viewing. At 1x, pull down to close; when enlarged, dragging pans within the image bounds. Pinch and double tap zoom; Close and native sharing remain available. Image filenames are omitted; documents retain names and use Quick Look. Swipe an attachment left and confirm to stage its removal. Deleted assignments retain their attachment files.

## Appearance

The four main iPhone destinations use the native Liquid Glass tab bar. Toolbar actions use neutral adaptive colors; the category menu keeps the configured accent. Secondary pages hide the tab bar and restore it on return. Undo uses the system accessory above the bar. Settings offers saved System/Light/Dark appearance and seven distinct color swatches, defaulting to the original lavender. Destructive actions remain red.

## Live Activities and Briefing

Enable Deadline countdown in Settings to track one eligible urgent assignment. The countdown occupies at most its final four hours; shorter reminder lead times start it later. Future starts use the local ActivityKit scheduling API and an alert configuration, with no APNs/server. Changes reconcile pending/active activities. At the deadline, the system marks the countdown stale and its text changes to Due now without requiring an app wake. The system controls authorization, duration and Dynamic Island expansion. A successfully registered activity owns an exactly coincident alert; earlier reminders remain ordinary notifications. If activity creation fails, ordinary reminders remain the fallback. Delivery and extension signing must be checked on a device.

Briefing works offline even without notification permission. Remaining/overdue counts exclude completed and abandoned work. Completed today uses actual completion timestamps. The progress ring counts completed assignments **due today**, with abandoned/deleted tasks excluded from its denominator. These are separate metrics. Next priority uses the same priority/deadline order as the task list.

Settings offers disabled/enabled reports, daily/twice-daily/weekly frequency and a preferred local time. The next seven reports use the latest known local records and refresh on edits, activation and time changes. Their content may become stale, and they do not rely on arbitrary background execution. Twice-daily times are twelve wall-clock hours apart and follow daylight-saving changes. Previous reports retain the latest observed snapshot for up to 31 days, with its recorded time zone; unobserved days are omitted. There is no voice narration.

## Optional AI import

In Settings → AI provider, enter your provider's HTTPS API base URL (including `/v1` if needed), model name and API key. The key stays in device-local Keychain. Enable images only for a compatible vision model; turn JSON mode off if a compatible endpoint rejects it. Test connection verifies a text response, not vision capability. Provider errors do not affect manual tasks.

Add with AI accepts text and up to four Photos/screenshots. Images are downsampled before upload, bounded to 4 MB each and 8 MB total; text is limited to 16,000 characters. Only the selected content is sent. Your current date/time zone accompanies the request. Check every candidate, edit its fields, deselect unwanted tasks, and explicitly confirm unclear deadlines. No task is saved until **Save selected**. AI interpretation can still be incorrect even when a response passes structural validation; the review is essential.

## Backup and restore

Settings → Backup and restore exports one JSON file containing nondeleted active/completed/abandoned tasks and attachment contents. Store it outside the app. It is not encrypted and contains your task data. Maximum size is 100 MB. API keys and provider settings are excluded. Version-one backups remain readable.

Import first validates the entire document and attachment checksums, then previews new/skipped task counts. Restore adds only missing UUIDs, preserving existing assignments and deletion records. Reimporting the same file is safe. A damaged import leaves existing data unchanged. To recover an earlier version of an already existing task, use a separate clean installation; import deliberately avoids overwriting your current edits.

Keep the same signing account/team and effective bundle ID when updating through SideStore. Install updates over the current app and retain an external backup. Actual signing and notification delivery require a device; see [the device checklist](DEVICE_TESTS.md).
