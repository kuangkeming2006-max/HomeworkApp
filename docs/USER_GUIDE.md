# Using Homework

## Assignments and calendar

Use **+** for manual creation or **Add with AI** for assisted import. Upcoming is the default; Completed, Abandoned and All show the other states. Search matches title, course and notes within the selected category. Priority sorting orders P1 through P4, then deadlines, creation time and UUID. The Sort menu also offers Deadline.

Tap the circle to choose Complete, Abandon or Restore. Swipe right for Complete/Restore; swipe left for Abandon/Delete. A full swipe never deletes automatically. Use the category header or empty area for horizontal page changes on compact layouts; rows keep their action gestures. Wider layouts use a category menu and list/detail panes. The bottom Undo action lasts five seconds and restores status/timestamps without reverting newer content edits. Abandoned tasks have no deadline reminders. Deletion retains an internal tombstone for future sync.

Open an assignment to edit it. Valid changes save automatically after a short delay and when leaving the screen. Invalid values show an error. Choose a deadline's time zone explicitly; the stored deadline is an absolute instant. The calendar groups deadlines by the device's local day. Tap the month heading to choose a month/year, use the arrows or horizontal month swipes, or return with Today. Day selection is preserved where possible and clamped for shorter months. Use + for the selected date.

Calendar dots show distinct states, not one dot per task: red overdue, orange reminder threshold reached, yellow due within 24 hours, accent upcoming, green completed and gray abandoned. Terminal states take precedence over deadline urgency. VoiceOver reads the counts for each state.

## Reminders and attachments

Each assignment has its own reminder. Settings defines only the default copied into new tasks. None, presets and Custom are available. Hours/minutes are elapsed time; days/weeks preserve wall-clock time across daylight saving transitions in the task's time zone.

The first-launch explanation lets you enable notifications or continue without them. System permission is requested only while undetermined; denied permission can be changed in system Settings. Completed, abandoned and deleted tasks have their pending/delivered reminders cancelled; edits and restoration reconcile changed requests. Past reminder times are skipped. At most 60 requests are reserved in total, including briefings and unrelated requests; later task reminders are deferred. Reopen the app to replenish this finite schedule. View opens the task; the notification's Complete action saves completion.

Photos and Files are available during creation as well as editing. New-task imports are staged until Create; canceling the draft cleans its own copies, while a validation error keeps them available for correction. Imports make persistent private copies, up to 25 MB each and 100 attachments per task. The original may then be moved or removed. Identical bytes are deduplicated within that task. Image thumbnails are resized and cached; tap an image/file for Quick Look and use the trash icon to remove it. Deleted-task files are cleaned after a one-day grace period.

## Live Activities and Briefing

Enable Deadline countdown in Settings to track one eligible urgent assignment. The countdown occupies at most its final four hours; shorter reminder lead times start it later. Future starts use the local ActivityKit scheduling API and an alert configuration, with no APNs/server. Changes reconcile pending/active activities. The system controls authorization, duration and Dynamic Island expansion. A successfully registered activity owns an exactly coincident alert; earlier reminders remain ordinary notifications. If activity creation fails, ordinary reminders remain the fallback. Delivery and extension signing must be checked on a device.

Briefing works offline even without notification permission. Remaining/overdue counts exclude completed and abandoned work. Completed today uses actual completion timestamps. The progress ring counts completed assignments **due today**, with abandoned/deleted tasks excluded from its denominator. These are separate metrics. Next priority uses the same priority/deadline order as the task list.

Settings offers disabled/enabled reports, daily/twice-daily/weekly frequency and a preferred local time. The next seven reports use the latest known local records and refresh on edits, activation and time changes. Their content may become stale, and they do not rely on arbitrary background execution. Twice-daily times are twelve wall-clock hours apart and follow daylight-saving changes. Previous reports retain the latest observed snapshot for up to 31 days; unobserved days are omitted. There is no voice narration.

## Optional AI import

In Settings → AI provider, enter your provider's HTTPS API base URL (including `/v1` if needed), model name and API key. The key stays in device-local Keychain. Enable images only for a compatible vision model; turn JSON mode off if a compatible endpoint rejects it. Test connection verifies a text response, not vision capability. Provider errors do not affect manual tasks.

Add with AI accepts text and up to four Photos/screenshots. Images are downsampled before upload, bounded to 4 MB each and 8 MB total; text is limited to 16,000 characters. Only the selected content is sent. Your current date/time zone accompanies the request. Check every candidate, edit its fields, deselect unwanted tasks, and explicitly confirm unclear deadlines. No task is saved until **Save selected**. AI interpretation can still be incorrect even when a response passes structural validation; the review is essential.

## Backup and restore

Settings → Backup and restore exports one JSON file containing nondeleted active/completed/abandoned tasks and attachment contents. Store it outside the app. It is not encrypted and contains your task data. Maximum size is 100 MB. API keys and provider settings are excluded. Version-one backups remain readable.

Import first validates the entire document and attachment checksums, then previews new/skipped task counts. Restore adds only missing UUIDs, preserving existing assignments and deletion records. Reimporting the same file is safe. A damaged import leaves existing data unchanged. To recover an earlier version of an already existing task, use a separate clean installation; import deliberately avoids overwriting your current edits.

Keep the same signing account/team and effective bundle ID when updating through SideStore. Install updates over the current app and retain an external backup. Actual signing and notification delivery require a device; see [the device checklist](DEVICE_TESTS.md).
