import StoreKit
import SwiftUI

@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs = Set<String>()
    
    private let productIdentifiers = ["com.htasks.aiprompts.30"]
    
    private init() {
        // Initialize StoreKit
        Task {
            await loadProducts()
            await updatePurchasedProducts()
            
            // Listen for transactions
            for await result in Transaction.updates {
                await handle(transactionResult: result)
            }
        }
    }
    
    private func handle(transactionResult: VerificationResult<Transaction>) async {
        do {
            let transaction = try checkVerified(transactionResult)
            if transaction.productID == "com.htasks.aiprompts.30" {
                SecureStorageManager.shared.addPrompts(30)
            }
            purchasedProductIDs.insert(transaction.productID)
            await transaction.finish()
        } catch {
            print("Failed to handle transaction: \(error)")
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
            await updatePurchasedProducts()
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
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.productID == "com.htasks.aiprompts.30" {
                    SecureStorageManager.shared.addPrompts(30)
                }
                purchasedProductIDs.insert(transaction.productID)
            } catch {
                print("Failed to update purchased products: \(error)")
            }
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
}

enum StoreError: Error {
    case failedVerification
} 