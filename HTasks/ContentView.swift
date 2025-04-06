//
//  ContentView.swift
//  HTasks
//
//  Created by Apple on 2025. 03. 29..
//

import SwiftUI
import UserNotifications
import Foundation

enum TaskPriority: String, CaseIterable, Codable {
    case easy = "Easy"
    case medium = "Medium"
    case difficult = "Difficult"
    
    var color: Color {
        switch self {
        case .easy:
            return .green
        case .medium:
            return .yellow
        case .difficult:
            return .red
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
    case fitness = "Fitness"
    case social = "Social"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .personal:
            return "person.fill"
        case .work:
            return "briefcase.fill"
        case .shopping:
            return "cart.fill"
        case .health:
            return "heart.fill"
        case .education:
            return "book.fill"
        case .fitness:
            return "figure.walk"
        case .social:
            return "person.2.fill"
        case .other:
            return "ellipsis.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .personal: return .blue
        case .work: return .orange
        case .shopping: return .green
        case .health: return .red
        case .education: return .purple
        case .fitness: return .pink
        case .social: return .pink
        case .other: return .gray
        }
    }
}

enum AchievementType: String, Codable, CaseIterable {
    case firstTask = "First Task"
    case taskMaster = "Task Master"
    case streakMaster = "Streak Master"
    case categoryExpert = "Category Expert"
    case priorityPro = "Priority Pro"
    
    var title: String {
        switch self {
        case .firstTask:
            return "Getting Started"
        case .taskMaster:
            return "Task Master"
        case .streakMaster:
            return "Consistency Master"
        case .categoryExpert:
            return "Category Expert"
        case .priorityPro:
            return "Priority Pro"
        }
    }
    
    var description: String {
        switch self {
        case .firstTask:
            return "Complete your first task"
        case .taskMaster:
            return "Complete 100 tasks"
        case .streakMaster:
            return "Maintain a 7-day streak"
        case .categoryExpert:
            return "Complete 50 tasks in a single category"
        case .priorityPro:
            return "Complete 50 tasks of a single priority level"
        }
    }
    
    var icon: String {
        switch self {
        case .firstTask:
            return "checkmark.circle.fill"
        case .taskMaster:
            return "trophy.fill"
        case .streakMaster:
            return "flame.fill"
        case .categoryExpert:
            return "star.fill"
        case .priorityPro:
            return "crown.fill"
        }
    }
    
    var showsProgress: Bool {
        switch self {
        case .taskMaster, .streakMaster, .categoryExpert, .priorityPro:
            return true
        case .firstTask:
            return false
        }
    }
    
    func progress(stats: TaskStats) -> (current: Int, total: Int) {
        switch self {
        case .firstTask:
            return (stats.totalCompletedTasks > 0 ? 1 : 0, 1)
        case .taskMaster:
            return (stats.totalCompletedTasks, 100)
        case .streakMaster:
            return (stats.longestStreak, 7)
        case .categoryExpert:
            return (stats.categoryStats.values.max() ?? 0, 50)
        case .priorityPro:
            return (stats.priorityStats.values.max() ?? 0, 50)
        }
    }
}

struct Achievement: Identifiable, Codable {
    let id: AchievementType
    let title: String
    let description: String
    let icon: String
    var isCompleted: Bool
}

struct TaskStats: Codable {
    var totalTasks: Int
    var completedTasks: Int
    var totalCompletedTasks: Int { completedTasks }
    var categoryDistribution: [TaskCategory: Int]
    var priorityDistribution: [TaskPriority: Int]
    var achievements: [Achievement]
    var longestStreak: Int
    var categoryStats: [TaskCategory: Int]
    var priorityStats: [TaskPriority: Int]
    
    init(totalTasks: Int = 0,
         completedTasks: Int = 0,
         categoryDistribution: [TaskCategory: Int] = [:],
         priorityDistribution: [TaskPriority: Int] = [:],
         achievements: [Achievement] = [],
         longestStreak: Int = 0,
         categoryStats: [TaskCategory: Int] = [:],
         priorityStats: [TaskPriority: Int] = [:]) {
        self.totalTasks = totalTasks
        self.completedTasks = completedTasks
        self.categoryDistribution = categoryDistribution
        self.priorityDistribution = priorityDistribution
        self.achievements = achievements
        self.longestStreak = longestStreak
        self.categoryStats = categoryStats
        self.priorityStats = priorityStats
    }
    
