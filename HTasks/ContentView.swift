//
//  ContentView.swift
//  HTasks
//
//  Created by Apple on 2025. 03. 29..
//

import SwiftUI
import CloudKit
import UserNotifications

struct Category: Identifiable, Codable {
    let id: UUID
    var name: String
    var color: String // Store as hex string
    
    init(id: UUID = UUID(), name: String, color: String) {
        self.id = id
        self.name = name
        self.color = color
    }
}

struct Chore: Identifiable, Codable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var categoryId: UUID?
    var dueDate: Date?
    var creationDate: Date
    
    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, categoryId: UUID? = nil, dueDate: Date? = nil) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.categoryId = categoryId
        self.dueDate = dueDate
        self.creationDate = Date()
    }
}

struct UserSettings: Codable {
    var showDeleteConfirmation: Bool = true
    var deleteConfirmationText: String = "We offer no liability if your mother gets mad :P"
    var autoBackupToiCloud: Bool = true
    
    static func load() -> UserSettings {
        if let data = UserDefaults.standard.data(forKey: "userSettings") {
            do {
                return try JSONDecoder().decode(UserSettings.self, from: data)
            } catch {
                print("Failed to load settings: \(error.localizedDescription)")
            }
        }
        return UserSettings()
    }
    
    func save() {
        do {
            let encoded = try JSONEncoder().encode(self)
            UserDefaults.standard.set(encoded, forKey: "userSettings")
            UserDefaults.standard.synchronize()
        } catch {
            print("Failed to save settings: \(error.localizedDescription)")
        }
    }
}

struct Achievement: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let icon: String
    let requirement: Int
    let type: AchievementType
    var isUnlocked: Bool
    
    enum AchievementType: String, Codable {
        case totalCompleted
        case streak
        case categoryCompletion
    }
}

struct Statistics: Codable {
    var totalCompleted: Int
    var currentStreak: Int
    var bestStreak: Int
    var lastCompletionDate: Date?
    var categoryCompletions: [UUID: Int]
    
    init() {
        totalCompleted = 0
        currentStreak = 0
        bestStreak = 0
        categoryCompletions = [:]
    }
}

class CloudKitManager: ObservableObject {
    static let shared = CloudKitManager()
    private let container: CKContainer
    private let database: CKDatabase
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var isAvailable = false
    
    private init() {
        container = CKContainer.default()
        database = container.privateCloudDatabase
        
        // Check iCloud status
        Task {
            do {
                try await checkAccountStatus()
                isAvailable = true
            } catch {
                print("iCloud not available: \(error.localizedDescription)")
                isAvailable = false
            }
        }
    }
    
