import Foundation
import CoreData
import UserNotifications

enum AchievementType: String {
    case firstTask = "firstTask"
    case taskMaster = "taskMaster"
    case categoryExplorer = "categoryExplorer"
    case streakMaster = "streakMaster"
    case earlyBird = "earlyBird"
    case organizer = "organizer"
    case consistency = "consistency"
}

class AchievementManager: ObservableObject {
    static let shared = AchievementManager()
    private let coreDataManager: CoreDataManager
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private init() {
        coreDataManager = CoreDataManager.shared
        setupDefaultAchievements()
    }
    
    private func setupDefaultAchievements() {
        let context = CoreDataManager.shared.container.viewContext
        
        // Check if we already have achievements
        let fetchRequest: NSFetchRequest<AchievementEntity> = AchievementEntity.fetchRequest()
        
        do {
            let count = try context.count(for: fetchRequest)
            if count == 0 {
                // Create default achievements
                let achievements = [
                    (AchievementType.firstTask, "First Task", "Complete your first task"),
                    (AchievementType.taskMaster, "Task Master", "Complete 10 tasks"),
                    (AchievementType.earlyBird, "Early Bird", "Complete 5 tasks before their due date"),
                    (AchievementType.organizer, "Organizer", "Create 5 categories"),
                    (AchievementType.consistency, "Consistency", "Complete tasks for 7 days in a row")
                ]
                
                for (type, name, description) in achievements {
                    let achievement = AchievementEntity(context: context)
                    achievement.id = UUID()
                    achievement.name = name
                    achievement.achievementDescription = description
                    achievement.type = type.rawValue
                    achievement.isCompleted = false
                    achievement.progress = 0
                    achievement.requiredProgress = getRequiredProgress(for: type)
                }
                
                try context.save()
                print("Default achievements created")
            }
        } catch {
            print("Error setting up default achievements: \(error)")
        }
    }
    
    func checkAchievements() {
        let context = coreDataManager.container.viewContext
        let fetchRequest: NSFetchRequest<AchievementEntity> = AchievementEntity.fetchRequest()
        
        do {
            let achievements = try context.fetch(fetchRequest)
            
            for achievement in achievements {
                if achievement.isCompleted { continue }
                
                let type = AchievementType(rawValue: achievement.type ?? "") ?? .firstTask
                
                switch type {
                case .firstTask:
                    checkFirstTaskAchievement(achievement)
                case .taskMaster:
                    checkTaskMasterAchievement(achievement)
                case .categoryExplorer:
                    checkCategoryExplorerAchievement(achievement)
                case .streakMaster:
                    checkStreakMasterAchievement(achievement)
                case .earlyBird:
                    checkEarlyBirdAchievement(achievement)
                case .organizer:
                    checkOrganizerAchievement(achievement)
                case .consistency:
                    checkConsistencyAchievement(achievement)
                }
            }
            
            try context.save()
        } catch {
            print("Error checking achievements: \(error)")
        }
    }
    
    private func checkFirstTaskAchievement(_ achievement: AchievementEntity) {
        let tasks = coreDataManager.fetchTasks()
        let completedTasks = tasks.filter { $0.isCompleted }
        
        if !completedTasks.isEmpty {
            completeAchievement(achievement)
        }
    }
    
    private func checkTaskMasterAchievement(_ achievement: AchievementEntity) {
        let tasks = coreDataManager.fetchTasks()
        let completedTasks = tasks.filter { $0.isCompleted }
        
        achievement.progress = Int32(completedTasks.count)
        
        if completedTasks.count >= Int(achievement.requiredProgress) {
            completeAchievement(achievement)
        }
    }
    
    private func checkCategoryExplorerAchievement(_ achievement: AchievementEntity) {
        let tasks = coreDataManager.fetchTasks()
        let categories = coreDataManager.fetchCategories()
        let usedCategories = Set(tasks.compactMap { $0.category?.id })
        
        achievement.progress = Int32(usedCategories.count)
        
        if usedCategories.count >= Int(achievement.requiredProgress) {
            completeAchievement(achievement)
        }
    }
    
