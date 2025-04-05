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
    var categoryDistribution: [TaskCategory: Int]
    var priorityDistribution: [TaskPriority: Int]
    
    init(totalTasks: Int = 0,
         completedTasks: Int = 0,
         categoryDistribution: [TaskCategory: Int] = [:],
         priorityDistribution: [TaskPriority: Int] = [:]) {
        self.totalTasks = totalTasks
        self.completedTasks = completedTasks
        self.categoryDistribution = categoryDistribution
        self.priorityDistribution = priorityDistribution
    }
    
    static func calculateStats(from tasks: [Task]) -> TaskStats {
        let total = tasks.count
        let completed = tasks.filter { $0.isCompleted }.count
        
        var categoryDist: [TaskCategory: Int] = [:]
        var priorityDist: [TaskPriority: Int] = [:]
        
        for task in tasks {
            categoryDist[task.category, default: 0] += 1
            priorityDist[task.priority, default: 0] += 1
        }
        
        return TaskStats(
            totalTasks: total,
            completedTasks: completed,
            categoryDistribution: categoryDist,
            priorityDistribution: priorityDist
        )
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
    var geminiApiKey: String?
    var dailyTaskGoal: Int
    var motivationLevel: Int
    var preferredNotificationTime: Date
    var showDeleteConfirmation: Bool
    var deleteConfirmationText: String
    var stats: TaskStats
    
    static var defaultSettings: UserSettings {
        UserSettings(
            geminiApiKey: nil,
            dailyTaskGoal: 5,
            motivationLevel: 3,
            preferredNotificationTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date(),
            showDeleteConfirmation: true,
            deleteConfirmationText: "Are you sure you want to delete this task?",
            stats: TaskStats()
        )
    }
}

struct SetupView: View {
    @ObservedObject var taskManager: TaskManager
    @State private var apiKey = ""
    @State private var dailyTaskGoal = 5
    @State private var motivationLevel = 3
    @State private var preferredNotificationTime = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("API Configuration")) {
                    TextField("Gemini API Key", text: $apiKey)
                        .textContentType(.none)
                        .autocapitalization(.none)
                }
                
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
                taskManager.userSettings.geminiApiKey = apiKey
                taskManager.userSettings.dailyTaskGoal = dailyTaskGoal
                taskManager.userSettings.motivationLevel = motivationLevel
                taskManager.userSettings.preferredNotificationTime = preferredNotificationTime
                taskManager.saveSettings()
            })
        }
    }
}

struct ContentView: View {
    @StateObject private var taskManager = TaskManager()
    @State private var isWelcomeActive = true
    @State private var showingSetupSheet = false
    
    var body: some View {
        Group {
            if isWelcomeActive {
                WelcomeView(tasks: $taskManager.tasks, isWelcomeActive: $isWelcomeActive)
            } else if taskManager.userSettings.geminiApiKey?.isEmpty ?? true {
                SetupView(taskManager: taskManager)
            } else {
                HomeView(taskManager: taskManager)
            }
        }
        .onAppear {
            if taskManager.userSettings.geminiApiKey?.isEmpty ?? true {
                showingSetupSheet = true
            }
        }
    }
}

struct WelcomeView: View {
    @Binding var tasks: [Task]
    @Binding var isWelcomeActive: Bool
    @State private var showingSetupSheet = false
    
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
            SetupView(taskManager: TaskManager())
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
    @State private var showingTaskSuggestions = false
    @State private var selectedSuggestion: String?
    @State private var showingSettingsSheet = false
    @State private var showingAchievementsSheet = false
    @State private var isGeneratingSuggestions = false
    
