//
//  ContentView.swift
//  HTasks
//
//  Created by Apple on 2025. 03. 29..
//

import SwiftUI
import CoreData

struct Chore: Identifiable, Codable {
    var id: UUID
    var title: String
    var isCompleted = false
    var dueDate: Date?  // Add due date property
    
    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, dueDate: Date? = nil) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.dueDate = dueDate
    }
}

struct UserSettings: Codable {
    var showDeleteConfirmation: Bool = true
    var deleteConfirmationText: String = "We offer no liability if your mother gets mad :P"
}

struct ContentView: View {
    @State private var isWelcomeActive = true
    @State private var chores: [Chore] = []
    @Environment(\.colorScheme) var colorScheme
    
    // Load saved chores when the view appears
    var body: some View {
        NavigationView {
            if isWelcomeActive {
                WelcomeView(chores: $chores, isWelcomeActive: $isWelcomeActive)
            } else {
                HomeView(chores: $chores)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            loadChores()
            
            // Check if we should skip welcome screen
            let hasSeenWelcome = UserDefaults.standard.bool(forKey: "hasSeenWelcome")
            if hasSeenWelcome && !chores.isEmpty {
                isWelcomeActive = false
            }
        }
    }
    
    private func loadChores() {
        if let savedChores = UserDefaults.standard.data(forKey: "savedChores") {
            do {
                let decodedChores = try JSONDecoder().decode([Chore].self, from: savedChores)
                self.chores = decodedChores
                
                // Log for debugging
                print("Loaded \(decodedChores.count) chores from UserDefaults")
            } catch {
                print("Failed to decode chores: \(error.localizedDescription)")
            }
        } else {
            print("No saved chores found in UserDefaults")
        }
    }
}

struct WelcomeView: View {
    @Binding var chores: [Chore]
    @Binding var isWelcomeActive: Bool
    @State private var newChore: String = ""
    @Environment(\.colorScheme) var colorScheme
    
    let presetChores = [
        "Wash the dishes",
        "Clean the Windows",
        "Mop the Floor",
        "Clean your room"
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to HTasks!")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            Text("Get Motivated.")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
            
            // Chore input field with modern styling
            TextField("Type your own task", text: $newChore)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.8))
                )
                .padding(.horizontal)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            Button(action: {
                if !newChore.isEmpty {
                    addChore(newChore)
                    newChore = ""
                }
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Task")
                }
                .fontWeight(.semibold)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? Color.blue.opacity(0.7) : Color.blue)
                )
                .foregroundColor(colorScheme == .dark ? .white : .black)
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Presets:")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .padding(.leading)
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(presetChores, id: \.self) { preset in
                            Button(action: {
                                addChore(preset)
                            }) {
                                HStack {
                                    Text(preset)
                                        .font(.headline)
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.8))
                                        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.1) : Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                )
                                .padding(EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4))
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            if !chores.isEmpty {
                Button(action: {
                    isWelcomeActive = false
                    // Mark that user has seen welcome screen
                    UserDefaults.standard.set(true, forKey: "hasSeenWelcome")
                    UserDefaults.standard.synchronize()
                }) {
                    HStack {
                        Text("Continue")
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .fontWeight(.semibold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color.green.opacity(0.7) : Color.green)
                    )
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .navigationBarHidden(true)
        .padding()
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
    
    private func addChore(_ title: String) {
        let newChore = Chore(title: title)
        chores.append(newChore)
        saveChores()
    }
    
    private func saveChores() {
        do {
            let encoded = try JSONEncoder().encode(chores)
            UserDefaults.standard.set(encoded, forKey: "savedChores")
            UserDefaults.standard.synchronize()
            print("Successfully saved \(chores.count) chores from WelcomeView")
        } catch {
            print("Failed to encode chores: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(CoreDataManager.shared)
}
