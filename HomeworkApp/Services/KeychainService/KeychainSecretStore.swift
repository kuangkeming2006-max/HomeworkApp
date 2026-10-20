import Foundation
import Security
import HomeworkDomain

@MainActor
final class KeychainSecretStore: SecretStore {
    private let service = "com.kkm.homework.llm"
    private let account = "provider-api-key"
    private var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service,
         kSecAttrAccount as String: account, kSecAttrSynchronizable as String: false]
    }

    func readKey() throws -> String? {
        var lookup = query
        lookup[kSecReturnData as String] = true
        lookup[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(lookup as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else { throw SecretError.unavailable }
        return key
    }

    func saveKey(_ key: String) throws {
        let data = Data(key.utf8)
        let attributes: [String: Any] = [kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var insertion = query
            attributes.forEach { insertion[$0.key] = $0.value }
            guard SecItemAdd(insertion as CFDictionary, nil) == errSecSuccess else { throw SecretError.unavailable }
        } else if status != errSecSuccess { throw SecretError.unavailable }
    }

    func deleteKey() throws {
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw SecretError.unavailable }
    }

    private enum SecretError: LocalizedError {
        case unavailable
        var errorDescription: String? { "Secure storage is unavailable. Unlock your device and try again." }
    }
}
