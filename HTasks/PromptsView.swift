import SwiftUI
import StoreKit

struct PromptsView: View {
    @StateObject private var storeKitManager = StoreKitManager.shared
    @State private var remainingPrompts = SecureStorageManager.shared.getRemainingMessages()
    @State private var showingPurchaseSheet = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Remaining Prompts: \(remainingPrompts)")
                .font(.title)
                .bold()
            
            if let product = storeKitManager.products.first {
                Button(action: {
                    showingPurchaseSheet = true
                }) {
                    Text("Purchase 30 Prompts - \(product.displayPrice)")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .onChange(of: storeKitManager.purchasedProductIDs) { _ in
            remainingPrompts = SecureStorageManager.shared.getRemainingMessages()
        }
        .sheet(isPresented: $showingPurchaseSheet) {
            if let product = storeKitManager.products.first {
                PurchaseView(product: product)
            }
        }
    }
}

struct PurchaseView: View {
    let product: Product
    @State private var isPurchasing = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Purchase 30 AI Prompts")
                .font(.title)
                .bold()
            
            Text("Get 30 additional AI prompts for your tasks")
                .multilineTextAlignment(.center)
                .padding()
            
            Text("Price: \(product.displayPrice)")
                .font(.title2)
            
            Button(action: {
                Task {
                    isPurchasing = true
                    do {
                        let success = try await StoreKitManager.shared.purchase(product)
                        if success {
                            dismiss()
                        }
                    } catch {
                        print("Purchase failed: \(error)")
                    }
                    isPurchasing = false
                }
            }) {
                if isPurchasing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Purchase")
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(isPurchasing)
            
            Button("Cancel") {
                dismiss()
            }
            .foregroundColor(.gray)
        }
        .padding()
    }
} 