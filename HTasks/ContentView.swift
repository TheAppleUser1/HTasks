//
//  ContentView.swift
//  HTasks
//
//  Created by Apple on 2025. 03. 29..
//

import SwiftUI
import UserNotifications

enum TaskPriority: String, CaseIterable, Codable {
    case easy = "Low"
    case medium = "Medium"
    case difficult = "High"
    
    var color: Color {
        switch self {
        case .easy: return .green
        case .medium: return .orange
        case .difficult: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .easy: return "circle.fill"
        case .medium: return "circle.fill"
        case .difficult: return "circle.fill"
        }
    }
}

enum TaskCategory: String, CaseIterable, Codable {
    case personal = "Personal"
    case work = "Work"
    case shopping = "Shopping"
    case health = "Health"
    case education = "Education"
    case social = "Social"
    
    var icon: String {
        switch self {
        case .personal: return "person.fill"
        case .work: return "briefcase.fill"
        case .shopping: return "cart.fill"
        case .health: return "heart.fill"
        case .education: return "book.fill"
        case .social: return "person.2.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .personal: return .blue
        case .work: return .orange
        case .shopping: return .green
        case .health: return .red
        case .education: return .purple
        case .social: return .pink
        }
    }
}

enum AchievementType: String, Codable, CaseIterable {
    case firstTask = "first_task"
    case streak3 = "streak_3"
    case streak7 = "streak_7"
    case taskMaster = "task_master"
    case weekendWarrior = "weekend_warrior"
    case balancedLife = "balanced_life"
    
    var title: String {
        switch self {
        case .firstTask: return "Getting Started"
        case .streak3: return "On a Roll"
        case .streak7: return "Consistency Master"
        case .taskMaster: return "Task Master"
        case .weekendWarrior: return "Weekend Warrior"
        case .balancedLife: return "Balanced Life"
        }
    }
    
    var description: String {
        switch self {
        case .firstTask: return "Complete your first task"
        case .streak3: return "Maintain a 3-day streak"
        case .streak7: return "Maintain a 7-day streak"
        case .taskMaster: return "Complete 10 tasks"
        case .weekendWarrior: return "Complete 5 tasks in a week"
        case .balancedLife: return "Complete tasks in 3 different categories"
        }
    }
    
    var icon: String {
        switch self {
        case .firstTask: return "star.fill"
        case .streak3, .streak7: return "flame.fill"
        case .taskMaster: return "checkmark.circle.fill"
        case .weekendWarrior: return "calendar.badge.clock"
        case .balancedLife: return "scalemass.fill"
        }
    }
    
    func isUnlocked(stats: TaskStats) -> Bool {
        switch self {
        case .firstTask:
            return stats.totalTasksCompleted >= 1
        case .streak3:
            return stats.currentStreak >= 3
        case .streak7:
            return stats.currentStreak >= 7
        case .taskMaster:
            return stats.totalTasksCompleted >= 10
        case .weekendWarrior:
            return stats.tasksCompletedThisWeek >= 5
        case .balancedLife:
            return stats.completedByCategory.count >= 3
        }
    }
    
    func progress(stats: TaskStats) -> (current: Int, total: Int) {
        switch self {
        case .firstTask:
            return (min(stats.totalTasksCompleted, 1), 1)
        case .streak3:
            return (min(stats.currentStreak, 3), 3)
        case .streak7:
            return (min(stats.currentStreak, 7), 7)
        case .taskMaster:
            return (min(stats.totalTasksCompleted, 10), 10)
        case .weekendWarrior:
            return (min(stats.tasksCompletedThisWeek, 5), 5)
        case .balancedLife:
            return (min(stats.completedByCategory.count, 3), 3)
        }
    }
    
    var showsProgress: Bool {
        switch self {
        case .firstTask:
            return false
        default:
            return true
        }
    }
}

struct Achievement: Identifiable, Codable {
    let id: AchievementType
    var isUnlocked: Bool
    
    var title: String { id.title }
    var description: String { id.description }
    var icon: String { id.icon }
    
    static let allAchievements: [Achievement] = AchievementType.allCases.map { type in
        Achievement(id: type, isUnlocked: false)
    }
}

