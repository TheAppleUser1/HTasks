//
//  ContentView.swift
//  HTasks
//
//  Created by Apple on 2025. 03. 29..
//

import SwiftUI
import UserNotifications
import EventKit

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
    
    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, dueDate: Date? = nil, completionDate: Date? = nil, category: TaskCategory = .personal, priority: TaskPriority = .medium) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.completionDate = completionDate
        self.category = category
        self.priority = priority
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

struct MainContent: View {
    @Binding var tasks: [Task]
    @Binding var settings: UserSettings
    @Binding var showingDeleteAlert: Bool
    @Binding var taskToDelete: Task?
    @Binding var showAchievementBanner: Bool
    @Binding var completedAchievement: Achievement?
    @Binding var showingStatisticsSheet: Bool
    @Binding var showingAddTaskSheet: Bool
    let completedTasksCount: Int
    let onToggleTask: (Task) -> Void
    let onDeleteTask: (Task) -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                TaskCompletionHeader(completedTasksCount: completedTasksCount)
                
                List {
                    ForEach(tasks) { task in
                        TaskListRow(
                            task: task,
                            onToggleCompletion: { onToggleTask(task) },
                            onDelete: {
                                taskToDelete = task
                                if settings.showDeleteConfirmation {
                                    showingDeleteAlert = true
                                } else {
                                    onDeleteTask(task)
                                }
                            }
                        )
                    }
                }
                .listStyle(PlainListStyle())
                .background(Color.clear)
            }
            
            VStack {
                Spacer()
                BottomActionButtons(
                    onStatistics: { showingStatisticsSheet = true },
                    onAddTask: { showingAddTaskSheet = true }
                )
            }
            
            if showAchievementBanner, let achievement = completedAchievement {
                VStack {
                    Spacer()
                    AchievementBanner(achievement: achievement)
                        .offset(y: showAchievementBanner ? 0 : 200)
                        .animation(.spring(), value: showAchievementBanner)
                }
            }
        }
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
        saveTasks()
        
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

struct AchievementsView: View {
    @Binding var tasks: [Task]
    @State private var settings = UserSettings.defaultSettings
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Achievements")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .padding(.top, 20)
            
            ScrollView {
                VStack(spacing: 16) {
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
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white)
                        )
                        .opacity(achievement.isUnlocked ? 1.0 : 0.6)
                    }
                }
                .padding()
            }
        }
        .background(
            colorScheme == .dark ? Color.black : Color.white
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

struct CalendarView: View {
    @Binding var tasks: [Task]
    @State private var selectedDate = Date()
    @State private var showingAddTaskSheet = false
    @State private var newTaskTitle = ""
    @State private var newTaskDueDate: Date = Date()
    @State private var selectedPriority: TaskPriority = .easy
    @State private var selectedCategory: TaskCategory = .personal
    @Environment(\.colorScheme) var colorScheme
    
    var tasksForSelectedDate: [Task] {
        tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return Calendar.current.isDate(dueDate, inSameDayAs: selectedDate)
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Calendar
            DatePicker(
                "Select Date",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white)
            )
            .padding(.horizontal)
            
            // Tasks for selected date
            VStack(alignment: .leading, spacing: 8) {
                Text("Tasks for \(selectedDate.formatted(date: .long, time: .omitted))")
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .padding(.horizontal)
                
                if tasksForSelectedDate.isEmpty {
                    Text("No tasks scheduled for this day")
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                        .padding()
                } else {
                    List {
                        ForEach(tasksForSelectedDate) { task in
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
                                
                                Button(action: {
                                    toggleTaskCompletion(task)
                                }) {
                                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .font(.title2)
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
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
                }
            }
            
            Spacer()
        }
        .navigationTitle("Calendar")
        .navigationBarItems(trailing: 
            Button(action: {
                showingAddTaskSheet = true
            }) {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }
        )
        .sheet(isPresented: $showingAddTaskSheet) {
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
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 30)
            .background(
                colorScheme == .dark ? Color.black : Color.white
            )
        }
        .onAppear {
            syncWithAppleCalendar()
        }
    }
    
    private func toggleTaskCompletion(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            if tasks[index].isCompleted {
                tasks[index].completionDate = Date()
            }
            saveTasks()
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
        saveTasks()
        addToAppleCalendar(newTask)
    }
    
    private func saveTasks() {
        do {
            let encoded = try JSONEncoder().encode(tasks)
            UserDefaults.standard.set(encoded, forKey: "savedTasks")
            UserDefaults.standard.synchronize()
        } catch {
            print("Failed to encode tasks: \(error.localizedDescription)")
        }
    }
    
    private func syncWithAppleCalendar() {
        let eventStore = EKEventStore()
        
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            loadEventsFromCalendar(eventStore)
        case .notDetermined:
            eventStore.requestAccess(to: .event) { granted, error in
                if granted {
                    loadEventsFromCalendar(eventStore)
                }
            }
        default:
            print("Calendar access denied")
        }
    }
    
    private func loadEventsFromCalendar(_ eventStore: EKEventStore) {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .month, value: -1, to: Date())!
        let endDate = calendar.date(byAdding: .month, value: 1, to: Date())!
        
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let events = eventStore.events(matching: predicate)
        
        for event in events {
            if !tasks.contains(where: { $0.title == event.title }) {
                let newTask = Task(
                    title: event.title,
                    dueDate: event.startDate,
                    category: .personal,
                    priority: .medium
                )
                tasks.append(newTask)
            }
        }
        saveTasks()
    }
    
    private func addToAppleCalendar(_ task: Task) {
        let eventStore = EKEventStore()
        
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            createEvent(eventStore, task)
        case .notDetermined:
            eventStore.requestAccess(to: .event) { granted, error in
                if granted {
                    createEvent(eventStore, task)
                }
            }
        default:
            print("Calendar access denied")
        }
    }
    
    private func createEvent(_ eventStore: EKEventStore, _ task: Task) {
        let event = EKEvent(eventStore: eventStore)
        event.title = task.title
        event.startDate = task.dueDate
        event.endDate = task.dueDate?.addingTimeInterval(3600) // 1 hour duration
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        do {
            try eventStore.save(event, span: .thisEvent)
        } catch {
            print("Failed to save event: \(error.localizedDescription)")
        }
    }
}

