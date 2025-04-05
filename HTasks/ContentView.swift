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
    var geminiApiKey: String?
    var dailyTaskGoal: Int
    var motivationLevel: Int
    var preferredNotificationTime: Date
    var showDeleteConfirmation: Bool
    var deleteConfirmationText: String
    
    static var defaultSettings: UserSettings {
        UserSettings(
            geminiApiKey: nil,
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
    @State private var apiKey: String
    @State private var dailyTaskGoal: Int
    @State private var motivationLevel: Double
    @State private var preferredNotificationTime: Date
    
    init(taskManager: TaskManager) {
        self.taskManager = taskManager
        _apiKey = State(initialValue: taskManager.userSettings.geminiApiKey ?? "")
        _dailyTaskGoal = State(initialValue: taskManager.userSettings.dailyTaskGoal)
        _motivationLevel = State(initialValue: Double(taskManager.userSettings.motivationLevel))
        _preferredNotificationTime = State(initialValue: taskManager.userSettings.preferredNotificationTime)
    }
    
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
                taskManager.userSettings.geminiApiKey = apiKey.isEmpty ? nil : apiKey
                taskManager.userSettings.dailyTaskGoal = dailyTaskGoal
                taskManager.userSettings.motivationLevel = Int(motivationLevel)
                taskManager.userSettings.preferredNotificationTime = preferredNotificationTime
                taskManager.saveSettings()
            })
        }
    }
}

struct ContentView: View {
    @StateObject private var taskManager: TaskManager
    @State private var isWelcomeActive = true
    @State private var showingSetupSheet = false
    
    init() {
        let geminiService = GeminiService(apiKey: "")
        let taskManager = TaskManager(geminiService: geminiService)
        _taskManager = StateObject(wrappedValue: taskManager)
    }
    
