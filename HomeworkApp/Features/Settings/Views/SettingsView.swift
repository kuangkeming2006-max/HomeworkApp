import SwiftUI
import UIKit
import HomeworkDomain

struct SettingsView: View {
    let version: String
    let preferences: AppPreferences
    let notifications: NotificationCoordinator
    let store: AssignmentStore
    let backupService: (any BackupService)?
    let secrets: any SecretStore
    let buildProvider: LLMProviderBuilder
    @Environment(\.openURL) private var openURL

    var body: some View {
        @Bindable var preferences = self.preferences
        Form {
            Section("AI") {
                NavigationLink("AI provider") {
                    AISettingsView(preferences: preferences, secrets: secrets, buildProvider: buildProvider)
                }
                    .accessibilityIdentifier("settings.ai")
            }
            if let backup = backupService {
                Section("Data") {
                    NavigationLink("Backup and restore") { BackupView(store: store, service: backup) }
                        .accessibilityIdentifier("settings.backup")
                }
            }
            Section("Notifications") {
                LabeledContent("Permission", value: permissionText)
                if notifications.permission == .notDetermined {
                    Button("Enable notifications") { Task { await notifications.enable() } }
                        .accessibilityIdentifier("settings.enableNotifications")
                } else if notifications.permission == .denied {
                    Button("Open system Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    }
                }
                LabeledContent("Scheduled reminders", value: "\(notifications.scheduledCount)")
                if notifications.deferredCount > 0 {
                    Text("Later reminders will be scheduled when you reopen the app.").foregroundStyle(.secondary)
                }
                if notifications.pastCount > 0 {
                    Text("\(notifications.pastCount) reminder times have already passed.").foregroundStyle(.secondary)
                }
                if let error = notifications.errorMessage { Text(error).foregroundStyle(.red) }
            }
            Section {
                ReminderPicker(value: $preferences.defaultReminder)
            } header: { Text("Default reminder") }
              footer: { Text("Applies to new assignments. Each assignment can use a different reminder.") }
            Section("About") {
                LabeledContent("Version", value: version)
                LabeledContent("Storage", value: "On this device")
                    .accessibilityIdentifier("settings.storage")
                Text("Your coursework and attachments stay on your device. AI features are optional.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .accessibilityIdentifier("settings.form")
    }

    private var permissionText: String {
        switch notifications.permission {
        case .allowed: "Enabled"
        case .notDetermined: "Not requested"
        case .denied: "Disabled in system Settings"
        }
    }
}
