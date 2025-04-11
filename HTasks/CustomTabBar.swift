import SwiftUI

struct CustomTabBar: View {
    @State private var selectedTab = 0
    @State private var showingNewTask = false
    @State private var showingAIChat = false
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                // Your existing tabs here
                Text("Tasks")
                    .tag(0)
                
                Text("Statistics")
                    .tag(1)
            }
            
            // Floating buttons
            VStack {
                Spacer()
                
                HStack {
                    // AI Chat Button
                    Button(action: {
                        showingAIChat = true
                    }) {
                        Image(systemName: "message.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                    }
                    .frame(width: 44, height: 44)
                    
                    Spacer()
                    
                    // Add Task Button
                    Button(action: {
                        showingNewTask = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.blue)
                    }
                    .frame(width: 44, height: 44)
                    
                    Spacer()
                    
                    // Statistics Button
                    Button(action: {
                        selectedTab = 1
                    }) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                    }
                    .frame(width: 44, height: 44)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(25)
                .shadow(radius: 5)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .sheet(isPresented: $showingNewTask) {
            // Your new task view here
            Text("New Task")
        }
        .sheet(isPresented: $showingAIChat) {
            AIChatView()
        }
    }
} 