struct TaskInsightsView: View {
    @Binding var tasks: [Task]
    @State private var settings = UserSettings.defaultSettings
    @Environment(\.colorScheme) var colorScheme
    
    var mostProductiveDay: String {
        let calendar = Calendar.current
        let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        var dayCounts = [Int: Int]()
        
        for task in tasks where task.isCompleted {
            if let completionDate = task.completionDate {
                let weekday = calendar.component(.weekday, from: completionDate)
                dayCounts[weekday, default: 0] += 1
            }
        }
        
        if let mostProductive = dayCounts.max(by: { $0.value < $1.value }) {
            return weekdays[mostProductive.key - 1]
        }
        return "No data"
    }
    
    var mostCommonCategory: TaskCategory {
        var categoryCounts = [TaskCategory: Int]()
        for task in tasks where task.isCompleted {
            categoryCounts[task.category, default: 0] += 1
        }
        return categoryCounts.max(by: { $0.value < $1.value })?.key ?? .personal
    }
    
    var averageCompletionTime: String {
        let completedTasks = tasks.filter { $0.isCompleted && $0.dueDate != nil && $0.completionDate != nil }
        if completedTasks.isEmpty { return "No data" }
        
        let totalTime = completedTasks.reduce(0) { result, task in
            guard let dueDate = task.dueDate,
                  let completionDate = task.completionDate else { return result }
            return result + completionDate.timeIntervalSince(dueDate)
        }
        
        let averageTime = totalTime / Double(completedTasks.count)
        let hours = Int(averageTime / 3600)
        let minutes = Int((averageTime.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var recommendations: [String] {
        var recs = [String]()
        
        // Check for overdue tasks
        let overdueTasks = tasks.filter { !$0.isCompleted && $0.dueDate != nil && $0.dueDate! < Date() }
        if !overdueTasks.isEmpty {
            recs.append("You have \(overdueTasks.count) overdue task(s). Consider completing them first.")
        }
        
        // Check for task distribution
        let categoryDistribution = Dictionary(grouping: tasks.filter { !$0.isCompleted }, by: { $0.category })
        if let mostTasksCategory = categoryDistribution.max(by: { $0.value.count < $1.value.count }) {
            if mostTasksCategory.value.count > 5 {
                recs.append("You have many tasks in the \(mostTasksCategory.key.rawValue) category. Consider delegating some.")
            }
        }
        
        // Check for high priority tasks
        let highPriorityTasks = tasks.filter { !$0.isCompleted && $0.priority == .difficult }
        if !highPriorityTasks.isEmpty {
            recs.append("You have \(highPriorityTasks.count) high priority task(s). Focus on these first.")
        }
        
        // Check for completion rate
        let completionRate = Double(tasks.filter { $0.isCompleted }.count) / Double(tasks.count)
        if completionRate < 0.5 {
            recs.append("Your task completion rate is low. Try breaking tasks into smaller steps.")
        }
        
        return recs
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Productivity Patterns
                VStack(alignment: .leading, spacing: 8) {
                    Text("Productivity Patterns")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .padding(.horizontal)
                    
                    HStack {
                        StatCard(
                            title: "Most Productive Day",
                            value: mostProductiveDay,
                            icon: "calendar.badge.clock",
                            color: .blue
                        )
                        
                        StatCard(
                            title: "Most Common Category",
                            value: mostCommonCategory.rawValue,
                            icon: mostCommonCategory.icon,
                            color: mostCommonCategory.color
                        )
                    }
                    .padding(.horizontal)
                }
                
                // Task Performance
                VStack(alignment: .leading, spacing: 8) {
                    Text("Task Performance")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .padding(.horizontal)
                    
                    StatCard(
                        title: "Average Completion Time",
                        value: averageCompletionTime,
                        icon: "clock.fill",
                        color: .green
                    )
                    .padding(.horizontal)
                }
                
                // Recommendations
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommendations")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(recommendations, id: \.self) { recommendation in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.yellow)
                                    .font(.title3)
                                
                                Text(recommendation)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .font(.subheadline)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white)
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Task Insights")
        .background(
            colorScheme == .dark ? Color.black : Color.white
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

struct TaskListRow: View {
    let task: Task
    let onToggleCompletion: () -> Void
    let onDelete: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
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
                Button(action: onToggleCompletion) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .contentShape(Rectangle())
                }
                .buttonStyle(BorderlessButtonStyle())
                
                Button(action: onDelete) {
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

struct TaskCompletionHeader: View {
    let completedTasksCount: Int
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
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
    }
}

struct BottomActionButtons: View {
    let onStatistics: () -> Void
    let onAddTask: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Button(action: onStatistics) {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white)
                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                    )
            }
            .padding(.leading, 20)
            .padding(.bottom, 20)
            
            Spacer()
            
            Button(action: onAddTask) {
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

struct NavigationButtons: View {
    let onInsights: () -> Void
    let onCalendar: () -> Void
    let onAchievements: () -> Void
    let onSettings: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: onInsights) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .padding(8)
                    .contentShape(Rectangle())
            }
            
            Button(action: onCalendar) {
                Image(systemName: "calendar")
                    .font(.title2)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .padding(8)
                    .contentShape(Rectangle())
            }
            
            Button(action: onAchievements) {
                Image(systemName: "trophy.fill")
                    .font(.title2)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .padding(8)
                    .contentShape(Rectangle())
            }
            
            Button(action: onSettings) {
                Image(systemName: "gear")
                    .font(.title2)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .padding(8)
                    .contentShape(Rectangle())
            }
        }
    }
}

struct AddTaskSheet: View {
    @Binding var isPresented: Bool
    @Binding var tasks: [Task]
    @State private var newTaskTitle = ""
    @State private var newTaskDueDate: Date = Date()
    @State private var showDatePicker = false
    @State private var selectedPriority: TaskPriority = .easy
    @State private var selectedCategory: TaskCategory = .personal
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
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
            
