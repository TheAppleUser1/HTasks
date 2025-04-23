import Foundation

class PromptManager: ObservableObject {
    static let shared = PromptManager()
    
    @Published private(set) var dailyPromptCount: Int = 0
    @Published private(set) var purchasedPrompts: Int = 0
    private let maxFreePrompts = 15
    private let promptsPerPurchase = 30
    
    private let userDefaults = UserDefaults.standard
    private let lastResetDateKey = "lastResetDate"
    private let purchasedPromptsKey = "purchasedPrompts"
    
    private init() {
        loadState()
        checkAndResetDailyCount()
    }
    
    private func loadState() {
        dailyPromptCount = userDefaults.integer(forKey: "dailyPromptCount")
        purchasedPrompts = userDefaults.integer(forKey: purchasedPromptsKey)
    }
    
    private func checkAndResetDailyCount() {
        let calendar = Calendar.current
        let now = Date()
        
        if let lastResetDate = userDefaults.object(forKey: lastResetDateKey) as? Date {
            if !calendar.isDate(lastResetDate, inSameDayAs: now) {
                dailyPromptCount = 0
                userDefaults.set(now, forKey: lastResetDateKey)
                userDefaults.set(dailyPromptCount, forKey: "dailyPromptCount")
            }
        } else {
            userDefaults.set(now, forKey: lastResetDateKey)
        }
    }
    
    func incrementPromptCount() {
        dailyPromptCount += 1
        userDefaults.set(dailyPromptCount, forKey: "dailyPromptCount")
    }
    
    func addPurchasedPrompts() {
        purchasedPrompts += promptsPerPurchase
        userDefaults.set(purchasedPrompts, forKey: purchasedPromptsKey)
    }
    
    var canSendPrompt: Bool {
        return dailyPromptCount < maxFreePrompts || purchasedPrompts > 0
    }
    
    var remainingPrompts: Int {
        if purchasedPrompts > 0 {
            return purchasedPrompts
        }
        return max(0, maxFreePrompts - dailyPromptCount)
    }
    
    func usePrompt() {
        if purchasedPrompts > 0 {
            purchasedPrompts -= 1
            userDefaults.set(purchasedPrompts, forKey: purchasedPromptsKey)
        } else {
            incrementPromptCount()
        }
    }
} 