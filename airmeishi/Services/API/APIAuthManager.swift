//
//  APIAuthManager.swift
//  airmeishi
//
//  Stores and manages API authentication token
//

import Foundation
import Security

/// Manages API bearer token securely in Keychain
class APIAuthManager {
    static let shared = APIAuthManager()
    
    private let service = "com.kidneyweakx.airmeishi.api"
    private let account = "bearer_token"
    
    private init() {}
    
    func setToken(_ token: String?) -> CardResult<Void> {
        guard let token = token, !token.isEmpty else {
            return deleteToken()
        }
        
        let data = Data(token.utf8)
        
        // Delete existing first
        let _ = deleteToken()
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecSuccess {
            return .success(())
        } else {
            return .failure(.storageError("Failed to store token: \(status)"))
        }
    }
    
    func getToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    @discardableResult
    func deleteToken() -> CardResult<Void> {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess || status == errSecItemNotFound {
            return .success(())
        } else {
            return .failure(.storageError("Failed to delete token: \(status)"))
        }
    }
}