struct TaskStats: Codable {
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var totalTasksCompleted: Int = 0
    var tasksCompletedToday: Int = 0
    var tasksCompletedThisWeek: Int = 0
    var completedByCategory: [TaskCategory: Int] = [:]
    var completedByPriority: [TaskPriority: Int] = [:]
    var lastCompletionDate: Date?
    var achievements: [Achievement] = Achievement.allAchievements
    
    mutating func updateStats(for tasks: [Task]) {
        // Reset daily and weekly stats
        let calendar = Calendar.current
        let now = Date()
        
        // Update total completed
        totalTasksCompleted = tasks.filter { $0.isCompleted }.count
        
        // Update today's completed tasks
        tasksCompletedToday = tasks.filter { task in
            guard task.isCompleted else { return false }
            return calendar.isDate(task.completionDate ?? now, inSameDayAs: now)
        }.count
        
        // Update this week's completed tasks
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        tasksCompletedThisWeek = tasks.filter { task in
            guard task.isCompleted else { return false }
            return calendar.isDate(task.completionDate ?? now, inSameDayAs: startOfWeek)
        }.count
        
        // Update category stats
        completedByCategory.removeAll()
        for task in tasks where task.isCompleted {
            completedByCategory[task.category, default: 0] += 1
        }
        
        // Update priority stats
        completedByPriority.removeAll()
        for task in tasks where task.isCompleted {
            completedByPriority[task.priority, default: 0] += 1
        }
        
        // Update streak
        if let lastDate = lastCompletionDate {
            if calendar.isDate(lastDate, inSameDayAs: now) {
                // Same day, streak continues
            } else if calendar.isDate(lastDate, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: now)!) {
                // Yesterday, streak continues
                currentStreak += 1
            } else {
                // Streak broken
                currentStreak = tasksCompletedToday > 0 ? 1 : 0
            }
        } else if tasksCompletedToday > 0 {
            // First completion
            currentStreak = 1
        }
        
        // Update longest streak
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }
        
        // Update last completion date if there are completed tasks today
        if tasksCompletedToday > 0 {
            lastCompletionDate = now
        }
        
        // Check and update achievements
        for i in 0..<achievements.count {
            let wasUnlocked = achievements[i].isUnlocked
            achievements[i].isUnlocked = achievements[i].id.isUnlocked(stats: self)
            if !wasUnlocked && achievements[i].isUnlocked {
                print("Achievement \(achievements[i].title) is now unlocked") // Debug print
            }
        }
    }
}

struct Task: Identifiable, Codable {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var dueDate: Date?
    var completionDate: Date?
    var category: TaskCategory
    var priority: TaskPriority
    var lastModified: Date
    
    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, dueDate: Date? = nil, completionDate: Date? = nil, category: TaskCategory = .personal, priority: TaskPriority = .medium) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.completionDate = completionDate
        self.category = category
        self.priority = priority
        self.lastModified = Date()
    }
}

struct UserSettings: Codable {
    var name: String
    var streak: Int
    var totalTasksCompleted: Int
    var lastLoginDate: Date
    var notificationsEnabled: Bool
    var theme: String
    var taskCategories: [TaskCategory]
    var showDeleteConfirmation: Bool
    var deleteConfirmationText: String
    var stats: TaskStats
    
    static var defaultSettings: UserSettings {
        UserSettings(
            name: "User",
            streak: 0,
            totalTasksCompleted: 0,
            lastLoginDate: Date(),
            notificationsEnabled: true,
            theme: "system",
            taskCategories: [
                .personal,
                .work,
                .shopping,
                .health
            ],
            showDeleteConfirmation: true,
            deleteConfirmationText: "Are you sure you want to delete this task?",
            stats: TaskStats()
        )
    }
}