    var body: some View {
        NavigationView {
            List {
                if !taskManager.suggestedTasks.isEmpty {
                    Section(header: Text("Suggested Tasks")) {
                        ForEach(taskManager.suggestedTasks, id: \.self) { suggestion in
                            Button(action: {
                                selectedSuggestion = suggestion
                                showingAddTaskSheet = true
                            }) {
                                HStack {
                                    Text(suggestion)
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Your Tasks")) {
                    ForEach(taskManager.tasks) { task in
                        TaskRow(task: task, taskManager: taskManager)
                    }
                }
            }
            .navigationTitle("HTasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            Task {
                                isGeneratingSuggestions = true
                                await taskManager.generateTaskSuggestions()
                                isGeneratingSuggestions = false
                            }
                        }) {
                            HStack {
                                Label("Get Task Suggestions", systemImage: "lightbulb")
                                if isGeneratingSuggestions {
                                    Spacer()
                                    ProgressView()
                                }
                            }
                        }
                        .disabled(isGeneratingSuggestions)
                        
                        Button(action: {
                            showingAddTaskSheet = true
                        }) {
                            Label("Add Custom Task", systemImage: "plus")
                        }
                    } label: {
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
                if let suggestion = selectedSuggestion {
                    AddTaskView(taskManager: taskManager, title: suggestion)
                } else {
                    AddTaskView(taskManager: taskManager)
                }
            }
            .sheet(isPresented: $showingSettingsSheet) {
                SettingsView(taskManager: taskManager)
            }
            .sheet(isPresented: $showingAchievementsSheet) {
                AchievementsView(taskManager: taskManager)
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

class GeminiService {
    private let apiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func suggestPriority(for task: String, context: [Task]) async throws -> TaskPriority {
        let prompt = """
        Based on the following task and context, suggest a priority level (Easy, Medium, or Difficult):
        
        Task: \(task)
        
        Recent tasks:
        \(context.map { "- \($0.title) (\($0.priority.rawValue))" }.joined(separator: "\n"))
        
        Consider the task's urgency and importance. Respond with only one word: Easy, Medium, or Difficult.
        """
        
        let response = try await makeRequest(prompt: prompt)
        let priority = response.lowercased()
        
        switch priority {
        case "easy": return .easy
        case "medium": return .medium
        case "difficult": return .difficult
        default: return .medium
        }
    }
    
    func generateMotivationalMessage(for task: String) async throws -> String {
        let prompt = """
        Generate a short, motivational message for a task reminder. The message should be encouraging and positive.
        Task: \(task)
        
        Respond with only the motivational message, no additional text.
        """
        
        return try await makeRequest(prompt: prompt)
    }
    
    func suggestTasks(context: [Task]) async throws -> [String] {
        let prompt = """
        Based on the user's task history, suggest 3 relevant tasks they might want to add.
        Consider their patterns and preferences.
        
        Recent tasks:
        \(context.map { "- \($0.title)" }.joined(separator: "\n"))
        
        Respond with exactly 3 task suggestions, one per line, no additional text.
        """
        
        let response = try await makeRequest(prompt: prompt)
        return response.components(separatedBy: "\n").filter { !$0.isEmpty }
    }
    
    private func makeRequest(prompt: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            throw NSError(domain: "GeminiService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(GeminiResponse.self, from: data)
        
        return response.candidates.first?.content.parts.first?.text ?? ""
    }
}

struct GeminiResponse: Codable {
    let candidates: [Candidate]
    
    struct Candidate: Codable {
        let content: Content
    }
    
    struct Content: Codable {
        let parts: [Part]
    }
    
    struct Part: Codable {
        let text: String
    }
}

class TaskManager: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var userSettings = UserSettings.defaultSettings
    @Published var taskStats = TaskStats()
    @Published var showAchievementBanner = false
    @Published var completedAchievement: Achievement?
    @Published var suggestedTasks: [String] = []
    @Published var isGeneratingSuggestions = false
    
    private let geminiService: GeminiService
    private let notificationCenter = UNUserNotificationCenter.current()
    private let userDefaults = UserDefaults.standard
    
    init(geminiService: GeminiService) {
        self.geminiService = geminiService
        loadTasks()
        loadSettings()
        loadStats()
        
        requestNotificationPermission()
    }
    
    func loadTasks() {
        if let data = userDefaults.data(forKey: "tasks"),
           let decodedTasks = try? JSONDecoder().decode([Task].self, from: data) {
            tasks = decodedTasks
        }
    }
    
    func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            userDefaults.set(encoded, forKey: "tasks")
        }
    }
    
    func addTask(_ task: Task) {
        tasks.append(task)
        saveTasks()
        
        if let dueDate = task.dueDate {
            scheduleNotification(for: task, at: dueDate)
        }
    }
    
    func toggleTaskCompletion(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            tasks[index].completionDate = tasks[index].isCompleted ? Date() : nil
            
            if tasks[index].isCompleted {
                notificationCenter.removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])
            } else if let dueDate = task.dueDate {
                scheduleNotification(for: task, at: dueDate)
            }
            
            saveTasks()
            
            // Update stats and check achievements
            taskStats.updateStats(for: tasks)
            checkAchievements()
        }
    }
    
    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])
        saveTasks()
    }
    
    func saveSettings() {
        if let encoded = try? JSONEncoder().encode(userSettings) {
            UserDefaults.standard.set(encoded, forKey: "userSettings")
        }
    }
    
    func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: "userSettings"),
           let decoded = try? JSONDecoder().decode(UserSettings.self, from: data) {
            userSettings = decoded
        }
    }
    
    private func loadStats() {
        if let data = UserDefaults.standard.data(forKey: "taskStats"),
           let decoded = try? JSONDecoder().decode(TaskStats.self, from: data) {
            taskStats = decoded
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
    
    func generateTaskSuggestions() async {
        let context = TaskStats(
            totalTasks: tasks.count,
            completedTasks: tasks.filter { $0.isCompleted }.count,
            categoryDistribution: Dictionary(grouping: tasks, by: { $0.category })
                .mapValues { $0.count },
            priorityDistribution: Dictionary(grouping: tasks, by: { $0.priority })
                .mapValues { $0.count }
        )
        
        if let suggestions = try? await geminiService.suggestTasks(context: context) {
            DispatchQueue.main.async {
                self.suggestedTasks = suggestions
            }
        }
    }
    
    func suggestPriority(for title: String) async throws -> TaskPriority {
        let context = TaskStats(
            totalTasks: tasks.count,
            completedTasks: tasks.filter { $0.isCompleted }.count,
            categoryDistribution: Dictionary(grouping: tasks, by: { $0.category })
                .mapValues { $0.count },
            priorityDistribution: Dictionary(grouping: tasks, by: { $0.priority })
                .mapValues { $0.count }
        )
        return try await geminiService.suggestPriority(for: title, context: context)
    }
    
    func generateMotivationalMessage(for title: String) async throws -> String? {
        return try await geminiService.generateMotivationalMessage(for: title)
    }
    
    private func requestNotificationPermission() {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Error requesting notification permission: \(error)")
            }
        }
    }
    
    private func scheduleNotification(for task: Task, at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Task Due: \(task.title)"
        
        if let message = task.motivationalMessage {
            content.body = message
        } else {
            content.body = "Your task is due today!"
        }
        
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)
        notificationCenter.add(request)
        
        // Schedule a reminder notification for the day before
        if let reminderDate = calendar.date(byAdding: .day, value: -1, to: date) {
            let reminderComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
            let reminderTrigger = UNCalendarNotificationTrigger(dateMatching: reminderComponents, repeats: false)
            
            let reminderContent = UNMutableNotificationContent()
            reminderContent.title = "Task Reminder: \(task.title)"
            reminderContent.body = "Your task is due tomorrow!"
            reminderContent.sound = .default
            
            let reminderRequest = UNNotificationRequest(identifier: "\(task.id.uuidString)-reminder", content: reminderContent, trigger: reminderTrigger)
            notificationCenter.add(reminderRequest)
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
    @State private var showSuggestedPriority = false
    @State private var suggestedPriority: TaskPriority = .medium
    @State private var isGeneratingPriority = false
    @State private var isGeneratingMotivation = false
    @State private var motivationalMessage: String?
    
    init(taskManager: TaskManager, title: String = "") {
        self.taskManager = taskManager
        _title = State(initialValue: title)
        
        if !title.isEmpty {
            Task {
                do {
                    let suggested = try await taskManager.suggestPriority(for: title)
                    DispatchQueue.main.async {
                        suggestedPriority = suggested
                        showSuggestedPriority = true
                        priority = suggested
                    }
                } catch {
                    print("Error suggesting priority: \(error)")
                }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
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
                    
                    if showSuggestedPriority {
                        HStack {
                            Text("Suggested Priority:")
                            Spacer()
                            Circle()
                                .fill(suggestedPriority.color)
                                .frame(width: 10, height: 10)
                            Text(suggestedPriority.rawValue.capitalized)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Button(action: {
                        isGeneratingPriority = true
                        Task {
                            do {
                                let suggested = try await taskManager.suggestPriority(for: title)
                                suggestedPriority = suggested
                                showSuggestedPriority = true
                                priority = suggested
                            } catch {
                                print("Error suggesting priority: \(error)")
                            }
                            isGeneratingPriority = false
                        }
                    }) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Suggest Priority")
                            if isGeneratingPriority {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(title.isEmpty || isGeneratingPriority)
                }
                
                Section(header: Text("Category")) {
                    Picker("Category", selection: $category) {
                        ForEach(TaskCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.rawValue.capitalized)
                            }
                        }
                    }
                }
                
                Section(header: Text("Due Date")) {
                    Toggle("Set Due Date", isOn: $showDueDate)
                    
                    if showDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date])
                    }
                }
                
                Section(header: Text("Motivation")) {
                    if let message = motivationalMessage {
                        Text(message)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .italic()
                    }
                    
                    Button(action: {
                        isGeneratingMotivation = true
                        Task {
                            do {
                                if let message = try await taskManager.generateMotivationalMessage(for: title) {
                                    motivationalMessage = message
                                }
                            } catch {
                                print("Error generating motivation: \(error)")
                            }
                            isGeneratingMotivation = false
                        }
                    }) {
                        HStack {
                            Image(systemName: "quote.bubble")
                            Text("Generate Motivational Message")
                            if isGeneratingMotivation {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(title.isEmpty || isGeneratingMotivation)
                }
            }
            .navigationTitle("Add Task")
            .navigationBarItems(trailing: Button("Done") {
                if !title.isEmpty {
                    let task = Task(
                        title: title,
                        priority: priority,
                        category: category,
                        dueDate: showDueDate ? dueDate : nil,
                        motivationalMessage: motivationalMessage
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
                Section(header: Text("API Configuration")) {
                    TextField("Gemini API Key", text: Binding(
                        get: { taskManager.userSettings.geminiApiKey ?? "" },
                        set: { taskManager.userSettings.geminiApiKey = $0 }
                    ))
                    .textContentType(.none)
                    .autocapitalization(.none)
                }
                
                Section(header: Text("Task Preferences")) {
                    Stepper("Daily Task Goal: \(taskManager.userSettings.dailyTaskGoal)", value: Binding(
                        get: { taskManager.userSettings.dailyTaskGoal },
                        set: { taskManager.userSettings.dailyTaskGoal = $0 }
                    ), in: 1...20)
                    
                    VStack(alignment: .leading) {
                        Text("Motivation Level")
                        Slider(value: Binding(
                            get: { Double(taskManager.userSettings.motivationLevel) },
                            set: { taskManager.userSettings.motivationLevel = Int($0) }
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
                
                Section(header: Text("Notification Preferences")) {
                    DatePicker("Preferred Notification Time", selection: Binding(
                        get: { taskManager.userSettings.preferredNotificationTime },
                        set: { taskManager.userSettings.preferredNotificationTime = $0 }
                    ), displayedComponents: .hourAndMinute)
                }
                
                Section(header: Text("Task Management")) {
                    Toggle("Show Delete Confirmation", isOn: Binding(
                        get: { taskManager.userSettings.showDeleteConfirmation },
                        set: { taskManager.userSettings.showDeleteConfirmation = $0 }
                    ))
                    
                    if taskManager.userSettings.showDeleteConfirmation {
                        TextField("Confirmation Message", text: Binding(
                            get: { taskManager.userSettings.deleteConfirmationText },
                            set: { taskManager.userSettings.deleteConfirmationText = $0 }
                        ))
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                taskManager.saveSettings()
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
                            let progress = achievement.id.progress(stats: taskManager.taskStats)
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
            .navigationTitle("Achievements")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

#Preview {
    ContentView()
}
