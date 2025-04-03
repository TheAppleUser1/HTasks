//
//  ContentView.swift
//  HTasks
//
//  Created by Apple on 2025. 03. 29..
//

import SwiftUI

struct Task: Identifiable, Codable {
    var id: UUID
    var title: String
    var isCompleted = false
    
    init(id: UUID = UUID(), title: String, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }
}

struct UserSettings: Codable {
    var showDeleteConfirmation: Bool = true
    var deleteConfirmationText: String = "We offer no liability if your mother gets mad :P"
}

struct ContentView: View {
    @State private var isWelcomeActive = true
    @State private var tasks: [Task] = []
    @Environment(\.colorScheme) var colorScheme
    
    // Load saved tasks when the view appears
    var body: some View {
        NavigationView {
            if isWelcomeActive {
                WelcomeView(tasks: $tasks, isWelcomeActive: $isWelcomeActive)
            } else {
                HomeView(tasks: $tasks)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            loadTasks()
            
            // Check if we should skip welcome screen
            let hasSeenWelcome = UserDefaults.standard.bool(forKey: "hasSeenWelcome")
            if hasSeenWelcome && !tasks.isEmpty {
                isWelcomeActive = false
            }
        }
    }
    
    private func loadTasks() {
        if let savedTasks = UserDefaults.standard.data(forKey: "savedTasks") {
            do {
                let decodedTasks = try JSONDecoder().decode([Task].self, from: savedTasks)
                self.tasks = decodedTasks
                
                // Log for debugging
                print("Loaded \(decodedTasks.count) tasks from UserDefaults")
            } catch {
                print("Failed to decode tasks: \(error.localizedDescription)")
            }
        } else {
            print("No saved tasks found in UserDefaults")
        }
    }
}

struct WelcomeView: View {
    @Binding var tasks: [Task]
    @Binding var isWelcomeActive: Bool
    @State private var newTask: String = ""
    @Environment(\.colorScheme) var colorScheme
    
