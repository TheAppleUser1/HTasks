import Foundation
import Security

class SecureStorageManager {
    static let shared = SecureStorageManager()
    private let service = "com.htasks.gemini"
    private let account = "rateLimit"
    private let lastResetDateKey = "lastResetDate"
    private let purchasedPromptsKey = "purchasedPrompts"
    
    private init() {
        checkAndResetDailyLimit()
    }
    
    private func checkAndResetDailyLimit() {
        let lastResetDate = UserDefaults.standard.object(forKey: lastResetDateKey) as? Date ?? Date()
        let calendar = Calendar.current
        
        if !calendar.isDateInToday(lastResetDate) {
            // Reset daily limit
            saveToKeychain(value: 15)
            UserDefaults.standard.set(Date(), forKey: lastResetDateKey)
        }
    }
    
    func getRemainingMessages() -> Int {
        let dailyLimit = readFromKeychain() ?? 15
        let purchasedPrompts = UserDefaults.standard.integer(forKey: purchasedPromptsKey)
        return dailyLimit + purchasedPrompts
    }
    
    func decrementMessages() -> Int {
        let current = getRemainingMessages()
        let newValue = max(0, current - 1)
        
        // First use purchased prompts if available
        var purchasedPrompts = UserDefaults.standard.integer(forKey: purchasedPromptsKey)
        if purchasedPrompts > 0 {
            purchasedPrompts -= 1
            UserDefaults.standard.set(purchasedPrompts, forKey: purchasedPromptsKey)
        } else {
            // Use daily limit
            let dailyLimit = readFromKeychain() ?? 15
            saveToKeychain(value: max(0, dailyLimit - 1))
        }
        
        return newValue
    }
    
    func addPrompts(_ count: Int) {
        let currentPurchased = UserDefaults.standard.integer(forKey: purchasedPromptsKey)
        UserDefaults.standard.set(currentPurchased + count, forKey: purchasedPromptsKey)
    }
    
    func resetMessages() {
        saveToKeychain(value: 15)
        UserDefaults.standard.set(0, forKey: purchasedPromptsKey)
        UserDefaults.standard.set(Date(), forKey: lastResetDateKey)
    }
    
    private func saveToKeychain(value: Int) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: Data(String(value).utf8)
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            print("Error saving to Keychain: \(status)")
            return
        }
    }
    
    private func readFromKeychain() -> Int? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8),
              let value = Int(string) else {
            return nil
        }
        
        return value
    }
} 