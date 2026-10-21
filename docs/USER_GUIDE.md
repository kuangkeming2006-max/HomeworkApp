# Using Homework

## Assignments and calendar

Use **+** for manual creation or **Add with AI** for assisted import. Scroll vertically through Upcoming, Completed and Abandoned sections in one list. Search matches title, course and notes across the sections. Priority sorting orders P1 through P4, then deadlines, creation time and UUID. The Sort menu also offers Deadline. Scrolling replaces the large Assignments heading with a compact title at the top left.

Tap the circle for a bottom sheet with three large side-by-side actions: Complete, Abandon and Cancel for upcoming work; Restore, Delete and Cancel for finished work. The circle provides a light haptic; successful completion uses the system success haptic. A full swipe right completes/restores; a full swipe left deletes. A shorter left swipe reveals Abandon and Delete. There is no horizontal category paging. The animated bottom Undo bar lasts five seconds, with a once-per-second countdown, and restores status/timestamps without reverting newer content edits. Abandoned tasks have no deadline reminders. Deletion retains an internal tombstone for future sync.

Open an assignment to edit it. Valid changes save automatically after a short delay and when leaving the screen. Invalid values show an error. Choose a deadline's time zone explicitly; the stored deadline is an absolute instant. The calendar groups deadlines by the device's local day. Tap the month heading to choose a month/year, use the arrows or horizontal month swipes, or return with Today. Day selection is preserved where possible and clamped for shorter months. Use + for the selected date.

The calendar follows a horizontal drag and settles with a spring; arrows use the same translation. A recognized drag suppresses date taps. Date selection uses a contrasting square and a short fade; the details beneath it crossfade, including empty days. Animations respect Reduce Motion.

Calendar dots show distinct states, not one dot per task: red overdue, orange reminder threshold reached, yellow due within 24 hours, accent upcoming, green completed and gray abandoned. Terminal states take precedence over deadline urgency. VoiceOver reads the counts for each state.

## Reminders and attachments

Each assignment has its own reminder. Settings defines only the default copied into new tasks. None, presets and Custom are available. Hours/minutes are elapsed time; days/weeks preserve wall-clock time across daylight saving transitions in the task's time zone.

The first-launch explanation lets you enable notifications or continue without them. System permission is requested only while undetermined; denied permission can be changed in system Settings. Completed, abandoned and deleted tasks have their pending/delivered reminders cancelled; edits and restoration reconcile changed requests. Past reminder times are skipped. At most 60 requests are reserved in total, including briefings and unrelated requests; later task reminders are deferred. Reopen the app to replenish this finite schedule. View opens the task; the notification's Complete action saves completion.

Photos and Files are available during creation as well as editing. New-task imports are staged until Create; canceling the draft cleans its own copies, while a validation error keeps them available for correction. Imports make persistent private copies, up to 25 MB each and 100 attachments per task. The original may then be moved or removed. Identical bytes are deduplicated within that task. Tap a list thumbnail or large cropped editor image to open the image full screen. Pull down or use Close to dismiss; pinch or double-tap to zoom. Image filenames are omitted from the editor. Documents retain filenames and use Quick Look. Use the trash icon to remove an attachment. Deleted-task files are cleaned after a one-day grace period.

## Appearance

The four iPhone navigation buttons have equal widths; switching pages uses a short fade and vertical movement. Settings → Appearance offers System, Light and Dark, plus seven theme colors. Both choices are saved on the device and apply throughout the app.

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
