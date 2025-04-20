import SwiftUI

struct ChatView: View {
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    @State private var scrollToBottom: Bool = false
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var isInputFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    struct ChatMessage: Identifiable {
        var id = UUID()
        let content: String
        let isUser: Bool
        let timestamp: Date
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Custom Top Bar
                HStack(spacing: 16) {
                    // Back Button
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                    
                    Spacer()
                    
                    // Model Info
                    VStack(spacing: 2) {
                        HStack(alignment: .center, spacing: 4) {
                            Text("HTasksAI")
                                .font(.headline)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            Text("BETA")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color(white: 0.5))
                                )
                                .offset(y: 1)
                        }
                        
                        Text("Powered by Gemini 2.0 Flash Lite, Imported from GemAI")
                            .font(.caption)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    // New Chat Button
                    Button(action: {
                        messages.removeAll()
                        saveMessages()
                    }) {
                        Image(systemName: "square.and.pencil")
                            .font(.title3)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .frame(width: 44, height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
                            )
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(
                    Rectangle()
                        .fill(colorScheme == .dark ? Color.black : Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, y: 1)
                )
                
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                            
                            if isLoading {
                                LoadingIndicator()
                            }
                        }
                        .padding(.vertical)
                    }
                    .onChange(of: messages.count) { oldValue, newValue in
                        withAnimation {
                            proxy.scrollTo(messages.last?.id, anchor: .bottom)
                        }
                    }
                }
                
                Divider()
                    .background(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
                
                InputArea(
                    text: $inputText,
                    isLoading: isLoading,
                    onSend: sendMessage
                )
                .focused($isInputFocused)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: colorScheme == .dark ? 
                                      [Color.black, Color.blue.opacity(0.2)] : 
                                      [Color.white, Color.blue.opacity(0.1)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
            )
        }
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
        guard !inputText.isEmpty && !isLoading else { return }
        guard inputText.count <= 1000 else {
            // Show error to user
            return
        }
        
        let userMessage = ChatMessage(
            content: inputText,
            isUser: true,
            timestamp: Date()
        )
        messages.append(userMessage)
        
        isLoading = true
        inputText = ""
        
        Task {
            do {
                let response = try await GeminiService.shared.sendMessage(userMessage.content)
                let aiMessage = ChatMessage(
                    content: response,
                    isUser: false,
                    timestamp: Date()
                )
                
                await MainActor.run {
                    messages.append(aiMessage)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    let errorMessage = ChatMessage(
                        content: "Sorry, I couldn't process your request. Please try again.",
                        isUser: false,
                        timestamp: Date()
                    )
                    messages.append(errorMessage)
                    isLoading = false
                }
            }
        }
    }
    
    private func loadMessages() {
        if let data = UserDefaults.standard.data(forKey: "chatMessages"),
           let decodedMessages = try? JSONDecoder().decode([ChatMessage].self, from: data) {
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
    let message: ChatView.ChatMessage
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(message.isUser ? 
                                (colorScheme == .dark ? Color.blue.opacity(0.7) : Color.blue) :
                                (colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.8))
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
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
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.8))
                )
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .accessibilityLabel("Message input")
                .accessibilityHint("Type your message here")
            
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(text.isEmpty ? .gray : (colorScheme == .dark ? .white : .black))
            }
            .disabled(text.isEmpty || isLoading)
            .accessibilityLabel("Send message")
            .accessibilityHint("Tap to send your message")
        }
        .padding()
    }
}

extension ChatView.ChatMessage: Codable {} 
