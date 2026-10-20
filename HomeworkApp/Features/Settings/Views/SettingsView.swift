import SwiftUI
import UIKit
import HomeworkDomain

struct SettingsView: View {
    let container: AppContainer
    @Environment(\.openURL) private var openURL

    var body: some View {
        @Bindable var preferences = container.preferences
        Form {
            Section("Notifications") {
                LabeledContent("Permission", value: permissionText)
                if container.notifications.permission == .notDetermined {
                    Button("Enable notifications") { Task { await container.notifications.enable() } }
                        .accessibilityIdentifier("settings.enableNotifications")
                } else if container.notifications.permission == .denied {
                    Button("Open system Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    }
                }
                LabeledContent("Scheduled reminders", value: "\(container.notifications.scheduledCount)")
                if container.notifications.deferredCount > 0 {
                    Text("Later reminders will be scheduled when you reopen the app.").foregroundStyle(.secondary)
                }
                if container.notifications.pastCount > 0 {
                    Text("\(container.notifications.pastCount) reminder times have already passed.").foregroundStyle(.secondary)
                }
                if let error = container.notifications.errorMessage { Text(error).foregroundStyle(.red) }
            }
            Section {
                ReminderPicker(value: $preferences.defaultReminder)
            } header: { Text("Default reminder") }
              footer: { Text("Applies to new assignments. Each assignment can use a different reminder.") }
            Section("About") {
                LabeledContent("Version", value: container.version)
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
        switch container.notifications.permission {
        case .allowed: "Enabled"
        case .notDetermined: "Not requested"
        case .denied: "Disabled in system Settings"
        }
    }
}