struct ContentView: View {
    @State private var isWelcomeActive = true
    @State private var tasks: [Task] = []
    @Environment(\.colorScheme) var colorScheme
    @State private var dataVersion = 1
    
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
        .onChange(of: tasks) { _, newTasks in
            saveTasks(newTasks)
        }
    }
    
    private func loadTasks() {
        // Check data version
        let savedVersion = UserDefaults.standard.integer(forKey: "dataVersion")
        if savedVersion < dataVersion {
            // Handle data migration if needed
            migrateData(from: savedVersion)
        }
        
        if let savedTasks = UserDefaults.standard.data(forKey: "savedTasks") {
            do {
                let decodedTasks = try JSONDecoder().decode([Task].self, from: savedTasks)
                
                // Remove duplicates based on title and category
                var uniqueTasks: [Task] = []
                for task in decodedTasks {
                    if !uniqueTasks.contains(where: { $0.title == task.title && $0.category == task.category }) {
                        uniqueTasks.append(task)
                    }
                }
                
                self.tasks = uniqueTasks
                print("Loaded \(uniqueTasks.count) tasks from UserDefaults")
            } catch {
                print("Failed to decode tasks: \(error.localizedDescription)")
                // Attempt to recover by loading backup if available
                if let backupData = UserDefaults.standard.data(forKey: "savedTasks_backup") {
                    do {
                        let backupTasks = try JSONDecoder().decode([Task].self, from: backupData)
                        self.tasks = backupTasks
                        print("Recovered \(backupTasks.count) tasks from backup")
                    } catch {
                        print("Failed to recover from backup: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            print("No saved tasks found in UserDefaults")
        }
    }
    
    private func saveTasks(_ tasks: [Task]) {
        do {
            // Create backup before saving
            if let currentData = UserDefaults.standard.data(forKey: "savedTasks") {
                UserDefaults.standard.set(currentData, forKey: "savedTasks_backup")
            }
            
            let encoded = try JSONEncoder().encode(tasks)
            UserDefaults.standard.set(encoded, forKey: "savedTasks")
            UserDefaults.standard.set(dataVersion, forKey: "dataVersion")
            UserDefaults.standard.synchronize()
            print("Successfully saved \(tasks.count) tasks")
        } catch {
            print("Failed to encode tasks: \(error.localizedDescription)")
        }
    }
    
    private func migrateData(from version: Int) {
        // Handle data migration between versions
        if version < 1 {
            // Migration logic for version 1
            if let oldData = UserDefaults.standard.data(forKey: "savedTasks") {
                do {
                    let oldTasks = try JSONDecoder().decode([Task].self, from: oldData)
                    var migratedTasks: [Task] = []
                    for task in oldTasks {
                        var migratedTask = task
                        migratedTask.lastModified = Date()
                        migratedTasks.append(migratedTask)
                    }
                    let encoded = try JSONEncoder().encode(migratedTasks)
                    UserDefaults.standard.set(encoded, forKey: "savedTasks")
                } catch {
                    print("Failed to migrate data: \(error.localizedDescription)")
                }
            }
        }
        UserDefaults.standard.set(dataVersion, forKey: "dataVersion")
    }
}

struct WelcomeView: View {
    @Binding var tasks: [Task]
    @Binding var isWelcomeActive: Bool
    @State private var newTaskTitle: String = ""
    @State private var dueDate: Date = Date()
    @State private var showDatePicker = false
    @State private var settings = UserSettings.defaultSettings
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedPriority: TaskPriority = .easy
    @State private var selectedCategory: TaskCategory = .personal
    
    let presetTasks = [
        "Wash the dishes",
        "Clean the Windows",
        "Mop the Floor",
        "Clean your room"
    ]
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Text("Welcome to HTasks!")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                Text("Get Motivated")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                
                TextField("Type your own task", text: $newTaskTitle)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.8))
                    )
                    .padding(.horizontal)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                HStack {
                    Text("Priority")
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    Picker("Priority", selection: $selectedPriority) {
                        ForEach([TaskPriority.easy, .medium, .difficult], id: \.self) { priority in
                            HStack {
                                Circle()
                                    .fill(priority.color)
                                    .frame(width: 10, height: 10)
                                Text(priority.rawValue)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding(.horizontal)
                
                HStack {
                    Text("Category")
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(TaskCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                .padding(.horizontal)
                
                Toggle("Add due date", isOn: $showDatePicker)
                    .padding(.horizontal)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                if showDatePicker {
                    DatePicker("Due Date & Time", selection: $dueDate, in: Date()...)
                        .datePickerStyle(.compact)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.8))
                        )
                        .padding(.horizontal)
                }
                
                Button(action: {
                    if !newTaskTitle.isEmpty {
                        addTask(newTaskTitle, withDate: showDatePicker)
                        newTaskTitle = ""
                        showDatePicker = false
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
        .onAppear {
            loadSettings()
        }
    }
    
    private func loadSettings() {
        if let savedSettings = UserDefaults.standard.data(forKey: "userSettings") {
            if let decodedSettings = try? JSONDecoder().decode(UserSettings.self, from: savedSettings) {
                self.settings = decodedSettings
            } else {
                self.settings = UserSettings.defaultSettings
                saveSettings()
            }
        } else {
            self.settings = UserSettings.defaultSettings
            saveSettings()
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
    
    private func addTask(_ title: String, withDate: Bool = false) {
        let newTask = Task(
            title: title,
            dueDate: withDate ? dueDate : nil,
            completionDate: withDate ? Date() : nil,
            category: selectedCategory,
            priority: selectedPriority
        )
        tasks.append(newTask)
        saveTasks(tasks)
        
        if withDate {
            scheduleNotification(for: newTask)
        }
        
        selectedPriority = .easy
        selectedCategory = .personal
    }
    
    private func scheduleNotification(for task: Task) {
        guard let dueDate = task.dueDate else { return }
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                let content = UNMutableNotificationContent()
                content.title = "Task Due: \(task.title)"
                content.body = "Your task is due today!"
                content.sound = .default
                
                let calendar = Calendar.current
                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                
                let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request)
                
                let reminderDate = calendar.date(byAdding: .day, value: -1, to: dueDate)!
                let reminderComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
                let reminderTrigger = UNCalendarNotificationTrigger(dateMatching: reminderComponents, repeats: false)
                
                let reminderContent = UNMutableNotificationContent()
                reminderContent.title = "Task Reminder: \(task.title)"
                reminderContent.body = "Your task is due tomorrow!"
                reminderContent.sound = .default
                
                let reminderRequest = UNNotificationRequest(identifier: "\(task.id.uuidString)-reminder", content: reminderContent, trigger: reminderTrigger)
                UNUserNotificationCenter.current().add(reminderRequest)
            }
        }
    }
}

struct HomeView: View {
    @Binding var tasks: [Task]
    @State private var taskToDelete: Task?
    @State private var showingDeleteAlert = false
    @State private var showingAddTaskSheet = false
    @State private var showingSettingsSheet = false
    @State private var showingAchievementsSheet = false
    @State private var showingStatisticsSheet = false
    @State private var newTaskTitle = ""
    @State private var newTaskDueDate: Date = Date()
    @State private var showDatePicker = false
    @State private var settings = UserSettings.defaultSettings
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedPriority: TaskPriority = .easy
    @State private var selectedCategory: TaskCategory = .personal
    
    var completedTasksCount: Int {
        tasks.filter { $0.isCompleted }.count
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
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
                
                List {
                    ForEach(tasks) { task in
                        HStack(spacing: 12) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(task.priority.color)
                                    .frame(width: 8, height: 8)
                                
                                Image(systemName: task.category.icon)
                                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                                    .font(.subheadline)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.title)
                                    .font(.headline)
                                    .foregroundColor(
                                        task.isCompleted ?
                                        (colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.5)) :
                                        (colorScheme == .dark ? .white : .black)
                                    )
                                    .strikethrough(task.isCompleted)
                                
                                if let dueDate = task.dueDate {
                                    Text(dueDate, style: .time)
                                        .font(.caption)
                                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                                }
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 8) {
                                Button(action: {
                                    toggleTaskCompletion(task)
                                }) {
                                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .font(.title2)
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                
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
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
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
            
            VStack {
                Spacer()
                HStack {
                    Button(action: {
                        showingStatisticsSheet = true
                    }) {
                        Image(systemName: "chart.bar.fill")
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
                    .padding(.leading, 20)
                    .padding(.bottom, 20)
                    
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
        .navigationBarItems(trailing: HStack(spacing: 16) {
            Button(action: {
                showingAchievementsSheet = true
            }) {
                Image(systemName: "trophy.fill")
                    .font(.title2)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .padding(8)
                    .contentShape(Rectangle())
            }
            
            Button(action: {
                showingSettingsSheet = true
            }) {
                Image(systemName: "gear")
                    .font(.title2)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .padding(8)
                    .contentShape(Rectangle())
            }
        })
        .sheet(isPresented: $showingAddTaskSheet) {
            VStack(spacing: 16) {
                Text("Add New Task")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .padding(.top, 20)
                
                VStack(spacing: 16) {
                    TextField("Task name", text: $newTaskTitle)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.8))
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        )
                        .padding(.horizontal)
                    
                    HStack {
                        Text("Priority")
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        Picker("Priority", selection: $selectedPriority) {
                            ForEach([TaskPriority.easy, .medium, .difficult], id: \.self) { priority in
                                HStack {
                                    Circle()
                                        .fill(priority.color)
                                        .frame(width: 10, height: 10)
                                    Text(priority.rawValue)
                                }
                                .tag(priority)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        Text("Category")
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(TaskCategory.allCases, id: \.self) { category in
                                HStack {
                                    Image(systemName: category.icon)
                                    Text(category.rawValue)
                                }
                                .tag(category)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    .padding(.horizontal)
                    
                    Toggle("Add due date", isOn: $showDatePicker)
                        .padding(.horizontal)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    if showDatePicker {
                        DatePicker("Due Date & Time", selection: $newTaskDueDate, in: Date()...)
                            .datePickerStyle(.compact)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.8))
                            )
                            .padding(.horizontal)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
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
                            addTask(newTaskTitle, withDate: showDatePicker)
                            newTaskTitle = ""
                            showDatePicker = false
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
                .padding()
            }
            .background(
                colorScheme == .dark ? Color.black : Color.white
            )
            .presentationDetents([.height(showDatePicker ? 500 : 400)])
        }
        .sheet(isPresented: $showingSettingsSheet) {
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
        .sheet(isPresented: $showingAchievementsSheet) {
            VStack(spacing: 24) {
                Text("Achievements")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .padding(.top, 20)
                
                List {
                    ForEach(settings.stats.achievements) { achievement in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 16) {
                                Image(systemName: achievement.icon)
                                    .font(.title2)
                                    .foregroundColor(achievement.isUnlocked ? .yellow : .gray)
                                    .frame(width: 40)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(achievement.title)
                                            .font(.headline)
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                        
                                        if achievement.isUnlocked {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                        }
                                    }
                                    
                                    Text(achievement.description)
                                        .font(.subheadline)
                                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                                }
                                
                                Spacer()
                            }
                            
                            if achievement.id.showsProgress && !achievement.isUnlocked {
                                let progress = achievement.id.progress(stats: settings.stats)
                                ProgressView(value: Double(progress.current), total: Double(progress.total))
                                    .tint(achievement.isUnlocked ? .green : .blue)
                                    .padding(.leading, 56)
                                
                                Text("\(progress.current)/\(progress.total)")
                                    .font(.caption)
                                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                                    .padding(.leading, 56)
                            }
                        }
                        .padding(.vertical, 8)
                        .opacity(achievement.isUnlocked ? 1.0 : 0.6)
                    }
                }
                .listStyle(PlainListStyle())
                
                Button(action: {
                    showingAchievementsSheet = false
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
        .sheet(isPresented: $showingStatisticsSheet) {
            StatisticsView()
        }
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
        .onAppear {
            loadSettings()
        }
    }
    
    private func toggleTaskCompletion(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            var updatedTask = tasks[index]
            updatedTask.isCompleted.toggle()
            updatedTask.completionDate = updatedTask.isCompleted ? Date() : nil
            updatedTask.lastModified = Date()
            tasks[index] = updatedTask
            
            if updatedTask.isCompleted {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])
            } else if let dueDate = task.dueDate {
                scheduleNotification(for: task, at: dueDate)
            }
            
            // Update stats and achievements
            let previousAchievements = settings.stats.achievements
            settings.stats.updateStats(for: tasks)
            
            // Check for newly completed achievements
            for (index, achievement) in settings.stats.achievements.enumerated() {
                if achievement.isUnlocked && !previousAchievements[index].isUnlocked {
                    print("Achievement unlocked: \(achievement.title)")
                    sendAchievementNotification(for: achievement)
                    break
                }
            }
            
            saveSettings()
        }
    }
    
    private func sendAchievementNotification(for achievement: Achievement) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                let content = UNMutableNotificationContent()
                content.title = "🎉 Achievement Unlocked!"
                content.body = "\(achievement.title): \(achievement.description)"
                content.sound = .default
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
                let request = UNNotificationRequest(identifier: "achievement-\(achievement.id.rawValue)", content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request)
            }
        }
    }
    
    private func addTask(_ title: String, withDate: Bool = false) {
        let newTask = Task(
            title: title,
            dueDate: withDate ? newTaskDueDate : nil,
            completionDate: withDate ? Date() : nil,
            category: selectedCategory,
            priority: selectedPriority
        )
        
        // Check for duplicate tasks based on title and category
        if !tasks.contains(where: { $0.title == newTask.title && $0.category == newTask.category }) {
            tasks.append(newTask)
            
            if withDate {
                scheduleNotification(for: newTask, at: newTaskDueDate)
            }
            
            selectedPriority = .easy
            selectedCategory = .personal
        }
    }
    
    private func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])
    }
    
    private func loadSettings() {
        if let savedSettings = UserDefaults.standard.data(forKey: "userSettings") {
            if let decodedSettings = try? JSONDecoder().decode(UserSettings.self, from: savedSettings) {
                self.settings = decodedSettings
            } else {
                self.settings = UserSettings.defaultSettings
                saveSettings()
            }
        } else {
            self.settings = UserSettings.defaultSettings
            saveSettings()
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
    
    private func scheduleNotification(for task: Task, at date: Date) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                let content = UNMutableNotificationContent()
                content.title = "Task Due: \(task.title)"
                content.body = "Your task is due today!"
                content.sound = .default
                
                let calendar = Calendar.current
                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                
                let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request)
                
                let reminderDate = calendar.date(byAdding: .day, value: -1, to: date)!
                let reminderComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
                let reminderTrigger = UNCalendarNotificationTrigger(dateMatching: reminderComponents, repeats: false)
                
                let reminderContent = UNMutableNotificationContent()
                reminderContent.title = "Task Reminder: \(task.title)"
                reminderContent.body = "Your task is due tomorrow!"
                reminderContent.sound = .default
                
                let reminderRequest = UNNotificationRequest(identifier: "\(task.id.uuidString)-reminder", content: reminderContent, trigger: reminderTrigger)
                UNUserNotificationCenter.current().add(reminderRequest)
            }
        }
    }
}

