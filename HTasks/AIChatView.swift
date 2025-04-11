import SwiftUI

struct AIChatView: View {
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isLoading = false
    @State private var showingPromptsView = false
    
    var body: some View {
        VStack {
            // Header with remaining prompts
            HStack {
                Text("HTasksAI")
                    .font(.title)
                    .bold()
                
                Spacer()
                
                Button(action: {
                    showingPromptsView = true
                }) {
                    HStack {
                        Image(systemName: "message.badge.filled.fill")
                        Text("\(SecureStorageManager.shared.getRemainingMessages())")
                    }
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            .padding()
            
            // Chat messages
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { message in
                        ChatBubble(message: message)
                    }
                }
                .padding()
            }
            
            // Input area
            HStack {
                TextField("Message HTasksAI...", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(isLoading)
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .disabled(inputText.isEmpty || isLoading)
            }
            .padding()
        }
        .sheet(isPresented: $showingPromptsView) {
            PromptsView()
        }
    }
    
    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        
        let userMessage = ChatMessage(text: inputText, isUser: true)
        messages.append(userMessage)
        
        isLoading = true
        inputText = ""
        
        Task {
            do {
                let response = try await GeminiAPIManager.shared.sendRequest(prompt: userMessage.text)
                let aiMessage = ChatMessage(text: response, isUser: false)
                
                await MainActor.run {
                    messages.append(aiMessage)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    let errorMessage = ChatMessage(text: "Sorry, I couldn't process your request. Please try again.", isUser: false)
                    messages.append(errorMessage)
                    isLoading = false
                }
            }
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            Text(message.text)
                .padding()
                .background(message.isUser ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(message.isUser ? .white : .primary)
                .cornerRadius(15)
            
            if !message.isUser {
                Spacer()
            }
        }
    }
} 