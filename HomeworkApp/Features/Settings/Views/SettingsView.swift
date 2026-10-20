import SwiftUI

struct SettingsView: View {
    let version: String

    var body: some View {
        Form {
            Section("About") {
                LabeledContent("Version", value: version)
                LabeledContent("Storage", value: "On this device")
                    .accessibilityIdentifier("settings.storage")
                Text("Your coursework stays on your device. AI features will be optional.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .accessibilityIdentifier("settings.form")
    }
}
