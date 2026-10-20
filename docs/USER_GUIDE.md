# Using Homework

## Assignments and calendar

Use **+** for manual creation or **Add with AI** for assisted import. Upcoming is the default; Completed and All show the other completion states. Priority sorting orders P1 through P4, then deadlines, creation time and UUID. The Sort menu also offers Deadline. Tap the circle to complete or restore; use swipe actions or the context menu to delete or edit. Deletion retains an internal tombstone for future sync.

Open an assignment to edit it. Valid changes save automatically after a short delay and when leaving the screen. Invalid values show an error. Choose a deadline's time zone explicitly; the stored deadline is an absolute instant. The month calendar shows tasks in the device's local calendar. Tap a day to list its tasks, use the arrows or Today to navigate, and use + to create a task for the selected day.

## Reminders and attachments

Each assignment has its own reminder. Settings defines only the default copied into new tasks. None, presets and Custom are available. Hours/minutes are elapsed time; days/weeks preserve wall-clock time across daylight saving transitions in the task's time zone.

Enable notifications explicitly in Settings. Task management works without permission. Completed/deleted tasks have their pending reminders cancelled; edits and restoration reschedule them. Past reminder times are skipped. The earliest 60 reminders are scheduled, leaving room under the system limit; unrelated app requests reduce this capacity. Open the app regularly to replenish deferred reminders. Settings reports skipped and deferred reminders. A closed app cannot replenish requests after the system's pending limit is reached.

Create a task before adding attachments. Photos and Files create persistent private copies, up to 25 MB each and 100 attachments per task. The original may then be moved or removed. Identical bytes are deduplicated within that task. Tap a filename to preview it; use the trash icon to remove it. Deleted-task files are cleaned after a one-day grace period.

## Optional AI import

In Settings → AI provider, enter your provider's HTTPS API base URL (including `/v1` if needed), model name and API key. The key stays in device-local Keychain. Enable images only for a compatible vision model; turn JSON mode off if a compatible endpoint rejects it. Test connection verifies a text response, not vision capability. Provider errors do not affect manual tasks.

Add with AI accepts text and up to four Photos/screenshots. Images are downsampled before upload, bounded to 4 MB each and 8 MB total; text is limited to 16,000 characters. Only the selected content is sent. Your current date/time zone accompanies the request. Check every candidate, edit its fields, deselect unwanted tasks, and explicitly confirm unclear deadlines. No task is saved until **Save selected**. AI interpretation can still be incorrect even when a response passes structural validation; the review is essential.

## Backup and restore

Settings → Backup and restore exports one JSON file containing active/completed tasks and attachment contents. Store it outside the app. It is not encrypted and contains your task data. Maximum size is 100 MB. API keys and provider settings are excluded.

Import first validates the entire document and attachment checksums, then previews new/skipped task counts. Restore adds only missing UUIDs, preserving existing assignments and deletion records. Reimporting the same file is safe. A damaged import leaves existing data unchanged. To recover an earlier version of an already existing task, use a separate clean installation; import deliberately avoids overwriting your current edits.

Keep the same signing account/team and effective bundle ID when updating through SideStore. Install updates over the current app and retain an external backup. Actual signing and notification delivery require a device; see [the device checklist](DEVICE_TESTS.md).
