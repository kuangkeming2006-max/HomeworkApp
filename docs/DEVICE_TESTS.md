# Physical device checklist

Record app commit, OS version, signing tool version and effective bundle ID. These checks cannot be certified by the simulator pipeline.

- Install the unsigned arm64 IPA after free-account signing; launch on iPhone and iPad.
- Refresh provisioning, then update the same installed app without uninstalling. Confirm records, attachments and settings survive; later verify Keychain behavior after re-signing with the same team.
- Grant/deny notifications, background and terminate the app, confirm delivery; edit/complete/delete/restore and verify cancellations/replacements. Change timezone and cross a DST boundary. With more than 60 pending reminders, reopen the app to replenish deferred notifications.
- Import from Photos/Files and a third-party file provider, preview/share files, revoke source access and confirm the persistent copy survives relaunch.
- Export a backup to Files, restore on a fresh installation and verify tasks and attachments; malformed imports must leave current data intact. Import twice and confirm no duplicates. Verify exported data is still available outside the app after reinstalling.
- Configure a real provider locally, test text and vision capability, import an announcement and a screenshot with multiple tasks, check ambiguous-date confirmation and cancellation. No real API key is required in CI.
- Resize iPad windows, use Split View and a hardware keyboard. Check Dynamic Type, VoiceOver and both appearances.

These physical-device checks remain unverified. Do not mark them passed based only on CI.

## Redesign checks
- Update the existing SideStore installation with the same Apple account and effective bundle ID. Confirm old active/completed/deleted records, attachments, preferences and API key survive the V2 upgrade. Do not uninstall to update.
- Test short releases, fast direction reversals and cancellation of row swipes at 60/120 Hz. Swipe rows while paging categories from the header; verify no accidental completion/deletion. Check Reduce Motion and accessibility text sizes.
- Complete, abandon, restore and delete, then Undo within five seconds. Repeat rapidly and across iPad windows; later content/status edits must survive old undo actions.
- Import several large images, PDF, TXT and DOCX from local/iCloud/third-party Files providers. Preview, remove, cancel a draft, navigate to time-zone selection and back, then create. Check file retention after relaunch.
- On first launch, inspect the explanation and grant/deny once. Test task-specific alerts, sound/badge, View deep links and Complete actions while foregrounded, backgrounded and terminated.
- Enable Live Activities. Test an immediate final-window countdown and a future scheduled start while the app is suspended. Check pending cancellation/rescheduling, completion/abandon/delete, priority changes, lock screen and all Dynamic Island presentations. Expanded presentation and exact delivery are controlled by the OS, not promised by the app.
- Free-sign/install the main package with its extension; record exact signing errors if rejected. Verify the extension-free package retains notifications and data. Test a non-Dynamic-Island device/iPad fallback.
- Configure daily, twice-daily and weekly reports; change preferred time/time zone/DST. Check summary delivery without keeping the app open. Compare content with the last scheduling snapshot, and verify history contains only observed days.
- Compare scrolling/search/calendar/import responsiveness on a physical device. CI operation timings and automation durations are not a certification of 120 Hz animation performance.