    static func calculateStats(from tasks: [Task]) -> TaskStats {
        let total = tasks.count
        let completed = tasks.filter { $0.isCompleted }.count
        
        var categoryDist: [TaskCategory: Int] = [:]
        var priorityDist: [TaskPriority: Int] = [:]
        var categoryStats: [TaskCategory: Int] = [:]
        var priorityStats: [TaskPriority: Int] = [:]
        
        for task in tasks {
            categoryDist[task.category, default: 0] += 1
            priorityDist[task.priority, default: 0] += 1
            
            if task.isCompleted {
                categoryStats[task.category, default: 0] += 1
                priorityStats[task.priority, default: 0] += 1
            }
        }
        
        // Calculate achievements
        var achievements: [Achievement] = []
        for type in AchievementType.allCases {
            let progress = type.progress(stats: TaskStats(
                totalTasks: total,
                completedTasks: completed,
                categoryDistribution: categoryDist,
                priorityDistribution: priorityDist,
                achievements: [],
                longestStreak: 0,
                categoryStats: categoryStats,
                priorityStats: priorityStats
            ))
            
            achievements.append(Achievement(
                id: type,
                title: type.title,
                description: type.description,
                icon: type.icon,
                isCompleted: progress.current >= progress.total
            ))
        }
        
        // Calculate streak
        let sortedTasks = tasks.sorted { $0.completionDate ?? Date() < $1.completionDate ?? Date() }
        var currentStreak = 0
        var longestStreak = 0
        var lastDate: Date?
        
        for task in sortedTasks where task.isCompleted {
            if let completionDate = task.completionDate {
                if let last = lastDate {
                    let days = Calendar.current.dateComponents([.day], from: last, to: completionDate).day ?? 0
                    if days == 1 {
                        currentStreak += 1
                    } else if days > 1 {
                        currentStreak = 1
                    }
                } else {
                    currentStreak = 1
                }
                lastDate = completionDate
                longestStreak = max(longestStreak, currentStreak)
            }
        }
        
        return TaskStats(
            totalTasks: total,
            completedTasks: completed,
            categoryDistribution: categoryDist,
            priorityDistribution: priorityDist,
            achievements: achievements,
            longestStreak: longestStreak,
            categoryStats: categoryStats,
            priorityStats: priorityStats
        )
    }
    
    mutating func updateStats(for tasks: [Task]) {
        let newStats = TaskStats.calculateStats(from: tasks)
        self = newStats
    }
}

struct Task: Identifiable, Codable {
    let id: UUID
    let title: String
    let priority: TaskPriority
    let category: TaskCategory
    let dueDate: Date?
    var isCompleted: Bool
    var completionDate: Date?
    var motivationalMessage: String?
    
    init(id: UUID = UUID(), title: String, priority: TaskPriority, category: TaskCategory, dueDate: Date? = nil, isCompleted: Bool = false, completionDate: Date? = nil, motivationalMessage: String? = nil) {
        self.id = id
        self.title = title
        self.priority = priority
        self.category = category
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.completionDate = completionDate
        self.motivationalMessage = motivationalMessage
    }
}

struct UserSettings: Codable {
    var dailyTaskGoal: Int
    var motivationLevel: Int
    var preferredNotificationTime: Date
    var showDeleteConfirmation: Bool
    var deleteConfirmationText: String
    
    static var defaultSettings: UserSettings {
        UserSettings(
            dailyTaskGoal: 5,
            motivationLevel: 3,
            preferredNotificationTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date(),
            showDeleteConfirmation: true,
            deleteConfirmationText: "Are you sure you want to delete this task?"
        )
    }
}

struct SetupView: View {
    @ObservedObject var taskManager: TaskManager
    @State private var dailyTaskGoal: Int
    @State private var motivationLevel: Double
    @State private var preferredNotificationTime: Date
    
