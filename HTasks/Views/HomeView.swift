import SwiftUI
import CoreData
import UserNotifications

struct HomeView: View {
    @EnvironmentObject private var coreDataManager: CoreDataManager
    @State private var showingAddTask = false
    @State private var showingEditTask = false
    @State private var showingCategoryPicker = false
    @State private var selectedTask: TaskEntity?
    @State private var selectedCategory: CategoryEntity?
    @State private var searchText = ""
    @Binding var tasks: [Chore]
    @State private var taskToDelete: Chore?
    @State private var showingDeleteAlert = false
    @State private var showingAddTaskSheet = false
    @State private var showingSettingsSheet = false
    @State private var newTaskTitle = ""
    @State private var newTaskDueDate: Date? = nil
    @State private var newTaskDueTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var settings = UserSettings()
    @Environment(\.colorScheme) var colorScheme
    
    var filteredTasks: [TaskEntity] {
        let tasks = coreDataManager.fetchTasks()
        return tasks.filter { task in
            let matchesCategory = selectedCategory == nil || task.category == selectedCategory
            let matchesSearch = searchText.isEmpty || 
                (task.title?.localizedCaseInsensitiveContains(searchText) ?? false)
            return matchesCategory && matchesSearch
        }
    }
    
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
                            
                        if completedTasksCount == 2 {
                            Text("keep going")
                                .font(.system(size: 12))
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6))
                                .padding(.bottom, 12)
                            
                        if completedTasksCount == 5
                            Text("You are great!!!")
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
                            VStack(alignment: .leading) {
                                Text(task.title)
                                    .font(.headline)
                                    .foregroundColor(
                                        task.isCompleted ? 
                                            (colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.5)) : 
                                            (colorScheme == .dark ? .white : .black)
                                    )
                                    .strikethrough(task.isCompleted)
                                
                                if let dueDate = task.dueDate {
                                    Text(dueDate, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            
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
                
                // Date picker
                DatePicker(
                    "Due Date",
                    selection: Binding(
                        get: { newTaskDueDate ?? Date() },
                        set: { newTaskDueDate = $0 }
                    ),
                    displayedComponents: [.date]
                )
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.8))
                )
                .padding(.horizontal)
                
                // Time picker
                DatePicker(
                    "Notification Time",
                    selection: $newTaskDueTime,
                    displayedComponents: [.hourAndMinute]
                )
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.8))
                )
                .padding(.horizontal)
                
                HStack(spacing: 15) {
                    Button(action: {
                        showingAddTaskSheet = false
                        newTaskDueDate = nil
                        newTaskDueTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
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
                            let newTask = Chore(title: newTaskTitle, dueDate: newTaskDueDate)
                            tasks.append(newTask)
                            if let dueDate = newTaskDueDate {
                                scheduleNotification(for: newTask)
                            }
                            saveTasks()
                            newTaskTitle = ""
                            newTaskDueDate = nil
                            newTaskDueTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
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
            .presentationDetents([.height(450)])  // Increased height to accommodate time picker
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
    
    private func toggleTaskCompletion(_ task: Chore) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            saveTasks()
        }
    }
    
    private func deleteTask(_ task: Chore) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            removeNotification(for: task)
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
    
    private func scheduleNotification(for task: Chore) {
        guard let dueDate = task.dueDate else { return }
        
        // Request notification permission if not already granted
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                let content = UNMutableNotificationContent()
                content.title = "Task Due Today"
                content.body = "Don't forget to complete: \(task.title)"
                content.sound = .default
                
                // Create date components using both date and time
                let calendar = Calendar.current
                let dateComponents = calendar.dateComponents([.year, .month, .day], from: dueDate)
                let timeComponents = calendar.dateComponents([.hour, .minute], from: newTaskDueTime)
                
                var finalComponents = DateComponents()
                finalComponents.year = dateComponents.year
                finalComponents.month = dateComponents.month
                finalComponents.day = dateComponents.day
                finalComponents.hour = timeComponents.hour
                finalComponents.minute = timeComponents.minute
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: finalComponents, repeats: false)
                let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("Error scheduling notification: \(error.localizedDescription)")
                    } else {
                        print("Successfully scheduled notification for task: \(task.title) at \(finalComponents.hour ?? 0):\(finalComponents.minute ?? 0)")
                    }
                }
            }
        }
    }
    
    private func removeNotification(for task: Chore) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])
    }
} 
