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
    var totalCompleted: Int = 0
    var currentStreak: Int = 0
    var bestStreak: Int = 0
    var lastCompletionDate: Date?
    var categoryCompletions: [UUID: Int] = [:]
    
    init() {
        // Empty init is fine since we have default values
    }
    
    mutating func updateForChoreCompletion(chore: Chore) {
        totalCompleted += 1
        
        if let categoryId = chore.categoryId {
            categoryCompletions[categoryId, default: 0] += 1
        }
        
        if let lastCompletion = lastCompletionDate {
            let calendar = Calendar.current
            let daysSinceLastCompletion = calendar.dateComponents([.day], from: lastCompletion, to: Date()).day ?? 0
            
            if daysSinceLastCompletion == 1 {
                currentStreak += 1
                bestStreak = max(bestStreak, currentStreak)
            } else if daysSinceLastCompletion > 1 {
                currentStreak = 1
            }
        } else {
            currentStreak = 1
        }
        
        lastCompletionDate = Date()
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
            await checkAccountStatus()
        }
    }
    
    func checkAccountStatus() async {
        do {
            let accountStatus = try await container.accountStatus()
            DispatchQueue.main.async {
                switch accountStatus {
                case .available:
                    self.isAvailable = true
                case .noAccount:
                    print("No iCloud account")
                    self.isAvailable = false
                case .restricted:
                    print("iCloud restricted")
                    self.isAvailable = false
                case .couldNotDetermine:
                    print("Could not determine iCloud status")
                    self.isAvailable = false
                @unknown default:
                    print("Unknown iCloud status")
                    self.isAvailable = false
                }
            }
        } catch {
            print("Error checking iCloud status: \(error)")
            DispatchQueue.main.async {
                self.isAvailable = false
            }
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
        let result = try await database.records(matching: query)
        let records = result.matchResults.compactMap { try? $0.1.get() }
        
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
            throw CloudKitError.iCloudNotAvailable
        }
        
        let recordID = CKRecord.ID(recordType: "Statistics")
        let record = CKRecord(recordID: recordID)
        
        record["totalCompleted"] = statistics.totalCompleted as CKRecordValue
        record["currentStreak"] = statistics.currentStreak as CKRecordValue
        record["bestStreak"] = statistics.bestStreak as CKRecordValue
        if let lastCompletionDate = statistics.lastCompletionDate {
            record["lastCompletionDate"] = lastCompletionDate as CKRecordValue
        }
        
        // Convert UUID dictionary to string keys for CloudKit storage
        let categoryCompletionsStringKeys = statistics.categoryCompletions.reduce(into: [:]) { result, entry in
            result[entry.key.uuidString] = entry.value
        }
        record["categoryCompletions"] = categoryCompletionsStringKeys as CKRecordValue
        
        do {
            _ = try await database.save(record)
        } catch {
            throw CloudKitError.saveFailed(error)
        }
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
        let result = try await database.records(matching: query)
        let records = result.matchResults.compactMap { try? $0.1.get() }
        
        return records.compactMap { record in
            guard let title = record.value(forKey: "title") as? String else { return nil }
            let isCompleted = record.value(forKey: "isCompleted") as? Bool ?? false
            let categoryIdString = record.value(forKey: "categoryId") as? String
            let categoryId = categoryIdString.flatMap { UUID(uuidString: $0) }
            let dueDate = record.value(forKey: "dueDate") as? Date
            let creationDate = record.value(forKey: "creationDate") as? Date ?? Date()
            
            return Chore(
                id: UUID(uuidString: record.recordID.recordName) ?? UUID(),
                title: title,
                isCompleted: isCompleted,
                categoryId: categoryId,
                dueDate: dueDate
            )
        }
    }
    
    func fetchCategories() async throws -> [Category] {
        let query = CKQuery(recordType: "Category", predicate: NSPredicate(value: true))
        let result = try await database.records(matching: query)
        let records = result.matchResults.compactMap { try? $0.1.get() }
        
        return records.compactMap { record in
            guard let name = record.value(forKey: "name") as? String,
                  let color = record.value(forKey: "color") as? String else { return nil }
            
            return Category(
                id: UUID(uuidString: record.recordID.recordName) ?? UUID(),
                name: name,
                color: color
            )
        }
    }
    
    func fetchStatistics() async throws -> Statistics {
        guard isAvailable else {
            throw CloudKitError.iCloudNotAvailable
        }
        
        let query = CKQuery(recordType: "Statistics", predicate: NSPredicate(value: true))
        
        do {
            let (results, _) = try await database.records(matching: query)
            if let record = results.first?.1.record {
                var statistics = Statistics()
                
                statistics.totalCompleted = record["totalCompleted"] as? Int ?? 0
                statistics.currentStreak = record["currentStreak"] as? Int ?? 0
                statistics.bestStreak = record["bestStreak"] as? Int ?? 0
                statistics.lastCompletionDate = record["lastCompletionDate"] as? Date
                
                // Convert string keys back to UUID for categoryCompletions
                if let stringKeyCompletions = record["categoryCompletions"] as? [String: Int] {
                    statistics.categoryCompletions = stringKeyCompletions.reduce(into: [:]) { result, entry in
                        if let uuid = UUID(uuidString: entry.key) {
                            result[uuid] = entry.value
                        }
                    }
                }
                
                return statistics
            }
            return Statistics()
        } catch {
            throw CloudKitError.fetchFailed(error)
        }
    }
    
    func fetchAchievements() async throws -> [Achievement] {
        let query = CKQuery(recordType: "Achievement", predicate: NSPredicate(value: true))
        let result = try await database.records(matching: query)
        let records = result.matchResults.compactMap { try? $0.1.get() }
        
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
                id: UUID(uuidString: record.recordID.recordName) ?? UUID(),
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

enum CloudKitError: Error {
    case iCloudNotAvailable
    case saveFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
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
                HomeView(chores: $chores, categories: $chores, statistics: $chores, achievements: $chores)
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
    @Binding var categories: [Category]
    @Binding var statistics: Statistics
    @Binding var achievements: [Achievement]
    @StateObject private var cloudKit = CloudKitManager()
    @State private var showingAddChore = false
    @State private var showingSettingsSheet = false
    @AppStorage("settings") private var settings = UserSettings()
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var motivationManager = AIMotivationManager()
    @State private var showingDeleteAlert = false
    @State private var choreToDelete: Chore?
    @State private var syncError: Error?
    @State private var showingSyncError = false
    
    private func saveChores() {
        if let encoded = try? JSONEncoder().encode(chores) {
            UserDefaults.standard.set(encoded, forKey: "chores")
            UserDefaults.standard.synchronize()
            
            // Sync to iCloud if available
            if cloudKit.isAvailable {
                Task {
                    do {
                        try await cloudKit.syncChores(chores)
                    } catch {
                        DispatchQueue.main.async {
                            syncError = error
                            showingSyncError = true
                        }
                    }
                }
            }
        }
    }
    
    private func saveStatistics() {
        if let encoded = try? JSONEncoder().encode(statistics) {
            UserDefaults.standard.set(encoded, forKey: "statistics")
            UserDefaults.standard.synchronize()
            
            // Sync to iCloud if available
            if cloudKit.isAvailable {
                Task {
                    do {
                        try await cloudKit.syncStatistics(statistics)
                    } catch {
                        DispatchQueue.main.async {
                            syncError = error
                            showingSyncError = true
                        }
                    }
                }
            }
        }
    }
    
    private func completeChore(_ chore: Chore) {
        if let index = chores.firstIndex(where: { $0.id == chore.id }) {
            chores[index].isCompleted = true
            chores[index].completedDate = Date()
            statistics.updateForChoreCompletion(chore: chores[index])
            
            saveChores()
            saveStatistics()
            checkAchievements()
            
            // Cancel notification for completed chore
            notificationManager.cancelNotification(for: chore.id)
            
            // Show motivation message
            motivationManager.showMotivationMessage()
        }
    }
    
    private func deleteChore(_ chore: Chore) {
        if let index = chores.firstIndex(where: { $0.id == chore.id }) {
            chores.remove(at: index)
            saveChores()
            
            // Cancel notification for deleted chore
            notificationManager.cancelNotification(for: chore.id)
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(chores.filter { !$0.isCompleted }) { chore in
                    ChoreRow(chore: chore, category: categories.first(where: { $0.id == chore.categoryId }))
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                if settings.showDeleteConfirmation {
                                    choreToDelete = chore
                                    showingDeleteAlert = true
                                } else {
                                    deleteChore(chore)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                completeChore(chore)
                            } label: {
                                Label("Complete", systemImage: "checkmark")
                            }
                            .tint(.green)
                        }
                }
            }
            .navigationTitle("HTasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettingsSheet = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddChore = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddChore) {
                AddChoreView(chores: $chores, categories: $categories, statistics: $statistics, notificationManager: notificationManager)
            }
            .sheet(isPresented: $showingSettingsSheet) {
                SettingsView(settings: $settings, chores: $chores, categories: $categories, statistics: $statistics, achievements: $achievements)
            }
            .alert(settings.deleteConfirmationText, isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let chore = choreToDelete {
                        deleteChore(chore)
                    }
                }
            }
            .alert("Sync Error", isPresented: $showingSyncError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(syncError?.localizedDescription ?? "Unknown error occurred while syncing")
            }
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