struct StatisticsView: View {
    @State private var settings = UserSettings.defaultSettings
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTimeRange: TimeRange = .week
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        case all = "All Time"
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Statistics")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .padding(.top, 20)
            
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Streak Statistics
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Streak Stats")
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                        HStack(spacing: 20) {
                            StatCard(
                                title: "Current Streak",
                                value: "\(settings.stats.currentStreak)",
                                icon: "flame.fill",
                                color: .orange
                            )
                            
                            StatCard(
                                title: "Longest Streak",
                                value: "\(settings.stats.longestStreak)",
                                icon: "trophy.fill",
                                color: .yellow
                            )
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.8))
                    )
                    
                    // Task Completion Stats
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Task Completion")
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        
                        HStack(spacing: 20) {
                            StatCard(
                                title: "Total Tasks",
                                value: "\(settings.stats.totalTasksCompleted)",
                                icon: "checkmark.circle.fill",
                                color: .green
                            )
                            
                            StatCard(
                                title: "Today",
                                value: "\(settings.stats.tasksCompletedToday)",
                                icon: "calendar",
                                color: .blue
                            )
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.8))
                    )
                    
                    // Category Distribution
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Category Distribution")
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        
                        ForEach(TaskCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(category.color)
                                Text(category.rawValue)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                Spacer()
                                Text("\(settings.stats.completedByCategory[category] ?? 0)")
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.8))
                    )
                    
                    // Priority Distribution
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Priority Distribution")
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            HStack {
                                Circle()
                                    .fill(priority.color)
                                    .frame(width: 10, height: 10)
                                Text(priority.rawValue)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                Spacer()
                                Text("\(settings.stats.completedByPriority[priority] ?? 0)")
                                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.8))
                    )
                }
                .padding()
            }
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
        .onAppear {
            loadSettings()
        }
    }
    
    private func loadSettings() {
        if let savedSettings = UserDefaults.standard.data(forKey: "userSettings") {
            if let decodedSettings = try? JSONDecoder().decode(UserSettings.self, from: savedSettings) {
                self.settings = decodedSettings
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
            }
            
            Text(value)
                    .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            }
        .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.gray.opacity(0.1) : Color.white.opacity(0.5))
            )
    }
}

#Preview {
    ContentView()
}
