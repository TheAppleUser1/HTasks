import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    private let db = Firestore.firestore()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    private init() {
        setupFirebase()
    }
    
    private func setupFirebase() {
        FirebaseApp.configure()
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            self?.isAuthenticated = user != nil
        }
    }
    
    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }
    
    func signUp(email: String, password: String) async throws {
        try await Auth.auth().createUser(withEmail: email, password: password)
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    func saveUserData(tasks: [Task], settings: UserSettings) async throws {
        guard let userId = currentUser?.uid else { return }
        
        let userData: [String: Any] = [
            "tasks": tasks.map { task in
                [
                    "id": task.id.uuidString,
                    "title": task.title,
                    "isCompleted": task.isCompleted,
                    "dueDate": task.dueDate as Any,
                    "completionDate": task.completionDate as Any,
                    "category": task.category.rawValue,
                    "priority": task.priority.rawValue,
                    "lastModified": task.lastModified
                ]
            },
            "settings": [
                "name": settings.name,
                "streak": settings.streak,
                "totalTasksCompleted": settings.totalTasksCompleted,
                "lastLoginDate": settings.lastLoginDate,
                "notificationsEnabled": settings.notificationsEnabled,
                "theme": settings.theme,
                "taskCategories": settings.taskCategories.map { $0.rawValue },
                "showDeleteConfirmation": settings.showDeleteConfirmation,
                "deleteConfirmationText": settings.deleteConfirmationText,
                "stats": [
                    "currentStreak": settings.stats.currentStreak,
                    "longestStreak": settings.stats.longestStreak,
                    "totalTasksCompleted": settings.stats.totalTasksCompleted,
                    "tasksCompletedToday": settings.stats.tasksCompletedToday,
                    "tasksCompletedThisWeek": settings.stats.tasksCompletedThisWeek,
                    "completedByCategory": settings.stats.completedByCategory.mapValues { $0 },
                    "completedByPriority": settings.stats.completedByPriority.mapValues { $0 },
                    "lastCompletionDate": settings.stats.lastCompletionDate as Any,
                    "achievements": settings.stats.achievements.map { [
                        "id": $0.id.rawValue,
                        "isUnlocked": $0.isUnlocked
                    ]}
                ]
            ]
        ]
        
        try await db.collection("users").document(userId).setData(userData, merge: true)
    }
    
    func loadUserData() async throws -> ([Task], UserSettings)? {
        guard let userId = currentUser?.uid else { return nil }
        
        let document = try await db.collection("users").document(userId).getDocument()
        guard let data = document.data() else { return nil }
        
        // Decode tasks
        let tasksData = data["tasks"] as? [[String: Any]] ?? []
        let tasks = tasksData.compactMap { taskData -> Task? in
            guard let id = UUID(uuidString: taskData["id"] as? String ?? ""),
                  let title = taskData["title"] as? String,
                  let isCompleted = taskData["isCompleted"] as? Bool,
                  let category = TaskCategory(rawValue: taskData["category"] as? String ?? ""),
                  let priority = TaskPriority(rawValue: taskData["priority"] as? String ?? ""),
                  let lastModified = taskData["lastModified"] as? Date else {
                return nil
            }
            
            return Task(
                id: id,
                title: title,
                isCompleted: isCompleted,
                dueDate: taskData["dueDate"] as? Date,
                completionDate: taskData["completionDate"] as? Date,
                category: category,
                priority: priority,
                lastModified: lastModified
            )
        }
        
        // Decode settings
        guard let settingsData = data["settings"] as? [String: Any],
              let statsData = settingsData["stats"] as? [String: Any] else {
            return nil
        }
        
        let achievementsData = statsData["achievements"] as? [[String: Any]] ?? []
        let achievements = achievementsData.compactMap { data -> Achievement? in
            guard let id = AchievementType(rawValue: data["id"] as? String ?? ""),
                  let isUnlocked = data["isUnlocked"] as? Bool else {
                return nil
            }
            return Achievement(id: id, isUnlocked: isUnlocked)
        }
        
        let stats = TaskStats(
            currentStreak: statsData["currentStreak"] as? Int ?? 0,
            longestStreak: statsData["longestStreak"] as? Int ?? 0,
            totalTasksCompleted: statsData["totalTasksCompleted"] as? Int ?? 0,
            tasksCompletedToday: statsData["tasksCompletedToday"] as? Int ?? 0,
            tasksCompletedThisWeek: statsData["tasksCompletedThisWeek"] as? Int ?? 0,
            completedByCategory: (statsData["completedByCategory"] as? [String: Int])?.mapKeys { TaskCategory(rawValue: $0) ?? .personal } ?? [:],
            completedByPriority: (statsData["completedByPriority"] as? [String: Int])?.mapKeys { TaskPriority(rawValue: $0) ?? .medium } ?? [:],
            lastCompletionDate: statsData["lastCompletionDate"] as? Date,
            achievements: achievements
        )
        
        let settings = UserSettings(
            name: settingsData["name"] as? String ?? "User",
            streak: settingsData["streak"] as? Int ?? 0,
            totalTasksCompleted: settingsData["totalTasksCompleted"] as? Int ?? 0,
            lastLoginDate: settingsData["lastLoginDate"] as? Date ?? Date(),
            notificationsEnabled: settingsData["notificationsEnabled"] as? Bool ?? true,
            theme: settingsData["theme"] as? String ?? "system",
            taskCategories: (settingsData["taskCategories"] as? [String])?.compactMap { TaskCategory(rawValue: $0) } ?? [.personal, .work, .shopping, .health],
            showDeleteConfirmation: settingsData["showDeleteConfirmation"] as? Bool ?? true,
            deleteConfirmationText: settingsData["deleteConfirmationText"] as? String ?? "Are you sure you want to delete this task?",
            stats: stats
        )
        
        return (tasks, settings)
    }
} 