    init(taskManager: TaskManager) {
        self.taskManager = taskManager
        _dailyTaskGoal = State(initialValue: taskManager.userSettings.dailyTaskGoal)
        _motivationLevel = State(initialValue: Double(taskManager.userSettings.motivationLevel))
        _preferredNotificationTime = State(initialValue: taskManager.userSettings.preferredNotificationTime)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Preferences")) {
                    Stepper("Daily Task Goal: \(dailyTaskGoal)", value: $dailyTaskGoal, in: 1...20)
                    
                    VStack(alignment: .leading) {
                        Text("Motivation Level")
                        Slider(value: $motivationLevel, in: 1...5, step: 1)
                        HStack {
                            Text("Low")
                            Spacer()
                            Text("High")
                        }
                        .font(.caption)
                        .foregroundColor(.gray)
                    }
                }
                
                Section(header: Text("Notification Preferences")) {
                    DatePicker("Preferred Notification Time", selection: $preferredNotificationTime, displayedComponents: .hourAndMinute)
                }
            }
            .navigationTitle("Setup")
            .navigationBarItems(trailing: Button("Done") {
                taskManager.updateSettings(
                    dailyTaskGoal: dailyTaskGoal,
                    motivationLevel: Int(motivationLevel),
                    preferredNotificationTime: preferredNotificationTime
                )
            })
        }
    }
}

struct ContentView: View {
    @StateObject private var taskManager = TaskManager()
    @State private var isWelcomeActive = true
    
    var body: some View {
        Group {
            if isWelcomeActive {
                WelcomeView(tasks: $taskManager.tasks, isWelcomeActive: $isWelcomeActive, taskManager: taskManager)
            } else {
                HomeView(taskManager: taskManager)
            }
        }
    }
}

struct WelcomeView: View {
    @Binding var tasks: [Task]
    @Binding var isWelcomeActive: Bool
    @State private var showingSetupSheet = false
    @ObservedObject var taskManager: TaskManager
    
    init(tasks: Binding<[Task]>, isWelcomeActive: Binding<Bool>, taskManager: TaskManager) {
        self._tasks = tasks
        self._isWelcomeActive = isWelcomeActive
        self.taskManager = taskManager
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Welcome to HTasks")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Your AI-powered task management app")
                .font(.title2)
                .foregroundColor(.gray)
            
            VStack(alignment: .leading, spacing: 20) {
                FeatureRow(icon: "sparkles", title: "AI Task Suggestions", description: "Get personalized task recommendations based on your habits")
                
                FeatureRow(icon: "quote.bubble", title: "Motivational Messages", description: "Receive encouraging notifications to keep you on track")
                
                FeatureRow(icon: "trophy.fill", title: "Achievements", description: "Earn achievements as you complete tasks and build habits")
            }
            .padding()
            
            Button(action: {
                showingSetupSheet = true
            }) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
        .sheet(isPresented: $showingSetupSheet) {
            SetupView(taskManager: taskManager)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct HomeView: View {
    @ObservedObject var taskManager: TaskManager
    @State private var showingAddTaskSheet = false
    @State private var showingSettingsSheet = false
    @State private var showingAchievementsSheet = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(taskManager.tasks) { task in
                        TaskRow(task: task, taskManager: taskManager)
                    }
                } header: {
                    Text("Your Tasks")
                }
            }
            .navigationTitle("HTasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddTaskSheet = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: {
                            showingAchievementsSheet = true
                        }) {
                            Image(systemName: "trophy.fill")
                                .font(.title2)
                        }
                        
                        Button(action: {
                            showingSettingsSheet = true
                        }) {
                            Image(systemName: "gear")
                                .font(.title2)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddTaskSheet) {
                AddTaskView(taskManager: taskManager)
            }
            .sheet(isPresented: $showingSettingsSheet) {
                SettingsView(taskManager: taskManager)
            }
            .sheet(isPresented: $showingAchievementsSheet) {
                AchievementsView(taskManager: taskManager)
            }
            .alert("Error", isPresented: $taskManager.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(taskManager.errorMessage ?? "An unknown error occurred")
            }
        }
    }
}

struct TaskRow: View {
    let task: Task
    let taskManager: TaskManager
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Circle()
                    .fill(task.priority.color)
                    .frame(width: 8, height: 8)
                
