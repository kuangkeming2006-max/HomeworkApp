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
