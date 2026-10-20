# Physical device checklist

Record app commit, OS version, signing tool version and effective bundle ID. These checks cannot be certified by the simulator pipeline.

- Install the unsigned arm64 IPA after free-account signing; launch on iPhone and iPad.
- Refresh provisioning, then update the same installed app without uninstalling. Confirm records, attachments and settings survive; later verify Keychain behavior after re-signing with the same team.
- After reminders exist: grant/deny notifications, background and terminate the app, confirm delivery; edit/complete/delete/restore and verify cancellations/replacements. Change timezone and cross a DST boundary.
- Import from Photos/Files and a third-party file provider, preview/share files, revoke source access and confirm the persistent copy survives relaunch.
- After backup exists: export through the share sheet, restore on a fresh installation and verify tasks and attachments; malformed imports must leave current data intact.
- Resize iPad windows, use Split View and a hardware keyboard. Check Dynamic Type, VoiceOver and both appearances.

Features listed as later phases remain unchecked until implemented. Do not mark this list passed based only on CI.