                Image(systemName: task.category.icon)
                    .foregroundColor(.black)
                    .font(.subheadline)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(.black)
                    .strikethrough(task.isCompleted)
                
                if let dueDate = task.dueDate {
                    Text(dueDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.black)
                }
                
                if let message = task.motivationalMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .italic()
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: {
                    taskManager.toggleTaskCompletion(task)
                }) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(.black)
                        .contentShape(Rectangle())
                }
                .buttonStyle(BorderlessButtonStyle())
                
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    Image(systemName: "trash.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                        .contentShape(Rectangle())
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .padding(.vertical, 8)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Delete Task"),
                message: Text(taskManager.userSettings.deleteConfirmationText),
                primaryButton: .destructive(Text("Delete")) {
                    taskManager.deleteTask(task)
                },
                secondaryButton: .cancel()
            )
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

final class TaskManager: ObservableObject, @unchecked Sendable {
    @Published private(set) var tasks: [Task] = []
    @Published private(set) var userSettings = UserSettings.defaultSettings {
        didSet {
            saveSettings()
        }
    }
    @Published private(set) var taskStats = TaskStats() {
        didSet {
            saveStats()
        }
    }
    @Published private(set) var showAchievementBanner = false
    @Published private(set) var completedAchievement: Achievement?
    @Published private(set) var errorMessage: String?
    @Published private(set) var showError = false
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let userDefaults = UserDefaults.standard
    private let queue = DispatchQueue(label: "com.htasks.taskmanager", qos: .userInitiated)
    
    init() {
        loadTasks()
        loadSettings()
        loadStats()
        checkNotificationPermission()
    }
    