    private func checkStreakMasterAchievement(_ achievement: AchievementEntity) {
        let tasks = coreDataManager.fetchTasks()
        let completedTasks = tasks.filter { $0.isCompleted }
        
        // Group completed tasks by date
        let calendar = Calendar.current
        let groupedTasks = Dictionary(grouping: completedTasks) { task in
            calendar.startOfDay(for: task.createdDate ?? Date())
        }
        
        // Sort dates and check for consecutive days
        let sortedDates = groupedTasks.keys.sorted()
        var currentStreak = 1
        var maxStreak = 1
        
        for i in 1..<sortedDates.count {
            let daysBetween = calendar.dateComponents([.day], from: sortedDates[i-1], to: sortedDates[i]).day ?? 0
            if daysBetween == 1 {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }
        
        achievement.progress = Int32(maxStreak)
        
        if maxStreak >= Int(achievement.requiredProgress) {
            completeAchievement(achievement)
        }
    }
    
    private func checkEarlyBirdAchievement(_ achievement: AchievementEntity) {
        let tasks = coreDataManager.fetchTasks()
        let earlyBirdTasks = tasks.filter { task in
            guard let dueDate = task.dueDate,
                  let completedDate = task.createdDate,
                  task.isCompleted else { return false }
            return completedDate < dueDate
        }
        
        if !earlyBirdTasks.isEmpty {
            completeAchievement(achievement)
        }
    }
    
    private func checkOrganizerAchievement(_ achievement: AchievementEntity) {
        let categories = coreDataManager.fetchCategories()
        achievement.progress = Int32(categories.count)
        
        if categories.count >= Int(achievement.requiredProgress) {
            completeAchievement(achievement)
        }
    }
    
    private func checkConsistencyAchievement(_ achievement: AchievementEntity) {
        let tasks = coreDataManager.fetchTasks()
        let completedTasks = tasks.filter { $0.isCompleted }
        
        // Group completed tasks by date
        let calendar = Calendar.current
        let groupedTasks = Dictionary(grouping: completedTasks) { task in
            calendar.startOfDay(for: task.createdDate ?? Date())
        }
        
        // Sort dates and check for consecutive days
        let sortedDates = groupedTasks.keys.sorted()
        var currentStreak = 1
        var maxStreak = 1
        
        for i in 1..<sortedDates.count {
            let daysBetween = calendar.dateComponents([.day], from: sortedDates[i-1], to: sortedDates[i]).day ?? 0
            if daysBetween == 1 {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }
        
        achievement.progress = Int32(maxStreak)
        
        if maxStreak >= Int(achievement.requiredProgress) {
            completeAchievement(achievement)
        }
    }
    
    private func completeAchievement(_ achievement: AchievementEntity) {
        achievement.isCompleted = true
        achievement.completedDate = Date()
        
        // Schedule achievement notification
        scheduleAchievementNotification(for: achievement)
    }
    
    private func scheduleAchievementNotification(for achievement: AchievementEntity) {
        guard let name = achievement.name else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Achievement Unlocked!"
        content.body = "Congratulations! You've earned the \(name) achievement!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: achievement.id?.uuidString ?? UUID().uuidString,
                                          content: content,
                                          trigger: trigger)
        
        notificationCenter.add(request)
    }
    
    func fetchAchievements() -> [AchievementEntity] {
        let request: NSFetchRequest<AchievementEntity> = AchievementEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \AchievementEntity.isCompleted, ascending: false),
            NSSortDescriptor(keyPath: \AchievementEntity.name, ascending: true)
        ]
        
        do {
            return try coreDataManager.container.viewContext.fetch(request)
        } catch {
            print("Error fetching achievements: \(error)")
            return []
        }
    }
} 