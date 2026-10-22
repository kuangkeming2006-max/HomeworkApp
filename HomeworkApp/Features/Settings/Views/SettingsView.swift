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
    var liveActivities: LiveActivityCoordinator? = nil
    @Environment(\.openURL) private var openURL

    var body: some View {
        @Bindable var preferences = self.preferences
        Form {
            Section("Appearance") {
                Picker("Appearance", selection: $preferences.appearance) {
                    ForEach(AppAppearance.allCases) { Text($0.rawValue).tag($0) }
                }
                .accessibilityIdentifier("settings.appearance")
                .tint(.blue)
                NavigationLink {
                    ThemeColorPicker(preferences: preferences)
                        .toolbar(.hidden, for: .tabBar)
                } label: {
                    HStack {
                        Text("Theme color").foregroundStyle(.primary)
                        Spacer()
                        Circle().fill(preferences.accent.color).frame(width: 18, height: 18)
                        Text(preferences.accent.rawValue).foregroundStyle(.secondary)
                    }
                }
                .accessibilityIdentifier("settings.accent")
            }
            Section("AI") {
                NavigationLink("AI provider") {
                    AISettingsView(preferences: preferences, secrets: secrets, buildProvider: buildProvider)
                        .toolbar(.hidden, for: .tabBar)
                }
                    .accessibilityIdentifier("settings.ai")
            }
            if let backup = backupService {
                Section("Data") {
                    NavigationLink("Backup and restore") { BackupView(store: store, service: backup).toolbar(.hidden, for: .tabBar) }
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
            Section("Live Activities") {
                NativeToggleRow(title: "Deadline countdown", isOn: $preferences.liveActivitiesEnabled, identifier: "settings.liveActivities")
                if let liveActivities {
                    LabeledContent("Status", value: liveActivities.status)
                    if let error = liveActivities.errorMessage { Text(error).font(.caption).foregroundStyle(.secondary) }
                }
                Text("Shows one urgent assignment during its final four hours. The system controls scheduled starts and Dynamic Island presentation. Ordinary reminders remain available when unsupported.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            BriefingSettingsSection(preferences: preferences)
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--preview-activities") {
                Section("Layout testing") {
                    NavigationLink("Live Activity layouts") { ActivityLayoutGallery().toolbar(.hidden, for: .tabBar) }
                        .accessibilityIdentifier("settings.activityLayouts")
                }
            }
            #endif
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
