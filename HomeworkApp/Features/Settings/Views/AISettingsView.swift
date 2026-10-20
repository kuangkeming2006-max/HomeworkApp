import SwiftUI

struct AISettingsView: View {
    @State private var model: AISettingsViewModel

    init(container: AppContainer) {
        _model = State(initialValue: AISettingsViewModel(preferences: container.preferences,
            secrets: container.secrets, buildProvider: container.providerBuilder))
    }

    var body: some View {
        Form {
            Section("Provider") {
                TextField("HTTPS base URL (including /v1 if needed)", text: $model.configuration.baseURL)
                    .keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                    .accessibilityIdentifier("provider.url")
                TextField("Model name", text: $model.configuration.model)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                    .accessibilityIdentifier("provider.model")
                Toggle("Model supports images", isOn: $model.configuration.supportsImages)
                    .accessibilityIdentifier("provider.vision")
                Toggle("Request JSON mode", isOn: $model.configuration.useJSONMode)
                Text("Turn JSON mode off if your compatible provider rejects it. Responses are always validated before import.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("API key") {
                SecureField(model.hasSavedKey ? "Leave blank to keep saved key" : "API key", text: $model.apiKey)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                    .accessibilityIdentifier("provider.key")
                Text(model.hasSavedKey ? "A key is saved securely on this device." : "No API key saved.")
                    .foregroundStyle(.secondary)
                if model.hasSavedKey { Button("Remove saved key", role: .destructive) { model.removeKey() } }
            }
            Section {
                Button("Save configuration") { model.save() }.accessibilityIdentifier("provider.save")
                Button("Test connection") { Task { await model.testConnection() } }
                    .disabled(model.busy).accessibilityIdentifier("provider.test")
                if model.busy { ProgressView("Connecting…") }
                if let message = model.message { Text(message).accessibilityIdentifier("provider.feedback") }
            } footer: {
                Text("Only content you choose to analyze is sent to this provider. Your provider may charge for requests. The API key is stored in Keychain and is excluded from backups.")
            }
        }
        .navigationTitle("AI provider")
    }
}
