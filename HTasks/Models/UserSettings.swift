import Foundation

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
    var showSocialFeatures: Bool
    
    static var defaultSettings: UserSettings {
        UserSettings(
            name: "",
            streak: 0,
            totalTasksCompleted: 0,
            lastLoginDate: Date(),
            notificationsEnabled: true,
            theme: "system",
            taskCategories: [.personal, .work, .shopping, .health],
            showDeleteConfirmation: true,
            deleteConfirmationText: "Are you sure you want to delete this task?",
            stats: TaskStats(),
            showSocialFeatures: true
        )
    }
}

struct TaskStats: Codable {
    var dailyCompletedTasks: Int = 0
    var weeklyCompletedTasks: Int = 0
    var monthlyCompletedTasks: Int = 0
    var totalCompletedTasks: Int = 0
    var longestStreak: Int = 0
    var currentStreak: Int = 0
    var lastCompletedDate: Date?
    var categoryCompletion: [String: Int] = [:]
    var averageCompletionTime: TimeInterval = 0
    var mostProductiveTime: String = "morning"
}

enum TaskCategory: String, Codable, CaseIterable {
    case personal = "Personal"
    case work = "Work"
    case shopping = "Shopping"
    case health = "Health"
    case education = "Education"
    case social = "Social"
    case finance = "Finance"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .personal: return "person.fill"
        case .work: return "briefcase.fill"
        case .shopping: return "cart.fill"
        case .health: return "heart.fill"
        case .education: return "book.fill"
        case .social: return "person.2.fill"
        case .finance: return "dollarsign.circle.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .personal: return "blue"
        case .work: return "purple"
        case .shopping: return "green"
        case .health: return "red"
        case .education: return "orange"
        case .social: return "pink"
        case .finance: return "yellow"
        case .other: return "gray"
        }
    }
} 