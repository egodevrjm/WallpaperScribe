//
//  KeychainHelper.swift
//  Wallpaper Generator
//
//  Created by Ryan Morrison on 9/25/24.
//


import Foundation
import Security

class KeychainHelper {
    static let shared = KeychainHelper()
    private let serviceName = "com.yourapp.wallpaperapp"
    private let apiKeyAccount = "userApiKey"
    
    private init() {}
    
    func save(apiKey: String) {
        guard let data = apiKey.data(using: .utf8) else { return }
        
        // Define query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: apiKeyAccount,
            kSecValueData as String: data
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Error saving API key: \(status)")
        }
    }
    
    func getApiKey() -> String? {
        // Define query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: apiKeyAccount,
            kSecReturnData as String: true
        ]
        
        // Get item from Keychain
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        // Check for success
        if status == errSecSuccess, let data = item as? Data, let apiKey = String(data: data, encoding: .utf8) {
            return apiKey
        }
        return nil
    }
}
