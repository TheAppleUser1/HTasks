import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Task: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var description: String
    var category: TaskCategory
    var isCompleted: Bool
    var dueDate: Date?
    var priority: TaskPriority
    var createdAt: Date
    var completedAt: Date?
    var userId: String
    var subtasks: [Subtask]
    var tags: [String]
    var reminderTime: Date?
    var isRecurring: Bool
    var recurrencePattern: RecurrencePattern?
    var attachments: [String]
    var notes: String?
    var estimatedDuration: TimeInterval?
    var actualDuration: TimeInterval?
    var location: TaskLocation?
    
    init(id: String? = nil,
         title: String,
         description: String = "",
         category: TaskCategory = .personal,
         isCompleted: Bool = false,
         dueDate: Date? = nil,
         priority: TaskPriority = .medium,
         createdAt: Date = Date(),
         completedAt: Date? = nil,
         userId: String,
         subtasks: [Subtask] = [],
         tags: [String] = [],
         reminderTime: Date? = nil,
         isRecurring: Bool = false,
         recurrencePattern: RecurrencePattern? = nil,
         attachments: [String] = [],
         notes: String? = nil,
         estimatedDuration: TimeInterval? = nil,
         actualDuration: TimeInterval? = nil,
         location: TaskLocation? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.priority = priority
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.userId = userId
        self.subtasks = subtasks
        self.tags = tags
        self.reminderTime = reminderTime
        self.isRecurring = isRecurring
        self.recurrencePattern = recurrencePattern
        self.attachments = attachments
        self.notes = notes
        self.estimatedDuration = estimatedDuration
        self.actualDuration = actualDuration
        self.location = location
    }
}

struct Subtask: Codable, Identifiable {
    var id: String
    var title: String
    var isCompleted: Bool
    var completedAt: Date?
    
    init(id: String = UUID().uuidString, title: String, isCompleted: Bool = false, completedAt: Date? = nil) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }
}

enum TaskPriority: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "blue"
        case .high: return "orange"
        case .urgent: return "red"
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "arrow.down.circle.fill"
        case .medium: return "equal.circle.fill"
        case .high: return "arrow.up.circle.fill"
        case .urgent: return "exclamationmark.circle.fill"
        }
    }
}

struct RecurrencePattern: Codable {
    enum Frequency: String, Codable {
        case daily, weekly, monthly, yearly
    }
    
    var frequency: Frequency
    var interval: Int
    var daysOfWeek: [Int]?
    var daysOfMonth: [Int]?
    var monthsOfYear: [Int]?
    var endDate: Date?
    var occurrences: Int?
}

struct TaskLocation: Codable {
    var name: String
    var latitude: Double
    var longitude: Double
    var address: String?
    var radius: Double?
} 