    private func checkAccountStatus() async throws {
        let accountStatus = try await container.accountStatus()
        switch accountStatus {
        case .available:
            return
        case .noAccount:
            throw NSError(domain: "CloudKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "No iCloud account found"])
        case .restricted:
            throw NSError(domain: "CloudKit", code: 2, userInfo: [NSLocalizedDescriptionKey: "iCloud access is restricted"])
        case .couldNotDetermine:
            throw NSError(domain: "CloudKit", code: 3, userInfo: [NSLocalizedDescriptionKey: "Could not determine iCloud status"])
        @unknown default:
            throw NSError(domain: "CloudKit", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unknown iCloud status"])
        }
    }
    
    // Update sync functions to check availability first
    func syncChores(_ chores: [Chore]) async throws {
        guard isAvailable else {
            throw NSError(domain: "CloudKit", code: 5, userInfo: [NSLocalizedDescriptionKey: "iCloud is not available"])
        }
        
        isSyncing = true
        defer { isSyncing = false }
        
        // Delete existing records
        let query = CKQuery(recordType: "Chore", predicate: NSPredicate(value: true))
        let (_, records, _) = try await database.records(matching: query)
        for record in records {
            try await database.deleteRecord(withID: record.recordID)
        }
        
        // Save new records
        for chore in chores {
            let record = CKRecord(recordType: "Chore")
            record.setValue(chore.title, forKey: "title")
            record.setValue(chore.isCompleted, forKey: "isCompleted")
            record.setValue(chore.categoryId?.uuidString, forKey: "categoryId")
            record.setValue(chore.dueDate, forKey: "dueDate")
            record.setValue(chore.creationDate, forKey: "creationDate")
            try await database.save(record)
        }
        
        lastSyncDate = Date()
    }
    
    // Update other sync functions similarly
    func syncCategories(_ categories: [Category]) async throws {
        guard isAvailable else {
            throw NSError(domain: "CloudKit", code: 5, userInfo: [NSLocalizedDescriptionKey: "iCloud is not available"])
        }
        
        let query = CKQuery(recordType: "Category", predicate: NSPredicate(value: true))
        let (_, records, _) = try await database.records(matching: query)
        for record in records {
            try await database.deleteRecord(withID: record.recordID)
        }
        
        for category in categories {
            let record = CKRecord(recordType: "Category")
            record.setValue(category.name, forKey: "name")
            record.setValue(category.color, forKey: "color")
            try await database.save(record)
        }
    }
    
    func syncStatistics(_ statistics: Statistics) async throws {
        guard isAvailable else {
            throw NSError(domain: "CloudKit", code: 5, userInfo: [NSLocalizedDescriptionKey: "iCloud is not available"])
        }
        
        let query = CKQuery(recordType: "Statistics", predicate: NSPredicate(value: true))
        let (_, records, _) = try await database.records(matching: query)
        for record in records {
            try await database.deleteRecord(withID: record.recordID)
        }
        
        let record = CKRecord(recordType: "Statistics")
        record.setValue(statistics.totalCompleted, forKey: "totalCompleted")
        record.setValue(statistics.currentStreak, forKey: "currentStreak")
        record.setValue(statistics.bestStreak, forKey: "bestStreak")
        record.setValue(statistics.lastCompletionDate, forKey: "lastCompletionDate")
        
        // Convert UUID keys to strings for CloudKit storage
        let categoryCompletions = Dictionary(uniqueKeysWithValues: statistics.categoryCompletions.map { 
            ($0.key.uuidString, $0.value)
        })
        record.setValue(categoryCompletions, forKey: "categoryCompletions")
        
        try await database.save(record)
    }
    
    func syncAchievements(_ achievements: [Achievement]) async throws {
        guard isAvailable else {
            throw NSError(domain: "CloudKit", code: 5, userInfo: [NSLocalizedDescriptionKey: "iCloud is not available"])
        }
        
        let query = CKQuery(recordType: "Achievement", predicate: NSPredicate(value: true))
        let (_, records, _) = try await database.records(matching: query)
        for record in records {
            try await database.deleteRecord(withID: record.recordID)
        }
        
        for achievement in achievements {
            let record = CKRecord(recordType: "Achievement")
            record.setValue(achievement.title, forKey: "title")
            record.setValue(achievement.description, forKey: "description")
            record.setValue(achievement.icon, forKey: "icon")
            record.setValue(achievement.requirement, forKey: "requirement")
            record.setValue(achievement.type.rawValue, forKey: "type")
            record.setValue(achievement.isUnlocked, forKey: "isUnlocked")
            try await database.save(record)
        }
    }
    
    func fetchChores() async throws -> [Chore] {
        let query = CKQuery(recordType: "Chore", predicate: NSPredicate(value: true))
        let (_, records, _) = try await database.records(matching: query)
        
        return records.compactMap { record in
            guard let title = record.value(forKey: "title") as? String else { return nil }
            let isCompleted = record.value(forKey: "isCompleted") as? Bool ?? false
            let categoryIdString = record.value(forKey: "categoryId") as? String
            let categoryId = categoryIdString.flatMap { UUID(uuidString: $0) }
            let dueDate = record.value(forKey: "dueDate") as? Date
            
            return Chore(
                id: record.recordID.recordName,
                title: title,
                isCompleted: isCompleted,
                categoryId: categoryId,
                dueDate: dueDate
            )
        }
    }
    
    func fetchCategories() async throws -> [Category] {
        let query = CKQuery(recordType: "Category", predicate: NSPredicate(value: true))
        let (_, records, _) = try await database.records(matching: query)
        
        return records.compactMap { record in
            guard let name = record.value(forKey: "name") as? String,
                  let color = record.value(forKey: "color") as? String else { return nil }
            
            return Category(
                id: record.recordID.recordName,
                name: name,
                color: color
            )
        }
    }
    
    func fetchStatistics() async throws -> Statistics {
        let query = CKQuery(recordType: "Statistics", predicate: NSPredicate(value: true))
        let (_, records, _) = try await database.records(matching: query)
        
        guard let record = records.first else { return Statistics() }
        
        let statistics = Statistics()
        statistics.totalCompleted = record.value(forKey: "totalCompleted") as? Int ?? 0
        statistics.currentStreak = record.value(forKey: "currentStreak") as? Int ?? 0
        statistics.bestStreak = record.value(forKey: "bestStreak") as? Int ?? 0
        statistics.lastCompletionDate = record.value(forKey: "lastCompletionDate") as? Date
        statistics.categoryCompletions = record.value(forKey: "categoryCompletions") as? [String: Int] ?? [:]
        
        return statistics
    }
    
    func fetchAchievements() async throws -> [Achievement] {
        let query = CKQuery(recordType: "Achievement", predicate: NSPredicate(value: true))
        let (_, records, _) = try await database.records(matching: query)
        
        return records.compactMap { record in
            guard let title = record.value(forKey: "title") as? String,
                  let description = record.value(forKey: "description") as? String,
                  let icon = record.value(forKey: "icon") as? String,
                  let requirement = record.value(forKey: "requirement") as? Int,
                  let typeString = record.value(forKey: "type") as? String,
                  let type = Achievement.AchievementType(rawValue: typeString),
                  let isUnlocked = record.value(forKey: "isUnlocked") as? Bool else {
                return nil
            }
            
            return Achievement(
                id: record.recordID.recordName,
                title: title,
                description: description,
                icon: icon,
                requirement: requirement,
                type: type,
                isUnlocked: isUnlocked
            )
        }
    }
}

class AIMotivationManager: ObservableObject {
    static let shared = AIMotivationManager()
    
    private let motivationalTemplates = [
        "time": [
            "short": [
                "Hey! That %@ isn't going to clean itself!",
                "Quick reminder: %@ is still waiting for you",
                "Don't forget about %@! It's been a while"
            ],
            "medium": [
                "Your %@ is feeling neglected...",
                "That %@ has been waiting patiently",
                "Time to tackle that %@ you've been avoiding"
            ],
            "long": [
                "Your %@ is collecting dust (literally)",
                "That %@ is starting to look like a science experiment",
                "Your %@ is begging for attention"
            ]
        ],
        "category": [
            "kitchen": [
                "Your kitchen is calling for a cleanup!",
                "Those dishes won't wash themselves",
                "Time to make your kitchen sparkle again"
            ],
            "bathroom": [
                "Your bathroom needs some TLC",
                "Time to freshen up your bathroom",
                "Your bathroom is waiting for a makeover"
            ],
            "bedroom": [
                "Your bedroom is looking a bit messy",
                "Time to make your bed and tidy up",
                "Your bedroom needs some organization"
            ]
        ],
        "streak": [
            "Don't break your %d-day streak!",
            "Keep that %d-day streak going!",
            "You're on fire with that %d-day streak!"
        ]
    ]
    
    func generateMessage(for chore: Chore, statistics: Statistics) -> String {
        let timeSinceCreation = Calendar.current.dateComponents([.hour], from: chore.creationDate, to: Date()).hour ?? 0
        let category = getCategoryName(for: chore.categoryId)
        
        // Time-based messages
        if timeSinceCreation < 24 {
            return String(format: motivationalTemplates["time"]!["short"]!.randomElement()!, chore.title)
        } else if timeSinceCreation < 72 {
            return String(format: motivationalTemplates["time"]!["medium"]!.randomElement()!, chore.title)
        } else {
            return String(format: motivationalTemplates["time"]!["long"]!.randomElement()!, chore.title)
        }
    }
    
    private func getCategoryName(for categoryId: UUID?) -> String {
        // This would be replaced with actual category lookup
        return "general"
    }
}

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()
    
    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleMotivationalNotification(for chore: Chore, statistics: Statistics) {
        let content = UNMutableNotificationContent()
        content.title = "Time to Get Moving!"
        content.body = AIMotivationManager.shared.generateMessage(for: chore, statistics: statistics)
        content.sound = .default
        
        // Schedule for 2 hours from now if chore is new, or 24 hours if it's been pending
        let timeSinceCreation = Calendar.current.dateComponents([.hour], from: chore.creationDate, to: Date()).hour ?? 0
        let delay: TimeInterval = timeSinceCreation < 24 ? 7200 : 86400 // 2 hours or 24 hours
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(identifier: chore.id.uuidString, content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    func cancelNotification(for choreId: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [choreId.uuidString])
    }
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
    @Binding var isWelcomeActive: Bool
    @Binding var chores: [Chore]
    @State private var newChoreName = ""
    @State private var showingAddChore = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 15) {
                Text("Welcome to")
                    .font(.title2)
                    .foregroundColor(.gray)
                
                Text("HTasks")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(.blue)
                
                Text("Your Home Chores Manager")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
            .padding(.top, 50)
            
            // Add Chore Section
            VStack(spacing: 20) {
                Text("Let's start by adding your first chore")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Button(action: {
                    showingAddChore = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Your First Chore")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(15)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Continue Button
            Button(action: {
                isWelcomeActive = false
                UserDefaults.standard.set(true, forKey: "hasSeenWelcome")
            }) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(15)
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .padding()
        .sheet(isPresented: $showingAddChore) {
            AddChoreView(chores: $chores, isPresented: $showingAddChore)
        }
    }
}

struct HomeView: View {
    @Binding var chores: [Chore]
    @State private var showingAddChore = false
    @State private var showingSettingsSheet = false
    @State private var showingCategoryManagement = false
    @State private var categories: [Category] = []
    @State private var selectedCategory: UUID?
    @State private var showingDeleteConfirmation = false
    @State private var choreToDelete: Chore?
    @State private var settings = UserSettings.load()
    @Environment(\.colorScheme) var colorScheme
    @State private var statistics = Statistics()
    @State private var achievements: [Achievement] = []
    @State private var showingStatistics = false
    @State private var showingAchievements = false
    @StateObject private var cloudKitManager = CloudKitManager.shared
    @State private var showingSyncError = false
    @State private var syncErrorMessage = ""
    @StateObject private var notificationManager = NotificationManager.shared
    
    var completedChoresCount: Int {
        chores.filter { $0.isCompleted }.count
    }
    
    var filteredChores: [Chore] {
        if let categoryId = selectedCategory {
            return chores.filter { $0.categoryId == categoryId }
        }
        return chores
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Category ScrollView
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            CategoryButton(title: "All", isSelected: selectedCategory == nil) {
                                selectedCategory = nil
                            }
                            
                            ForEach(categories) { category in
                                CategoryButton(
                                    title: category.name,
                                    color: Color(category.color),
                                    isSelected: selectedCategory == category.id
                                ) {
                                    selectedCategory = category.id
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                    
                    // VisionOS style header with completed chores count
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Number of chores done this week:")
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                        
                        HStack(alignment: .bottom, spacing: 8) {
                            Text("\(completedChoresCount)")
                                .font(.system(size: 60, weight: .bold, design: .rounded))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            if completedChoresCount == 0 {
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
                    
                    // Chore list with VisionOS-style design
                    List {
                        ForEach(filteredChores) { chore in
                            HStack {
                                Text(chore.title)
                                    .font(.headline)
                                    .foregroundColor(
                                        chore.isCompleted ? 
                                            (colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.5)) : 
                                            (colorScheme == .dark ? .white : .black)
                                    )
                                    .strikethrough(chore.isCompleted)
                                
                                Spacer()
                                
                                // Checkmark button
                                Button(action: {
                                    toggleChoreCompletion(chore)
                                }) {
                                    Image(systemName: chore.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .font(.title2)
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                        .padding(5)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                
                                // Delete button
                                Button(action: {
                                    choreToDelete = chore
                                    if settings.showDeleteConfirmation {
                                        showingDeleteConfirmation = true
                                    } else {
                                        deleteChore(chore)
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
                    .alert(isPresented: $showingDeleteConfirmation) {
                        Alert(
                            title: Text("Are you sure you want to delete this chore?"),
                            message: Text(settings.deleteConfirmationText),
                            primaryButton: .destructive(Text("Delete").foregroundColor(colorScheme == .dark ? .white : .black)) {
                                if let choreToDelete = choreToDelete {
                                    deleteChore(choreToDelete)
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
                            showingAddChore = true
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
            .navigationTitle("My Chores")
            .navigationBarItems(
                leading: HStack {
                    Button(action: { showingCategoryManagement = true }) {
                        Image(systemName: "folder.fill")
                    }
                    Button(action: { showingStatistics = true }) {
                        Image(systemName: "chart.bar.fill")
                    }
                    Button(action: { showingAchievements = true }) {
                        Image(systemName: "trophy.fill")
                    }
                    Button(action: syncWithCloud) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                },
                trailing: Button(action: { showingSettingsSheet = true }) {
                    Image(systemName: "gearshape.fill")
                }
            )
            .alert("Sync Error", isPresented: $showingSyncError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(syncErrorMessage)
            }
            .sheet(isPresented: $showingAddChore) {
                AddChoreView(
                    chores: $chores,
                    isPresented: $showingAddChore,
                    categories: categories,
                    statistics: statistics,
                    notificationManager: notificationManager
                )
            }
            .sheet(isPresented: $showingSettingsSheet) {
                SettingsView(
                    settings: $settings,
                    chores: $chores,
                    categories: $categories,
                    statistics: $statistics,
                    achievements: $achievements
                )
            }
            .sheet(isPresented: $showingCategoryManagement) {
                CategoryManagementView(categories: $categories)
            }
            .sheet(isPresented: $showingStatistics) {
                NavigationView {
                    StatisticsView(statistics: statistics, categories: categories)
                }
            }
            .sheet(isPresented: $showingAchievements) {
                NavigationView {
                    AchievementView(achievements: achievements)
                }
            }
            .onAppear {
                loadSettings()
                loadCategories()
                loadStatistics()
                loadAchievements()
                loadFromCloud()
                notificationManager.requestAuthorization()
            }
        }
    }
    
    private func toggleChoreCompletion(_ chore: Chore) {
        if let index = chores.firstIndex(where: { $0.id == chore.id }) {
            chores[index].isCompleted.toggle()
            if chores[index].isCompleted {
                updateStatistics(for: chore)
                notificationManager.cancelNotification(for: chore.id)
            }
            saveChores()
        }
    }
    
    private func deleteChore(_ chore: Chore) {
        if let index = chores.firstIndex(where: { $0.id == chore.id }) {
            chores.remove(at: index)
            saveChores()
        }
    }
    
    private func saveChores() {
        do {
            let encoded = try JSONEncoder().encode(chores)
            UserDefaults.standard.set(encoded, forKey: "savedChores")
            UserDefaults.standard.synchronize()
            handleAutoBackup()
        } catch {
            print("Failed to save chores: \(error.localizedDescription)")
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
    
    private func loadCategories() {
        if let data = UserDefaults.standard.data(forKey: "savedCategories") {
            do {
                categories = try JSONDecoder().decode([Category].self, from: data)
            } catch {
                print("Failed to load categories: \(error.localizedDescription)")
            }
        }
    }
    
    private func loadStatistics() {
        if let data = UserDefaults.standard.data(forKey: "statistics") {
            do {
                statistics = try JSONDecoder().decode(Statistics.self, from: data)
            } catch {
                print("Failed to load statistics: \(error.localizedDescription)")
            }
        }
    }
    
    private func loadAchievements() {
        if let data = UserDefaults.standard.data(forKey: "achievements") {
            do {
                achievements = try JSONDecoder().decode([Achievement].self, from: data)
            } catch {
                achievements = defaultAchievements
            }
        } else {
            achievements = defaultAchievements
        }
    }
    
    private func updateStatistics(for chore: Chore) {
        statistics.totalCompleted += 1
        
        if let categoryId = chore.categoryId {
            statistics.categoryCompletions[categoryId, default: 0] += 1
        }
        
        if let lastCompletion = statistics.lastCompletionDate {
            let calendar = Calendar.current
            let daysSinceLastCompletion = calendar.dateComponents([.day], from: lastCompletion, to: Date()).day ?? 0
            
            if daysSinceLastCompletion == 1 {
                statistics.currentStreak += 1
                statistics.bestStreak = max(statistics.bestStreak, statistics.currentStreak)
            } else if daysSinceLastCompletion > 1 {
                statistics.currentStreak = 1
            }
        } else {
            statistics.currentStreak = 1
        }
        
        statistics.lastCompletionDate = Date()
        
        saveStatistics()
        checkAchievements()
    }
    
    private func saveStatistics() {
        do {
            let encoded = try JSONEncoder().encode(statistics)
            UserDefaults.standard.set(encoded, forKey: "statistics")
            UserDefaults.standard.synchronize()
            handleAutoBackup()
        } catch {
            print("Failed to save statistics: \(error.localizedDescription)")
        }
    }
    
    private func checkAchievements() {
        for (index, achievement) in achievements.enumerated() {
            var shouldUnlock = false
            
            switch achievement.type {
            case .totalCompleted:
                shouldUnlock = statistics.totalCompleted >= achievement.requirement
            case .streak:
                shouldUnlock = statistics.currentStreak >= achievement.requirement
            case .categoryCompletion:
                shouldUnlock = statistics.categoryCompletions.values.contains { $0 >= achievement.requirement }
            }
            
            if shouldUnlock && !achievement.isUnlocked {
                achievements[index].isUnlocked = true
                saveAchievements()
            }
        }
    }
    
    private func saveAchievements() {
        do {
            let encoded = try JSONEncoder().encode(achievements)
            UserDefaults.standard.set(encoded, forKey: "achievements")
            UserDefaults.standard.synchronize()
            handleAutoBackup()
        } catch {
            print("Failed to save achievements: \(error.localizedDescription)")
        }
    }
    
    private func defaultAchievements: [Achievement] {
        [
            Achievement(
                id: UUID(),
                title: "Getting Started",
                description: "Complete your first chore",
                icon: "star.fill",
                requirement: 1,
                type: .totalCompleted,
                isUnlocked: statistics.totalCompleted >= 1
            ),
            Achievement(
                id: UUID(),
                title: "Streak Master",
                description: "Maintain a 7-day streak",
                icon: "flame.fill",
                requirement: 7,
                type: .streak,
                isUnlocked: statistics.currentStreak >= 7
            ),
            Achievement(
                id: UUID(),
                title: "Category Expert",
                description: "Complete 5 chores in a single category",
                icon: "folder.fill",
                requirement: 5,
                type: .categoryCompletion,
                isUnlocked: statistics.categoryCompletions.values.contains { $0 >= 5 }
            )
        ]
    }
    
    private func syncWithCloud() {
        Task {
            do {
                try await cloudKitManager.syncChores(chores)
                try await cloudKitManager.syncCategories(categories)
                try await cloudKitManager.syncStatistics(statistics)
                try await cloudKitManager.syncAchievements(achievements)
            } catch {
                syncErrorMessage = error.localizedDescription
                showingSyncError = true
            }
        }
    }
    
    private func loadFromCloud() {
        Task {
            do {
                let cloudChores = try await cloudKitManager.fetchChores()
                let cloudCategories = try await cloudKitManager.fetchCategories()
                let cloudStatistics = try await cloudKitManager.fetchStatistics()
                let cloudAchievements = try await cloudKitManager.fetchAchievements()
                
                await MainActor.run {
                    chores = cloudChores
                    categories = cloudCategories
                    statistics = cloudStatistics
                    achievements = cloudAchievements
                }
            } catch {
                syncErrorMessage = error.localizedDescription
                showingSyncError = true
            }
        }
    }
    
    private func handleAutoBackup() {
        if settings.autoBackupToiCloud {
            syncWithCloud()
        }
    }
}

struct CategoryManagementView: View {
    @Binding var categories: [Category]
    @State private var newCategoryName = ""
    @State private var selectedColor = "blue"
    @Environment(\.dismiss) var dismiss
    
    let colors = ["blue", "red", "green", "orange", "purple", "pink"]
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Add New Category")) {
                    TextField("Category Name", text: $newCategoryName)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(colors, id: \.self) { color in
                                Circle()
                                    .fill(Color(color))
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedColor == color ? 2 : 0)
                                    )
                                    .onTapGesture {
                                        selectedColor = color
                                    }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Button(action: addCategory) {
                        Text("Add Category")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color.blue)
                    .disabled(newCategoryName.isEmpty)
                }
                
                Section(header: Text("Your Categories")) {
                    ForEach(categories) { category in
                        HStack {
                            Circle()
                                .fill(Color(category.color))
                                .frame(width: 20, height: 20)
                            Text(category.name)
                        }
                    }
                    .onDelete(perform: deleteCategories)
                }
            }
            .navigationTitle("Categories")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
    
    private func addCategory() {
        let newCategory = Category(name: newCategoryName, color: selectedColor)
        categories.append(newCategory)
        newCategoryName = ""
        saveCategories()
    }
    
    private func deleteCategories(at offsets: IndexSet) {
        categories.remove(atOffsets: offsets)
        saveCategories()
    }
    
    private func saveCategories() {
        do {
            let encoded = try JSONEncoder().encode(categories)
            UserDefaults.standard.set(encoded, forKey: "savedCategories")
            UserDefaults.standard.synchronize()
            handleAutoBackup()
        } catch {
            print("Failed to save categories: \(error.localizedDescription)")
        }
    }
}

struct CategoryButton: View {
    let title: String
    var color: Color = .blue
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? color : color.opacity(0.1))
                )
        }
    }
}

struct AddChoreView: View {
    @Binding var chores: [Chore]
    @Binding var isPresented: Bool
    @State private var newChoreTitle = ""
    @State private var selectedCategoryId: UUID?
    @State private var dueDate: Date?
    @State private var showingDatePicker = false
    let categories: [Category]
    let statistics: Statistics
    let notificationManager: NotificationManager
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Chore Details")) {
                    TextField("Chore name", text: $newChoreTitle)
                    
                    Picker("Category", selection: $selectedCategoryId) {
                        Text("No Category").tag(Optional<UUID>.none)
                        ForEach(categories) { category in
                            HStack {
                                Circle()
                                    .fill(Color(category.color))
                                    .frame(width: 12, height: 12)
                                Text(category.name)
                            }
                            .tag(Optional(category.id))
                        }
                    }
                    
                    Toggle("Set Due Date", isOn: $showingDatePicker)
                    
                    if showingDatePicker {
                        DatePicker(
                            "Due Date",
                            selection: Binding(
                                get: { dueDate ?? Date() },
                                set: { dueDate = $0 }
                            ),
                            displayedComponents: [.date]
                        )
                    }
                }
            }
            .navigationTitle("Add New Chore")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                },
                trailing: Button("Add") {
                    let newChore = Chore(
                        title: newChoreTitle,
                        isCompleted: false,
                        categoryId: selectedCategoryId,
                        dueDate: showingDatePicker ? dueDate : nil
                    )
                    chores.append(newChore)
                    saveChores()
                    notificationManager.scheduleMotivationalNotification(for: newChore, statistics: statistics)
                    newChoreTitle = ""
                    isPresented = false
                }
                .disabled(newChoreTitle.isEmpty)
            )
        }
    }
    
    private func saveChores() {
        do {
            let encoded = try JSONEncoder().encode(chores)
            UserDefaults.standard.set(encoded, forKey: "savedChores")
            UserDefaults.standard.synchronize()
        } catch {
            print("Failed to save chores: \(error.localizedDescription)")
        }
    }
}

struct StatisticsView: View {
    let statistics: Statistics
    let categories: [Category]
    
    var body: some View {
        List {
            Section(header: Text("Overall Progress")) {
                StatRow(title: "Total Completed", value: "\(statistics.totalCompleted)")
                StatRow(title: "Current Streak", value: "\(statistics.currentStreak) days")
                StatRow(title: "Best Streak", value: "\(statistics.bestStreak) days")
            }
            
            Section(header: Text("Category Progress")) {
                ForEach(categories) { category in
                    StatRow(
                        title: category.name,
                        value: "\(statistics.categoryCompletions[category.id] ?? 0)"
                    )
                }
            }
        }
        .navigationTitle("Statistics")
    }
}

struct AchievementView: View {
    let achievements: [Achievement]
    
    var body: some View {
        List {
            ForEach(achievements) { achievement in
                HStack {
                    Image(systemName: achievement.icon)
                        .font(.title2)
                        .foregroundColor(achievement.isUnlocked ? .yellow : .gray)
                        .frame(width: 40)
                    
                    VStack(alignment: .leading) {
                        Text(achievement.title)
                            .font(.headline)
                        Text(achievement.description)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    if achievement.isUnlocked {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Achievements")
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.gray)
        }
    }
}

struct SettingsView: View {
    @Binding var settings: UserSettings
    @Binding var chores: [Chore]
    @Binding var categories: [Category]
    @Binding var statistics: Statistics
    @Binding var achievements: [Achievement]
    @Environment(\.dismiss) var dismiss
    @State private var showingBackupSuccess = false
    @State private var showingBackupError = false
    @State private var backupErrorMessage = ""
    @State private var isBackingUp = false
    @StateObject private var cloudKitManager = CloudKitManager.shared
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Delete Confirmation")) {
                    Toggle("Show confirmation when deleting", isOn: $settings.showDeleteConfirmation)
                    
                    if settings.showDeleteConfirmation {
                        TextField("Delete confirmation message", text: $settings.deleteConfirmationText)
                            .foregroundColor(.gray)
                    }
                }
                
                Section(header: Text("iCloud Backup")) {
                    Button(action: {
                        Task {
                            await performBackup()
                        }
                    }) {
                        HStack {
                            Text("Backup Now")
                            Spacer()
                            if isBackingUp {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                            }
                        }
                    }
                    .disabled(isBackingUp)
                    
                    Toggle("Automatic iCloud Backup", isOn: $settings.autoBackupToiCloud)
                        .onChange(of: settings.autoBackupToiCloud) { oldValue, newValue in
                            settings.save()
                        }
                    
                    if let lastSync = cloudKitManager.lastSyncDate {
                        Text("Last backup: \(lastSync.formatted(.relative(presentation: .named)))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .alert("Backup Successful", isPresented: $showingBackupSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your data has been successfully backed up to iCloud.")
            }
            .alert("Backup Failed", isPresented: $showingBackupError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(backupErrorMessage)
            }
        }
    }
    
    private func performBackup() async {
        isBackingUp = true
        defer { isBackingUp = false }
        
        do {
            try await cloudKitManager.syncChores(chores)
            try await cloudKitManager.syncCategories(categories)
            try await cloudKitManager.syncStatistics(statistics)
            try await cloudKitManager.syncAchievements(achievements)
            
            await MainActor.run {
                showingBackupSuccess = true
            }
        } catch {
            await MainActor.run {
                backupErrorMessage = error.localizedDescription
                showingBackupError = true
            }
        }
    }
}

#Preview {
    ContentView()
}