    private func checkNotificationPermission() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            guard let self = self else { return }
            if settings.authorizationStatus == .notDetermined {
                self.requestNotificationPermission()
            }
        }
    }
    
    private func requestNotificationPermission() {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to request notification permission: \(error.localizedDescription)"
                    self.showError = true
                }
            }
        }
    }
    
    func loadTasks() {
        queue.async { [weak self] in
            guard let self = self else { return }
            if let data = userDefaults.data(forKey: "tasks"),
               let decodedTasks = try? JSONDecoder().decode([Task].self, from: data) {
                DispatchQueue.main.async {
                    self.tasks = decodedTasks
                    self.taskStats.updateStats(for: decodedTasks)
                }
            }
        }
    }
    
    func saveTasks() {
        queue.async { [weak self] in
            guard let self = self else { return }
            if let encoded = try? JSONEncoder().encode(self.tasks) {
                self.userDefaults.set(encoded, forKey: "tasks")
            }
        }
    }
    
    private func saveStats() {
        queue.async { [weak self] in
            guard let self = self else { return }
            if let encoded = try? JSONEncoder().encode(self.taskStats) {
                self.userDefaults.set(encoded, forKey: "taskStats")
            }
        }
    }
    
    func addTask(_ task: Task) {
        queue.async { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.tasks.append(task)
                self.saveTasks()
                self.taskStats.updateStats(for: self.tasks)
                
                if let dueDate = task.dueDate {
                    self.scheduleNotification(for: task, at: dueDate)
                }
            }
        }
    }
    
    func toggleTaskCompletion(_ task: Task) {
        queue.async { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let index = self.tasks.firstIndex(where: { $0.id == task.id }) {
                    self.tasks[index].isCompleted.toggle()
                    self.tasks[index].completionDate = self.tasks[index].isCompleted ? Date() : nil
                    
                    if self.tasks[index].isCompleted {
                        self.notificationCenter.removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])
                    } else if let dueDate = task.dueDate {
                        self.scheduleNotification(for: task, at: dueDate)
                    }
                    
                    self.saveTasks()
                    self.taskStats.updateStats(for: self.tasks)
                    self.checkAchievements()
                }
            }
        }
    }
    
    func deleteTask(_ task: Task) {
        queue.async { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.tasks.removeAll { $0.id == task.id }
                self.notificationCenter.removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])
                self.saveTasks()
                self.taskStats.updateStats(for: self.tasks)
            }
        }
    }
    
    func saveSettings() {
        queue.async { [weak self] in
            guard let self = self else { return }
            if let encoded = try? JSONEncoder().encode(self.userSettings) {
                UserDefaults.standard.set(encoded, forKey: "userSettings")
            }
        }
    }
    
    func loadSettings() {
        queue.async { [weak self] in
            guard let self = self else { return }
            if let data = UserDefaults.standard.data(forKey: "userSettings"),
               let decoded = try? JSONDecoder().decode(UserSettings.self, from: data) {
                DispatchQueue.main.async {
                    self.userSettings = decoded
                }
            }
        }
    }
    
    private func loadStats() {
        queue.async { [weak self] in
            guard let self = self else { return }
            if let data = UserDefaults.standard.data(forKey: "taskStats"),
               let decoded = try? JSONDecoder().decode(TaskStats.self, from: data) {
                DispatchQueue.main.async {
                    self.taskStats = decoded
                }
            }
        }
    }
    
    private func checkAchievements() {
        let previousAchievements = taskStats.achievements
        taskStats.updateStats(for: tasks)
        
        // Check for newly completed achievements
        for achievement in taskStats.achievements {
            if achievement.isCompleted && !previousAchievements.contains(where: { $0.id == achievement.id && $0.isCompleted }) {
                DispatchQueue.main.async {
                    self.completedAchievement = achievement
                    self.showAchievementBanner = true
                    
                    // Hide banner after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.showAchievementBanner = false
                    }
                }
            }
        }
    }
    
    private func scheduleNotification(for task: Task, at date: Date) {
        notificationCenter.getNotificationSettings { [weak self] settings in
            guard let self = self else { return }
            guard settings.authorizationStatus == .authorized else { return }
            
            let content = UNMutableNotificationContent()
            content.title = "Task Due: \(task.title)"
            content.body = "Your task is due today!"
            content.sound = .default
            
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)
            
            self.notificationCenter.add(request) { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = "Failed to schedule notification: \(error.localizedDescription)"
                        self.showError = true
                    }
                }
            }
            
            // Schedule reminder
            if let reminderDate = calendar.date(byAdding: .day, value: -1, to: date) {
                let reminderComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
                let reminderTrigger = UNCalendarNotificationTrigger(dateMatching: reminderComponents, repeats: false)
                
                let reminderContent = UNMutableNotificationContent()
                reminderContent.title = "Task Reminder: \(task.title)"
                reminderContent.body = "Your task is due tomorrow!"
                reminderContent.sound = .default
                
                let reminderRequest = UNNotificationRequest(identifier: "\(task.id.uuidString)-reminder", content: reminderContent, trigger: reminderTrigger)
                
                self.notificationCenter.add(reminderRequest) { [weak self] error in
                    guard let self = self else { return }
                    if let error = error {
                        DispatchQueue.main.async {
                            self.errorMessage = "Failed to schedule reminder: \(error.localizedDescription)"
                            self.showError = true
                        }
                    }
                }
            }
        }
    }
    
    func updateSettings(dailyTaskGoal: Int, motivationLevel: Int, preferredNotificationTime: Date) {
        queue.async { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.userSettings.dailyTaskGoal = dailyTaskGoal
                self.userSettings.motivationLevel = motivationLevel
                self.userSettings.preferredNotificationTime = preferredNotificationTime
                self.saveSettings()
            }
        }
    }
    
    func updateDeleteConfirmation(show: Bool, text: String) {
        queue.async { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.userSettings.showDeleteConfirmation = show
                self.userSettings.deleteConfirmationText = text
                self.saveSettings()
            }
        }
    }
}

struct AddTaskView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var taskManager: TaskManager
    @State private var title: String
    @State private var priority: TaskPriority = .medium
    @State private var category: TaskCategory = .personal
    @State private var dueDate = Date()
    @State private var showDueDate = false
    
    init(taskManager: TaskManager, title: String = "") {
        self.taskManager = taskManager
        _title = State(initialValue: title)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Task Title", text: $title)
                    
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            HStack {
                                Circle()
                                    .fill(priority.color)
                                    .frame(width: 10, height: 10)
                                Text(priority.rawValue.capitalized)
                            }
                        }
                    }
                }
                
                Section {
                    Picker("Category", selection: $category) {
                        ForEach(TaskCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.rawValue.capitalized)
                            }
                        }
                    }
                }
                
                Section {
                    Toggle("Set Due Date", isOn: $showDueDate)
                    
                    if showDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date])
                    }
                }
            }
            .navigationTitle("Add Task")
            .navigationBarItems(trailing: Button("Done") {
                if !title.isEmpty {
                    let task = Task(
                        title: title,
                        priority: priority,
                        category: category,
                        dueDate: showDueDate ? dueDate : nil
                    )
                    taskManager.addTask(task)
                }
                dismiss()
            })
        }
    }
}

