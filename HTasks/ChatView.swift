import SwiftUI
import StoreKit
import SwiftGlass

struct ChatView: View {
    @StateObject private var promptManager = PromptManager.shared
    @StateObject private var storeKit = StoreKitConfig.shared
    @State private var messageText = ""
    @State private var messages: [Message] = []
    @State private var isLoading = false
    @State private var scrollToBottom: Bool = false
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var isInputFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Chat with AI Assistant")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .padding(.top)
            
            Text("Powered by Gemini 2.0 Flash")
                .font(.subheadline)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
            
            ScrollView {
                VStack(spacing: 16) {
                    // Message bubbles with reduced glass opacity
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                            .glass(radius: 12, color: colorScheme == .dark ? .white : .black, material: .regularMaterial, gradientOpacity: 0.15)
                    }
                }
                .padding()
            }
            
            // Input field with reduced glass opacity
            HStack {
                TextField("Type your message...", text: $messageText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding()
                    .glass(radius: 12, color: colorScheme == .dark ? .white : .black, material: .regularMaterial, gradientOpacity: 0.15)
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .font(.title2)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .frame(width: 44, height: 44)
                }
                .glass(radius: 12, color: colorScheme == .dark ? .white : .black, material: .regularMaterial, gradientOpacity: 0.15)
            }
            .padding()
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: colorScheme == .dark ?
                                  [Color.black, Color.blue.opacity(0.2)] :
                                  [Color.white, Color.blue.opacity(0.1)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadMessages()
        }
        .onDisappear {
            saveMessages()
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        if !promptManager.canSendPrompt {
            // Add the limit message directly without using the AI model
            let limitMessage = Message(
                text: "Sorry, you reached your daily limit. Purchase 30 more prompts to continue using the AI model.",
                isUser: false,
                timestamp: Date()
            )
            messages.append(limitMessage)
            return
        }
        
        let userMessage = Message(
            text: messageText,
            isUser: true,
            timestamp: Date()
        )
        messages.append(userMessage)
        messageText = ""
        
        isLoading = true
        
        Task {
            do {
                let response = try await GeminiService.shared.sendMessage(userMessage.text)
                let aiMessage = Message(
                    text: response,
                    isUser: false,
                    timestamp: Date()
                )
                messages.append(aiMessage)
                promptManager.usePrompt()
            } catch {
                let errorMessage = Message(
                    text: "Error: \(error.localizedDescription)",
                    isUser: false,
                    timestamp: Date()
                )
                messages.append(errorMessage)
            }
            isLoading = false
        }
    }
    
    private func purchasePrompts() async {
        guard let product = storeKit.products.first else { return }
        
        do {
            let transaction = try await storeKit.purchase(product)
            if transaction != nil {
                promptManager.addPurchasedPrompts()
            }
        } catch {
            print("Purchase failed: \(error)")
        }
    }
    
    private func loadMessages() {
        if let data = UserDefaults.standard.data(forKey: "chatMessages"),
           let decodedMessages = try? JSONDecoder().decode([Message].self, from: data) {
            messages = decodedMessages
        }
    }
    
    private func saveMessages() {
        if let encoded = try? JSONEncoder().encode(messages) {
            UserDefaults.standard.set(encoded, forKey: "chatMessages")
        }
    }
}

struct MessageBubble: View {
    let message: Message
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding()
                    .glass(
                        radius: 12,
                        color: message.isUser ? .blue : (colorScheme == .dark ? .white : .black),
                        material: .regularMaterial,
                        gradientOpacity: message.isUser ? 0.7 : 0.5
                    )
                    .foregroundColor(message.isUser ? .white : (colorScheme == .dark ? .white : .black))
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
            }
            
            if !message.isUser {
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}

struct LoadingIndicator: View {
    var body: some View {
        HStack {
            Spacer()
            ProgressView()
                .frame(width: 44, height: 44)
            Spacer()
        }
        .padding()
    }
}

struct InputArea: View {
    @Binding var text: String
    let isLoading: Bool
    let onSend: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("Type your message...", text: $text)
                .padding()
                .glass(radius: 20, color: colorScheme == .dark ? .white : .black, material: .regularMaterial)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .accessibilityLabel("Message input")
                .accessibilityHint("Type your message here")
            
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(text.isEmpty ? .gray : (colorScheme == .dark ? .white : .black))
            }
            .disabled(text.isEmpty || isLoading)
            .glass(radius: 12, color: text.isEmpty ? .gray : .blue, material: .regularMaterial, gradientOpacity: 0.7)
            .accessibilityLabel("Send message")
            .accessibilityHint("Tap to send your message")
        }
        .padding()
    }
}

struct Message: Identifiable {
    var id = UUID()
    let text: String
    let isUser: Bool
    let timestamp: Date
}

struct MessageView: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            
            Text(message.text)
                .padding()
                .glass(
                    radius: 12,
                    color: message.isUser ? .blue : .gray,
                    material: .regularMaterial,
                    gradientOpacity: message.isUser ? 0.7 : 0.5
                )
                .foregroundColor(message.isUser ? .white : .primary)
            
            if !message.isUser { Spacer() }
        }
    }
}

extension Message: Codable {} 