    let presetTasks = [
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
            
            Text("Choose basic tasks you want to do at home and get motivated!")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
            
            // Task input field with modern styling
            TextField("Type your own task", text: $newTask)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.8))
                )
                .padding(.horizontal)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            Button(action: {
                if !newTask.isEmpty {
                    addTask(newTask)
                    newTask = ""
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
                        ForEach(presetTasks, id: \.self) { preset in
                            Button(action: {
                                addTask(preset)
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
            
            if !tasks.isEmpty {
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
    
    private func addTask(_ title: String) {
        let newTask = Task(title: title)
        tasks.append(newTask)
        saveTasks()
    }
    
    private func saveTasks() {
        do {
            let encoded = try JSONEncoder().encode(tasks)
            UserDefaults.standard.set(encoded, forKey: "savedTasks")
            UserDefaults.standard.synchronize()
            print("Successfully saved \(tasks.count) tasks from WelcomeView")
        } catch {
            print("Failed to encode tasks: \(error.localizedDescription)")
        }
    }
}

struct HomeView: View {
    @Binding var tasks: [Task]
    @State private var taskToDelete: Task?
    @State private var showingDeleteAlert = false
    @State private var showingAddTaskSheet = false
    @State private var showingSettingsSheet = false
    @State private var newTaskTitle = ""
    @State private var settings = UserSettings()
    @Environment(\.colorScheme) var colorScheme
    
    var completedTasksCount: Int {
        tasks.filter { $0.isCompleted }.count
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // VisionOS style header with completed tasks count
                VStack(alignment: .leading, spacing: 8) {
                    Text("Number of tasks done this week:")
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                    
                    HStack(alignment: .bottom, spacing: 8) {
                        Text("\(completedTasksCount)")
                            .font(.system(size: 60, weight: .bold, design: .rounded))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        
                        if completedTasksCount == 0 {
                            Text("u lazy or sum?")
                                .font(.system(size: 12))
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6))
                                .padding(.bottom, 12)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
                )
                .padding(.horizontal)
                .padding(.top)
                
                // Task list with VisionOS-style design
                List {
                    ForEach(tasks) { task in
                        HStack {
                            Text(task.title)
                                .font(.headline)
                                .foregroundColor(
                                    task.isCompleted ? 
                                        (colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.5)) : 
                                        (colorScheme == .dark ? .white : .black)
                                )
                                .strikethrough(task.isCompleted)
                            
                            Spacer()
                            
                            // Checkmark button
                            Button(action: {
                                toggleTaskCompletion(task)
                            }) {
                                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.title2)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .padding(5)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            
                            // Delete button
                            Button(action: {
                                taskToDelete = task
                                if settings.showDeleteConfirmation {
                                    showingDeleteAlert = true
                                } else {
                                    deleteTask(task)
                                }
                            }) {
                                Image(systemName: "trash.fill")
                                    .font(.title2)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .padding(5)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                        .padding(.vertical, 8)
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.8))
                                .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                        )
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                }
                .listStyle(PlainListStyle())
                .background(Color.clear)
                .alert(isPresented: $showingDeleteAlert) {
                    Alert(
                        title: Text("Are you sure you want to delete this task?"),
                        message: Text(settings.deleteConfirmationText),
                        primaryButton: .destructive(Text("Delete").foregroundColor(colorScheme == .dark ? .white : .black)) {
                            if let taskToDelete = taskToDelete {
                                deleteTask(taskToDelete)
                            }
                        },
                        secondaryButton: .cancel(Text("No").foregroundColor(colorScheme == .dark ? .white : .black))
                    )
                }
            }
            
            // Floating add button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showingAddTaskSheet = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(colorScheme == .dark ? .black : .white)
                            .frame(width: 60, height: 60)
                            .background(
                                Circle()
                                    .fill(colorScheme == .dark ? .white : .black)
                                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                            )
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("My Tasks")
        .navigationBarItems(trailing: 
            Button(action: {
                showingSettingsSheet = true
            }) {
                Image(systemName: "gear")
                    .font(.title2)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .padding(8)
                    .contentShape(Rectangle())
            }
        )
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
        .sheet(isPresented: $showingAddTaskSheet) {
            // Add task sheet
            VStack(spacing: 20) {
                Text("Add New Task")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                TextField("Task name", text: $newTaskTitle)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.8))
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    )
                    .padding(.horizontal)
                
                HStack(spacing: 15) {
                    Button(action: {
                        showingAddTaskSheet = false
                    }) {
                        Text("Cancel")
                            .fontWeight(.medium)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(colorScheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    Button(action: {
                        if !newTaskTitle.isEmpty {
                            let newTask = Task(title: newTaskTitle)
                            tasks.append(newTask)
                            saveTasks()
                            newTaskTitle = ""
                            showingAddTaskSheet = false
                        }
                    }) {
                        Text("Add")
                            .fontWeight(.medium)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(colorScheme == .dark ? Color.blue.opacity(0.7) : Color.blue)
                            )
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 30)
            .background(
                colorScheme == .dark ? Color.black : Color.white
            )
            .presentationDetents([.height(250)])
        }
        .sheet(isPresented: $showingSettingsSheet) {
            // Settings sheet
            VStack(spacing: 24) {
                Text("Settings")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("Customization")
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    Toggle("Show Confirmation when clicking delete", isOn: $settings.showDeleteConfirmation)
                        .onChange(of: settings.showDeleteConfirmation) { _, newValue in
                            saveSettings()
                        }
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Change the Confirmation text when clicking delete")
                            .foregroundColor(settings.showDeleteConfirmation ? 
                                           (colorScheme == .dark ? .white : .black) : 
                                           (colorScheme == .dark ? .white.opacity(0.4) : .black.opacity(0.4)))
                        
                        TextField("Confirmation message", text: $settings.deleteConfirmationText)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.8))
                                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            )
                            .disabled(!settings.showDeleteConfirmation)
                            .opacity(settings.showDeleteConfirmation ? 1.0 : 0.4)
                            .onChange(of: settings.deleteConfirmationText) { _, newValue in
                                saveSettings()
                            }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button(action: {
                    showingSettingsSheet = false
                }) {
                    Text("Done")
                        .fontWeight(.medium)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(colorScheme == .dark ? Color.blue.opacity(0.7) : Color.blue)
                        )
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
                .padding()
            }
            .background(
                colorScheme == .dark ? Color.black : Color.white
            )
            .presentationDetents([.medium])
        }
        .onAppear {
            loadSettings()
        }
    }
    
    private func toggleTaskCompletion(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            saveTasks()
        }
    }
    
    private func deleteTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks.remove(at: index)
            saveTasks()
        }
    }
    
    private func saveTasks() {
        do {
            let encoded = try JSONEncoder().encode(tasks)
            UserDefaults.standard.set(encoded, forKey: "savedTasks")
            UserDefaults.standard.synchronize()
            print("Successfully saved \(tasks.count) tasks from HomeView")
        } catch {
            print("Failed to encode tasks: \(error.localizedDescription)")
        }
    }
    
    private func loadSettings() {
        if let savedSettings = UserDefaults.standard.data(forKey: "userSettings") {
            do {
                let decodedSettings = try JSONDecoder().decode(UserSettings.self, from: savedSettings)
                self.settings = decodedSettings
                print("Loaded user settings from UserDefaults")
            } catch {
                print("Failed to decode settings: \(error.localizedDescription)")
            }
        } else {
            // Use default settings already initialized
            print("No saved settings found in UserDefaults, using defaults")
        }
    }
    
    private func saveSettings() {
        do {
            let encoded = try JSONEncoder().encode(settings)
            UserDefaults.standard.set(encoded, forKey: "userSettings")
            UserDefaults.standard.synchronize()
            print("Successfully saved user settings")
        } catch {
            print("Failed to encode settings: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ContentView()
}
