import Foundation
import Observation
import HomeworkDomain

@Observable @MainActor
final class AISettingsViewModel {
    var configuration: ProviderConfiguration
    var apiKey = ""
    private(set) var hasSavedKey = false
    private(set) var busy = false
    var message: String?
    private let preferences: AppPreferences
    private let secrets: any SecretStore
    private let buildProvider: LLMProviderBuilder

    init(preferences: AppPreferences, secrets: any SecretStore, buildProvider: @escaping LLMProviderBuilder) {
        self.preferences = preferences; self.secrets = secrets; self.buildProvider = buildProvider
        configuration = preferences.provider
        do { hasSavedKey = !(try secrets.readKey() ?? "").isEmpty }
        catch { message = error.localizedDescription }
    }

    @discardableResult
    func save() -> Bool {
        do {
            _ = try configuration.endpoint()
            if !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                try secrets.saveKey(apiKey.trimmingCharacters(in: .whitespacesAndNewlines))
                hasSavedKey = true; apiKey = ""
            }
            preferences.provider = configuration
            message = "Configuration saved."
            return true
        } catch { message = error.localizedDescription; return false }
    }

    func testConnection() async {
        guard !busy, save() else { return }
        busy = true; defer { busy = false }
        do {
            guard let key = try secrets.readKey(), !key.isEmpty else { throw LLMError.missingKey }
            message = try await buildProvider(configuration, key).testConnection()
        } catch { message = error.localizedDescription }
    }

    func removeKey() {
        do {
            try secrets.deleteKey(); apiKey = ""; hasSavedKey = false
            message = "API key removed."
        } catch { message = error.localizedDescription }
    }
}
