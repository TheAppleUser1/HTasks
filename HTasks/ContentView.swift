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
    var createdDate: Date
    
    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, categoryId: UUID? = nil, createdDate: Date = Date()) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.categoryId = categoryId
        self.createdDate = createdDate
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
    @Published var isAvailable = false
    @Published var lastSyncDate: Date?
    
    init() {
        self.container = CKContainer.default()
        self.database = container.privateCloudDatabase
        Task {
            await checkAccountStatus()
        }
    }
    
    func checkAccountStatus() async {
        do {
            let accountStatus = try await container.accountStatus()
            DispatchQueue.main.async {
                self.isAvailable = accountStatus == .available
            }
        } catch {
            print("Error checking iCloud status: \(error)")
            DispatchQueue.main.async {
                self.isAvailable = false
            }
        }
    }
    
    func syncChores(_ chores: [Chore]) async throws {
        guard isAvailable else { throw CloudKitError.iCloudNotAvailable }
        
        // Delete existing records
        let query = CKQuery(recordType: "Chore", predicate: NSPredicate(value: true))
        let (matchResults, _) = try await database.records(matching: query)
        try await withThrowingTaskGroup(of: Void.self) { group in
            for (recordID, _) in matchResults {
                group.addTask {
                    try await self.database.deleteRecord(withID: recordID)
                }
            }
        }
        
        // Save new records
        try await withThrowingTaskGroup(of: Void.self) { group in
            for chore in chores {
                group.addTask {
                    let record = CKRecord(recordType: "Chore")
                    record.setValue(chore.id.uuidString, forKey: "id")
                    record.setValue(chore.title, forKey: "title")
                    record.setValue(chore.isCompleted, forKey: "isCompleted")
                    record.setValue(chore.categoryId?.uuidString, forKey: "categoryId")
                    record.setValue(chore.createdDate, forKey: "createdDate")
                    try await self.database.save(record)
                }
            }
        }
        
        DispatchQueue.main.async {
            self.lastSyncDate = Date()
        }
    }
    
    func syncCategories(_ categories: [Category]) async throws {
        guard isAvailable else { throw CloudKitError.iCloudNotAvailable }
        
        let query = CKQuery(recordType: "Category", predicate: NSPredicate(value: true))
        let (matchResults, _) = try await database.records(matching: query)
        try await withThrowingTaskGroup(of: Void.self) { group in
            for (recordID, _) in matchResults {
                group.addTask {
                    try await self.database.deleteRecord(withID: recordID)
                }
            }
        }
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            for category in categories {
                group.addTask {
                    let record = CKRecord(recordType: "Category")
                    record.setValue(category.id.uuidString, forKey: "id")
                    record.setValue(category.name, forKey: "name")
                    record.setValue(category.color, forKey: "color")
                    try await self.database.save(record)
                }
            }
        }
        
        DispatchQueue.main.async {
            self.lastSyncDate = Date()
        }
    }
    
    func syncStatistics(_ statistics: Statistics) async throws {
        guard isAvailable else { throw CloudKitError.iCloudNotAvailable }
        
        let query = CKQuery(recordType: "Statistics", predicate: NSPredicate(value: true))
        let (matchResults, _) = try await database.records(matching: query)
        try await withThrowingTaskGroup(of: Void.self) { group in
            for (recordID, _) in matchResults {
                group.addTask {
                    try await self.database.deleteRecord(withID: recordID)
                }
            }
        }
        
        let record = CKRecord(recordType: "Statistics")
        record.setValue(statistics.totalCompleted, forKey: "totalCompleted")
        record.setValue(statistics.currentStreak, forKey: "currentStreak")
        record.setValue(statistics.bestStreak, forKey: "bestStreak")
        record.setValue(statistics.lastCompletionDate, forKey: "lastCompletionDate")
        
        // Convert UUID dictionary to string keys for CloudKit storage
        let categoryCompletionsStringKeys = statistics.categoryCompletions.reduce(into: [:]) { result, entry in
            result[entry.key.uuidString] = entry.value
        }
        record.setValue(categoryCompletionsStringKeys, forKey: "categoryCompletions")
        
        try await database.save(record)
        
        DispatchQueue.main.async {
            self.lastSyncDate = Date()
        }
    }
    
    func syncAchievements(_ achievements: [Achievement]) async throws {
        guard isAvailable else { throw CloudKitError.iCloudNotAvailable }
        
        let query = CKQuery(recordType: "Achievement", predicate: NSPredicate(value: true))
        let (matchResults, _) = try await database.records(matching: query)
        try await withThrowingTaskGroup(of: Void.self) { group in
            for (recordID, _) in matchResults {
                group.addTask {
                    try await self.database.deleteRecord(withID: recordID)
                }
            }
        }
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            for achievement in achievements {
                group.addTask {
                    let record = CKRecord(recordType: "Achievement")
                    record.setValue(achievement.id.uuidString, forKey: "id")
                    record.setValue(achievement.title, forKey: "title")
                    record.setValue(achievement.description, forKey: "description")
                    record.setValue(achievement.icon, forKey: "icon")
                    record.setValue(achievement.requirement, forKey: "requirement")
                    record.setValue(achievement.type.rawValue, forKey: "type")
                    record.setValue(achievement.isUnlocked, forKey: "isUnlocked")
                    try await self.database.save(record)
                }
            }
        }
        
        DispatchQueue.main.async {
            self.lastSyncDate = Date()
        }
    }
    
    func fetchChores() async throws -> [Chore] {
        guard isAvailable else { throw CloudKitError.iCloudNotAvailable }
        
        let query = CKQuery(recordType: "Chore", predicate: NSPredicate(value: true))
        let (matchResults, _) = try await database.records(matching: query)
        
        return try matchResults.compactMap { _, result in
            let record = try result.get()
            guard let idString = record.value(forKey: "id") as? String,
                  let id = UUID(uuidString: idString),
                  let title = record.value(forKey: "title") as? String,
                  let isCompleted = record.value(forKey: "isCompleted") as? Bool,
                  let createdDate = record.value(forKey: "createdDate") as? Date else {
                return nil
            }
            
            let categoryIdString = record.value(forKey: "categoryId") as? String
            let categoryId = categoryIdString.flatMap { UUID(uuidString: $0) }
            
            return Chore(
                id: id,
                title: title,
                isCompleted: isCompleted,
                categoryId: categoryId,
                createdDate: createdDate
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
    
    private let motivationalTemplates: [String: [String: [String]]] = [
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
            "default": [
                "Don't break your %d-day streak!",
                "Keep that %d-day streak going!",
                "You're on fire with that %d-day streak!"
            ]
        ]
    ]
    
    func generateMessage(for chore: Chore, statistics: Statistics) -> String {
        let timeSinceCreation = Calendar.current.dateComponents([.hour], from: chore.createdDate, to: Date()).hour ?? 0
        let category = getCategoryName(for: chore.categoryId)
        
        // Time-based messages
        let timeCategory: String
        if timeSinceCreation < 24 {
            timeCategory = "short"
        } else if timeSinceCreation < 72 {
            timeCategory = "medium"
        } else {
            timeCategory = "long"
        }
        
        if let timeMessages = motivationalTemplates["time"]?[timeCategory],
           let message = timeMessages.randomElement() {
            return String(format: message, chore.title)
        }
        
        return "Time to complete your chore!"
    }
    
    private func getCategoryName(for categoryId: UUID?) -> String {
        // This would be replaced with actual category lookup
        return "general"
    }
}

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()
    
    private init() {} // Make init private for singleton
    
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
        let timeSinceCreation = Calendar.current.dateComponents([.hour], from: chore.createdDate, to: Date()).hour ?? 0
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
    @State private var categories: [Category] = []
    @State private var statistics = Statistics()
    @State private var achievements: [Achievement] = []
    
    var body: some View {
        Group {
            if isWelcomeActive && chores.isEmpty {
                WelcomeView(
                    isWelcomeActive: $isWelcomeActive,
                    chores: $chores,
                    categories: $categories,
                    statistics: $statistics
                )
            } else {
                HomeView(
                    chores: $chores,
                    categories: $categories,
                    statistics: $statistics,
                    achievements: $achievements
                )
            }
        }
    }
}

