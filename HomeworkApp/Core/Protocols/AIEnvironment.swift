import SwiftUI
import HomeworkDomain

typealias LLMProviderFactory = @MainActor @Sendable () throws -> any LLMProvider
typealias LLMProviderBuilder = @Sendable (ProviderConfiguration, String) -> any LLMProvider

private struct LLMProviderFactoryKey: EnvironmentKey {
    static let defaultValue: LLMProviderFactory? = nil
}

extension EnvironmentValues {
    var llmProviderFactory: LLMProviderFactory? {
        get { self[LLMProviderFactoryKey.self] }
        set { self[LLMProviderFactoryKey.self] = newValue }
    }
}
