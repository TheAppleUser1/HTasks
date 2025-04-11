import Foundation
import Security

class SecureStorageManager {
    static let shared = SecureStorageManager()
    
    private init() {
        checkAndResetDailyLimit()
    }
    
    private func checkAndResetDailyLimit() {
        let calendar = Calendar.current
        let lastResetDate = UserDefaults.standard.object(forKey: "lastResetDate") as? Date ?? Date()
        
        if !calendar.isDateInToday(lastResetDate) {
            // Reset daily limit
            saveToKeychain(value: 15)
            UserDefaults.standard.set(Date(), forKey: "lastResetDate")
        }
    }
    
    func getDailyLimit() -> Int {
        return readFromKeychain() ?? 15
    }
    
    func decrementDailyLimit() {
        let dailyLimit = readFromKeychain() ?? 15
        saveToKeychain(value: max(0, dailyLimit - 1))
    }
    
    func resetDailyLimit() {
        saveToKeychain(value: 15)
    }
    
    private func saveToKeychain(value: Int) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "dailyLimit",
            kSecValueData as String: Data(String(value).utf8),
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Error saving to Keychain: \(status)")
        }
    }
    
    private func readFromKeychain() -> Int? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "dailyLimit",
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let string = String(data: data, encoding: .utf8),
           let value = Int(string) {
            return value
        }
        
        return nil
    }
} 