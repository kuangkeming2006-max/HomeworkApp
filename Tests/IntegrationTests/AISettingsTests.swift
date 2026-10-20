import XCTest
import HomeworkDomain
@testable import HomeworkApp

@MainActor
private final class MemorySecrets: SecretStore {
    var key: String?
    func readKey() throws -> String? { key }
    func saveKey(_ key: String) throws { self.key = key }
    func deleteKey() throws { key = nil }
}

@MainActor
final class AISettingsTests: XCTestCase {
    func testConfigurationPersistsWithoutExposingKeyAndBlankKeepsSavedKey() async throws {
        let suite = "HomeworkTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let preferences = AppPreferences(defaults: defaults)
        let secrets = MemorySecrets()
        let model = AISettingsViewModel(preferences: preferences, secrets: secrets,
                                        buildProvider: { _, _ in FixtureLLMProvider() })
        model.configuration = .init(baseURL: "https://example.com/v1", model: "fixture")
        model.apiKey = "synthetic-key-for-unit-test"
        XCTAssertTrue(model.save())
        XCTAssertTrue(model.apiKey.isEmpty)
        XCTAssertTrue(model.hasSavedKey)
        XCTAssertEqual(secrets.key, "synthetic-key-for-unit-test")
        XCTAssertEqual(AppPreferences(defaults: defaults).provider, model.configuration)
        let savedPreferences = try XCTUnwrap(defaults.data(forKey: "llmProvider"))
        XCTAssertFalse(String(decoding: savedPreferences, as: UTF8.self).contains("synthetic-key"))
        XCTAssertTrue(model.save())
        XCTAssertEqual(secrets.key, "synthetic-key-for-unit-test")
        await model.testConnection()
        XCTAssertEqual(model.message, "Synthetic connection succeeded.")
        model.removeKey()
        XCTAssertNil(secrets.key)
        XCTAssertFalse(model.hasSavedKey)
    }
}