    var body: some View {
        Group {
            if isWelcomeActive {
                WelcomeView(tasks: $taskManager.tasks, isWelcomeActive: $isWelcomeActive, taskManager: taskManager)
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
    @State private var showingTaskSuggestions = false
    @State private var selectedSuggestion: String?
    @State private var showingSettingsSheet = false
    @State private var showingAchievementsSheet = false
    @State private var isGeneratingSuggestions = false
    
    var body: some View {
        NavigationView {
            List {
                if !taskManager.suggestedTasks.isEmpty {
                    Section {
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
                    } header: {
                        Text("Suggested Tasks")
                    }
                }
                
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

class GeminiService {
    private let apiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func suggestPriority(for title: String, context: TaskStats) async throws -> TaskPriority {
        let prompt = """
        Based on this task title and context, suggest a priority level (Easy, Medium, or Difficult):
        
        Task: \(title)
        
        Context:
        - Total tasks: \(context.totalTasks)
        - Completed tasks: \(context.completedTasks)
        - Category distribution: \(context.categoryDistribution)
        - Priority distribution: \(context.priorityDistribution)
        
        Consider the task's complexity, urgency, and how it fits with existing tasks.
        Respond with only one word: Easy, Medium, or Difficult.
        """
        
        let response = try await makeRequest(prompt: prompt)
        let priority = response.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        switch priority {
        case "easy": return .easy
        case "medium": return .medium
        case "difficult": return .difficult
        default: return .medium
        }
    }
    
    func suggestTasks(context: TaskStats) async throws -> [String] {
        let prompt = """
        Based on the following task statistics, suggest 3 relevant tasks:
        
        Context:
        - Total tasks: \(context.totalTasks)
        - Completed tasks: \(context.completedTasks)
        - Category distribution: \(context.categoryDistribution)
        - Priority distribution: \(context.priorityDistribution)
        
        Consider:
        1. Balance across categories
        2. Current workload
        3. Completion patterns
        
        Respond with exactly 3 task suggestions, one per line, no additional text.
        """
        
        let response = try await makeRequest(prompt: prompt)
        return response
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(3)
            .map { String($0) }
    }
    
    func generateMotivationalMessage(for title: String) async throws -> String {
        let prompt = """
        Create a short, motivational message (maximum 100 characters) for this task: "\(title)"
        The message should be encouraging and specific to the task.
        Focus on the positive impact of completing the task.
        """
        
        return try await makeRequest(prompt: prompt)
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
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "GeminiService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            throw NSError(domain: "GeminiService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
        }
        
        return text
    }
}

class TaskManager: ObservableObject, Sendable {
    @Published var tasks: [Task] = []
    @Published var userSettings = UserSettings.defaultSettings {
        didSet {
            if oldValue.geminiApiKey != userSettings.geminiApiKey {
                updateGeminiService()
            }
        }
    }
    @Published var taskStats = TaskStats() {
        didSet {
            saveStats()
        }
    }
    @Published var showAchievementBanner = false
    @Published var completedAchievement: Achievement?
    @Published var suggestedTasks: [String] = []
    @Published var isGeneratingSuggestions = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    private var geminiService: GeminiService
    private let notificationCenter = UNUserNotificationCenter.current()
    private let userDefaults = UserDefaults.standard
    
    init(geminiService: GeminiService) {
        self.geminiService = geminiService
        loadTasks()
        loadSettings()
        loadStats()
        checkNotificationPermission()
    }
    
    private func updateGeminiService() {
        if let apiKey = userSettings.geminiApiKey {
            self.geminiService = GeminiService(apiKey: apiKey)
        }
    }
    
    private func checkNotificationPermission() {
        notificationCenter.getNotificationSettings { settings in
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
        if let data = userDefaults.data(forKey: "tasks"),
           let decodedTasks = try? JSONDecoder().decode([Task].self, from: data) {
            tasks = decodedTasks
            taskStats.updateStats(for: tasks)
        }
    }
    
    func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            userDefaults.set(encoded, forKey: "tasks")
        }
    }
    
    private func saveStats() {
        if let encoded = try? JSONEncoder().encode(taskStats) {
            userDefaults.set(encoded, forKey: "taskStats")
        }
    }
    
    func addTask(_ task: Task) {
        tasks.append(task)
        saveTasks()
        taskStats.updateStats(for: tasks)
        
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
            taskStats.updateStats(for: tasks)
            checkAchievements()
        }
    }
    
    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])
        saveTasks()
        taskStats.updateStats(for: tasks)
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
        isGeneratingSuggestions = true
        defer { isGeneratingSuggestions = false }
        
        do {
            let context = TaskStats.calculateStats(from: tasks)
            let suggestions = try await geminiService.suggestTasks(context: context)
            await MainActor.run {
                self.suggestedTasks = suggestions
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to generate task suggestions: \(error.localizedDescription)"
                self.showError = true
            }
        }
    }
    
    func suggestPriority(for title: String) async throws -> TaskPriority {
        let context = TaskStats.calculateStats(from: tasks)
        return try await geminiService.suggestPriority(for: title, context: context)
    }
    
    func generateMotivationalMessage(for title: String) async throws -> String? {
        return try await geminiService.generateMotivationalMessage(for: title)
    }
    
    private func scheduleNotification(for task: Task, at date: Date) {
        notificationCenter.getNotificationSettings { [weak self] settings in
            guard let self = self else { return }
            guard settings.authorizationStatus == .authorized else { return }
            
            let content = UNMutableNotificationContent()
            content.title = "Task Due: \(task.title)"
            content.body = task.motivationalMessage ?? "Your task is due today!"
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
    @State private var showError = false
    @State private var errorMessage: String?
    
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
                    DispatchQueue.main.async {
                        errorMessage = "Failed to suggest priority: \(error.localizedDescription)"
                        showError = true
                    }
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
                                DispatchQueue.main.async {
                                    suggestedPriority = suggested
                                    showSuggestedPriority = true
                                    priority = suggested
                                }
                            } catch {
                                DispatchQueue.main.async {
                                    errorMessage = "Failed to suggest priority: \(error.localizedDescription)"
                                    showError = true
                                }
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
                                    DispatchQueue.main.async {
                                        motivationalMessage = message
                                    }
                                }
                            } catch {
                                DispatchQueue.main.async {
                                    errorMessage = "Failed to generate motivation: \(error.localizedDescription)"
                                    showError = true
                                }
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
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
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
