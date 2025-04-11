import StoreKit
import SwiftUI

@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs = Set<String>()
    
    private let productIdentifiers = ["com.htasks.aiprompts.30"]
    
    private init() {
        Task {
            await setupStoreKit()
        }
    }
    
    private func setupStoreKit() async {
        await loadProducts()
        await updatePurchasedProducts()
        
        // Listen for transactions
        for await result in Transaction.updates {
            await handle(transactionResult: result)
        }
    }
    
    private func handle(transactionResult: VerificationResult<StoreKit.Transaction>) async {
        do {
            let transaction = try checkVerified(transactionResult)
            if transaction.productID == "com.htasks.aiprompts.30" {
                // Add 30 prompts for consumable purchase
                SecureStorageManager.shared.addPrompts(30)
            }
            // For consumables, we don't need to track purchasedProductIDs
            await transaction.finish()
        } catch {
            print("Failed to handle transaction: \(error)")
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    func loadProducts() async {
        do {
            products = try await Product.products(for: productIdentifiers)
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            // Add prompts immediately for consumable
            if transaction.productID == "com.htasks.aiprompts.30" {
                SecureStorageManager.shared.addPrompts(30)
            }
            await transaction.finish()
            return true
            
        case .userCancelled:
            return false
            
        case .pending:
            return false
            
        @unknown default:
            return false
        }
    }
    
    func updatePurchasedProducts() async {
        // For consumables, we don't need to track past purchases
        // as they are one-time use
    }
}

enum StoreError: Error {
    case failedVerification
} 