import Foundation
import Security

/// Service for securely storing credentials in macOS Keychain
class KeychainService {
    private let serviceName = "me.orzech.FastMemos"
    
    // MARK: - Access Token
    
    func saveAccessToken(_ token: String) {
        save(key: "accessToken", value: token)
    }
    
    func getAccessToken() -> String? {
        return get(key: "accessToken")
    }
    
    func deleteAccessToken() {
        delete(key: "accessToken")
    }
    
    // MARK: - Username
    
    func saveUsername(_ username: String) {
        save(key: "username", value: username)
    }
    
    func getUsername() -> String? {
        return get(key: "username")
    }
    
    func deleteUsername() {
        delete(key: "username")
    }
    
    // MARK: - Generic Keychain Operations
    
    private func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        
        // Delete any existing item first
        delete(key: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