            HStack(spacing: 15) {
                Button(action: {
                    isPresented = false
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
                        isPresented = false
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
        }
        .padding()
        .background(
            colorScheme == .dark ? Color.black : Color.white
        )
    }
    
    private func addTask(_ title: String, withDate: Bool = false) {
        let newTask = Task(
            title: title,
            dueDate: withDate ? newTaskDueDate : nil,
            completionDate: withDate ? Date() : nil,
            category: selectedCategory,
            priority: selectedPriority
        )
        tasks.append(newTask)
        saveTasks()
        
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
    
    private func saveTasks() {
        do {
            let encoded = try JSONEncoder().encode(tasks)
            UserDefaults.standard.set(encoded, forKey: "savedTasks")
            UserDefaults.standard.synchronize()
        } catch {
            print("Failed to encode tasks: \(error.localizedDescription)")
        }
    }
}

struct SettingsSheet: View {
    @Binding var isPresented: Bool
    @Binding var settings: UserSettings
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
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
                isPresented = false
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

struct HomeView: View {
    @Binding var tasks: [Task]
    @State private var taskToDelete: Task?
    @State private var showingDeleteAlert = false
    @State private var showingAddTaskSheet = false
    @State private var showingSettingsSheet = false
    @State private var showingAchievements = false
    @State private var showingInsights = false
    @State private var newTaskTitle = ""
    @State private var newTaskDueDate: Date = Date()
    @State private var showDatePicker = false
    @State private var settings = UserSettings.defaultSettings
    @State private var completedAchievement: Achievement?
    @State private var showAchievementBanner = false
    @State private var showingStatisticsSheet = false
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedPriority: TaskPriority = .easy
    @State private var selectedCategory: TaskCategory = .personal
    
    var completedTasksCount: Int {
        tasks.filter { $0.isCompleted }.count
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    TaskCompletionHeader(completedTasksCount: completedTasksCount)
                    
                    List {
                        ForEach(tasks) { task in
                            TaskListRow(
                                task: task,
                                onToggleCompletion: { toggleTaskCompletion(task) },
                                onDelete: {
                                    taskToDelete = task
                                    if settings.showDeleteConfirmation {
                                        showingDeleteAlert = true
                                    } else {
                                        deleteTask(task)
                                    }
                                }
                            )
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
                
                if showAchievementBanner, let achievement = completedAchievement {
                    VStack {
                        Spacer()
                        AchievementBanner(achievement: achievement)
                            .offset(y: showAchievementBanner ? 0 : 200)
                            .animation(.spring(), value: showAchievementBanner)
                    }
                }
            }
            .navigationTitle("My Tasks")
            .navigationBarItems(trailing:
                HStack(spacing: 16) {
                    Button(action: {
                        showingAchievements = true
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
                    .padding(.horizontal)
                }
                .padding(.top, 30)
                .background(
                    colorScheme == .dark ? Color.black : Color.white
                )
            }
            .sheet(isPresented: $showingSettingsSheet) {
                SettingsSheet(isPresented: $showingSettingsSheet, settings: $settings)
            }
            .sheet(isPresented: $showingStatisticsSheet) {
                StatisticsView(tasks: $tasks)
            }
            .navigationDestination(isPresented: $showingAchievements) {
                AchievementsView(tasks: $tasks)
            }
            .navigationDestination(isPresented: $showingInsights) {
                TaskInsightsView(tasks: $tasks)
            }
        }
        .onAppear {
            loadSettings()
        }
    }
    
    private func toggleTaskCompletion(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            
            if tasks[index].isCompleted {
                tasks[index].completionDate = Date()
                
                // Update stats
                settings.stats.updateStats(for: tasks)
                
                // Check for achievements
                for achievement in settings.stats.achievements where !achievement.isUnlocked && achievement.id.isUnlocked(stats: settings.stats) {
                    completedAchievement = achievement
                    showAchievementBanner = true
                }
                
                // Save updated stats
                saveSettings()
            }
            
            saveTasks()
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
        saveTasks()
        addToAppleCalendar(newTask)
    }
    
    private func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])
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
}

struct AchievementBanner: View {
    let achievement: Achievement
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(achievement.title) completed!")
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    Text(achievement.description)
                        .font(.subheadline)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
        }
        .padding(.horizontal, 20)
        .padding(.trailing, 80)
        .padding(.bottom, 20)
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct StatisticsView: View {
    @Binding var tasks: [Task]
    @State private var settings = UserSettings.defaultSettings
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Streak Stats
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Streak Stats")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        
                        HStack {
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
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white)
                    )
                    
                    // Task Completion Stats
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Task Completion")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        
                        HStack {
                            StatCard(
                                title: "Today",
                                value: "\(settings.stats.tasksCompletedToday)",
                                icon: "calendar",
                                color: .blue
                            )
                            
                            StatCard(
                                title: "This Week",
                                value: "\(settings.stats.tasksCompletedThisWeek)",
                                icon: "calendar.badge.clock",
                                color: .purple
                            )
                        }
                        
                        StatCard(
                            title: "Total Tasks",
                            value: "\(settings.stats.totalTasksCompleted)",
                            icon: "checkmark.circle.fill",
                            color: .green
                        )
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white)
                    )
                    
                    // Category Distribution
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category Distribution")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        
                        ForEach(TaskCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(category.color)
                                Text(category.rawValue)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                Spacer()
                                Text("\(settings.stats.completedByCategory[category, default: 0])")
                                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white)
                    )
                }
                .padding()
            }
            .navigationTitle("Statistics")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .background(
                colorScheme == .dark ? Color.black : Color.white
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
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(colorScheme == .dark ? .white : .black)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white)
        )
    }
}

struct ContentView: View {
    @State private var isWelcomeActive = true
    @State private var tasks: [Task] = []
    
    var body: some View {
        NavigationView {
            if isWelcomeActive {
                WelcomeView(isActive: $isWelcomeActive)
            } else {
                HomeView(tasks: $tasks)
            }
        }
        .onAppear {
            loadTasks()
        }
    }
    
    private func loadTasks() {
        if let savedTasks = UserDefaults.standard.data(forKey: "savedTasks") {
            do {
                tasks = try JSONDecoder().decode([Task].self, from: savedTasks)
            } catch {
                print("Failed to decode tasks: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    ContentView()
}