struct WelcomeView: View {
    @Binding var isWelcomeActive: Bool
    @Binding var chores: [Chore]
    @Binding var categories: [Category]
    @Binding var statistics: Statistics
    @State private var newChoreName = ""
    @State private var showingAddChore = false
    @StateObject private var notificationManager = NotificationManager.shared
    
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
            AddChoreView(
                chores: $chores,
                categories: $categories,
                statistics: $statistics
            )
        }
        .onAppear {
            notificationManager.requestAuthorization()
        }
    }
}

struct HomeView: View {
    @Binding var chores: [Chore]
    @Binding var categories: [Category]
    @Binding var statistics: Statistics
    @Binding var achievements: [Achievement]
    @StateObject private var cloudKit = CloudKitManager.shared
    @State private var showingAddChore = false
    @State private var showingSettingsSheet = false
    @State private var settings = UserSettings()
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var showingDeleteAlert = false
    @State private var choreToDelete: Chore?
    @State private var syncError: Error?
    @State private var showingSyncError = false
    
    private func saveChores() {
        if let encoded = try? JSONEncoder().encode(chores) {
            UserDefaults.standard.set(encoded, forKey: "chores")
            UserDefaults.standard.synchronize()
            
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
    
    private func saveCategories() {
        if let encoded = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(encoded, forKey: "categories")
            UserDefaults.standard.synchronize()
            
            if cloudKit.isAvailable {
                Task {
                    do {
                        try await cloudKit.syncCategories(categories)
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
            statistics.updateForChoreCompletion(chore: chores[index])
            
            saveChores()
            saveStatistics()
            
            // Cancel notification for completed chore
            notificationManager.cancelNotification(for: chore.id)
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
                AddChoreView(
                    chores: $chores,
                    categories: $categories,
                    statistics: $statistics
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
    @StateObject private var cloudKit = CloudKitManager.shared
    @State private var syncError: Error?
    @State private var showingSyncError = false
    
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
            .alert("Sync Error", isPresented: $showingSyncError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(syncError?.localizedDescription ?? "Unknown error occurred while syncing")
            }
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
        if let encoded = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(encoded, forKey: "categories")
            UserDefaults.standard.synchronize()
            
            if cloudKit.isAvailable {
                Task {
                    do {
                        try await cloudKit.syncCategories(categories)
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
    @Binding var categories: [Category]
    @Binding var statistics: Statistics
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var cloudKit = CloudKitManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var newChoreTitle = ""
    @State private var selectedCategoryId: UUID?
    @State private var dueDate: Date?
    @State private var showingDatePicker = false
    @State private var syncError: Error?
    @State private var showingSyncError = false
    
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
                    dismiss()
                },
                trailing: Button("Add") {
                    addChore()
                }
                .disabled(newChoreTitle.isEmpty)
            )
            .alert("Sync Error", isPresented: $showingSyncError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(syncError?.localizedDescription ?? "Unknown error occurred while syncing")
            }
        }
    }
    
    private func addChore() {
        let newChore = Chore(
            title: newChoreTitle,
            isCompleted: false,
            categoryId: selectedCategoryId,
            createdDate: showingDatePicker ? dueDate ?? Date() : Date()
        )
        chores.append(newChore)
        saveChores()
        notificationManager.scheduleMotivationalNotification(for: newChore, statistics: statistics)
        newChoreTitle = ""
        dismiss()
    }
    
    private func saveChores() {
        if let encoded = try? JSONEncoder().encode(chores) {
            UserDefaults.standard.set(encoded, forKey: "chores")
            UserDefaults.standard.synchronize()
            
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
    @StateObject private var cloudKit = CloudKitManager.shared
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Delete Confirmation")) {
                    Toggle("Show confirmation when deleting", isOn: $settings.showDeleteConfirmation)
                    
                    if settings.showDeleteConfirmation {
                        TextField("Delete confirmation message", text: $settings.deleteConfirmationText)
                    }
                }
                .onChange(of: settings.showDeleteConfirmation) { _, _ in
                    settings.save()
                }
                .onChange(of: settings.deleteConfirmationText) { _, _ in
                    settings.save()
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
                    .disabled(isBackingUp || !cloudKit.isAvailable)
                    
                    Toggle("Automatic iCloud Backup", isOn: $settings.autoBackupToiCloud)
                        .onChange(of: settings.autoBackupToiCloud) { _, _ in
                            settings.save()
                        }
                    
                    if let lastSync = cloudKit.lastSyncDate {
                        Text("Last backup: \(lastSync.formatted(.relative(presentation: .named)))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                if !cloudKit.isAvailable {
                    Section {
                        Text("iCloud is not available. Please check your iCloud settings.")
                            .foregroundColor(.red)
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
        guard cloudKit.isAvailable else {
            await MainActor.run {
                backupErrorMessage = "iCloud is not available"
                showingBackupError = true
            }
            return
        }
        
        await MainActor.run {
            isBackingUp = true
        }
        
        do {
            try await cloudKit.syncChores(chores)
            try await cloudKit.syncCategories(categories)
            try await cloudKit.syncStatistics(statistics)
            try await cloudKit.syncAchievements(achievements)
            
            await MainActor.run {
                isBackingUp = false
                showingBackupSuccess = true
            }
        } catch {
            await MainActor.run {
                isBackingUp = false
                backupErrorMessage = error.localizedDescription
                showingBackupError = true
            }
        }
    }
}

struct ChoreRow: View {
    let chore: Chore
    let category: Category?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(chore.title)
                    .font(.headline)
                if let category = category {
                    Text(category.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            if chore.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ContentView()
}