struct SettingsView: View {
    @ObservedObject var taskManager: TaskManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Stepper("Daily Task Goal: \(taskManager.userSettings.dailyTaskGoal)", value: Binding(
                        get: { taskManager.userSettings.dailyTaskGoal },
                        set: { newValue in
                            taskManager.updateSettings(
                                dailyTaskGoal: newValue,
                                motivationLevel: taskManager.userSettings.motivationLevel,
                                preferredNotificationTime: taskManager.userSettings.preferredNotificationTime
                            )
                        }
                    ), in: 1...20)
                    
                    VStack(alignment: .leading) {
                        Text("Motivation Level")
                        Slider(value: Binding(
                            get: { Double(taskManager.userSettings.motivationLevel) },
                            set: { newValue in
                                taskManager.updateSettings(
                                    dailyTaskGoal: taskManager.userSettings.dailyTaskGoal,
                                    motivationLevel: Int(newValue),
                                    preferredNotificationTime: taskManager.userSettings.preferredNotificationTime
                                )
                            }
                        ), in: 1...5, step: 1)
                        HStack {
                            Text("Low")
                            Spacer()
                            Text("High")
                        }
                        .font(.caption)
                        .foregroundColor(.gray)
                    }
                }
                
                Section {
                    DatePicker("Preferred Notification Time", selection: Binding(
                        get: { taskManager.userSettings.preferredNotificationTime },
                        set: { newValue in
                            taskManager.updateSettings(
                                dailyTaskGoal: taskManager.userSettings.dailyTaskGoal,
                                motivationLevel: taskManager.userSettings.motivationLevel,
                                preferredNotificationTime: newValue
                            )
                        }
                    ), displayedComponents: .hourAndMinute)
                }
                
                Section {
                    Toggle("Show Delete Confirmation", isOn: Binding(
                        get: { taskManager.userSettings.showDeleteConfirmation },
                        set: { newValue in
                            taskManager.updateDeleteConfirmation(
                                show: newValue,
                                text: taskManager.userSettings.deleteConfirmationText
                            )
                        }
                    ))
                    
                    if taskManager.userSettings.showDeleteConfirmation {
                        TextField("Confirmation Message", text: Binding(
                            get: { taskManager.userSettings.deleteConfirmationText },
                            set: { newValue in
                                taskManager.updateDeleteConfirmation(
                                    show: taskManager.userSettings.showDeleteConfirmation,
                                    text: newValue
                                )
                            }
                        ))
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

struct AchievementsView: View {
    @ObservedObject var taskManager: TaskManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(taskManager.taskStats.achievements) { achievement in
                    Section {
                        AchievementRow(achievement: achievement, stats: taskManager.taskStats)
                    }
                }
            }
            .navigationTitle("Achievements")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

struct AchievementRow: View {
    let achievement: Achievement
    let stats: TaskStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 16) {
                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundColor(achievement.isCompleted ? .yellow : .gray)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(achievement.title)
                            .font(.headline)
                        
                        if achievement.isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    
                    Text(achievement.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            if achievement.id.showsProgress && !achievement.isCompleted {
                let progress = achievement.id.progress(stats: stats)
                ProgressView(value: Double(progress.current), total: Double(progress.total))
                    .tint(achievement.isCompleted ? .green : .blue)
                    .padding(.leading, 56)
                
                Text("\(progress.current)/\(progress.total)")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.leading, 56)
            }
        }
        .padding(.vertical, 8)
        .opacity(achievement.isCompleted ? 1.0 : 0.6)
    }
}

#Preview {
    ContentView()
}
