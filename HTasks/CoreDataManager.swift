import CoreData
import SwiftUI

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private let container: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        return container.viewContext
    }
    
    private init() {
        container = NSPersistentContainer(name: "HTasksModel")
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Failed to load Core Data: \(error.localizedDescription)")
            }
        }
        // Merge policy to handle conflicts
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    // MARK: - Save Context
    func saveContext() {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                print("Error saving context: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Chore Methods
    func createChore(title: String, priority: Int = 0, dueDate: Date? = nil, categoryID: UUID? = nil, isRecurring: Bool = false, recurrencePattern: String? = nil, notes: String? = nil) -> ChoreEntity {
        let chore = ChoreEntity(context: viewContext)
        chore.id = UUID()
        chore.title = title
        chore.priority = Int16(priority)
        chore.dueDate = dueDate
        chore.categoryID = categoryID
        chore.isRecurring = isRecurring
        chore.recurrencePattern = recurrencePattern
        chore.isCompleted = false
        chore.createdDate = Date()
        chore.notes = notes
        
        // Connect to category if exists
        if let categoryID = categoryID {
            let fetchRequest: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", categoryID as CVarArg)
            
            do {
                let categories = try viewContext.fetch(fetchRequest)
                if let category = categories.first {
                    chore.category = category
                }
            } catch {
                print("Error fetching category: \(error.localizedDescription)")
            }
        }
        
        saveContext()
        return chore
    }
    
    func deleteChore(_ chore: ChoreEntity) {
        viewContext.delete(chore)
        saveContext()
    }
    
    func completeChore(_ chore: ChoreEntity) {
        chore.isCompleted = true
        chore.completedDate = Date()
        
        // Update streak
        updateStreak()
        
        // Handle recurring chores
        if chore.isRecurring, let pattern = chore.recurrencePattern {
            createNextRecurringChore(from: chore, pattern: pattern)
        }
        
        saveContext()
    }
    
    func createNextRecurringChore(from chore: ChoreEntity, pattern: String) {
        // Create a new chore based on the recurring pattern
        let newChore = ChoreEntity(context: viewContext)
        newChore.id = UUID()
        newChore.title = chore.title
        newChore.priority = chore.priority
        newChore.categoryID = chore.categoryID
        newChore.isRecurring = true
        newChore.recurrencePattern = pattern
        newChore.isCompleted = false
        newChore.createdDate = Date()
        newChore.notes = chore.notes
        newChore.category = chore.category
        
        // Calculate next due date based on pattern
        if let dueDate = chore.dueDate {
            switch pattern {
            case "daily":
                newChore.dueDate = Calendar.current.date(byAdding: .day, value: 1, to: dueDate)
            case "weekly":
                newChore.dueDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: dueDate)
            case "biweekly":
                newChore.dueDate = Calendar.current.date(byAdding: .weekOfYear, value: 2, to: dueDate)
            case "monthly":
                newChore.dueDate = Calendar.current.date(byAdding: .month, value: 1, to: dueDate)
            default:
                newChore.dueDate = Calendar.current.date(byAdding: .day, value: 1, to: dueDate)
            }
        }
        
        saveContext()
    }
    
    func fetchChores(includeCompleted: Bool = false) -> [ChoreEntity] {
        let fetchRequest: NSFetchRequest<ChoreEntity> = ChoreEntity.fetchRequest()
        
        if !includeCompleted {
            fetchRequest.predicate = NSPredicate(format: "isCompleted == NO")
        }
        
        // Sort by priority (high to low) then by due date (soonest first)
        let prioritySort = NSSortDescriptor(key: "priority", ascending: false)
        let dueDateSort = NSSortDescriptor(key: "dueDate", ascending: true)
        let createdDateSort = NSSortDescriptor(key: "createdDate", ascending: true)
        
        fetchRequest.sortDescriptors = [prioritySort, dueDateSort, createdDateSort]
        
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("Error fetching chores: \(error.localizedDescription)")
            return []
        }
    }
    
    func fetchChores(for category: CategoryEntity) -> [ChoreEntity] {
        let fetchRequest: NSFetchRequest<ChoreEntity> = ChoreEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "category == %@ AND isCompleted == NO", category)
        
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("Error fetching chores: \(error.localizedDescription)")
            return []
        }
    }
    
    func fetchChoresDueToday() -> [ChoreEntity] {
        let fetchRequest: NSFetchRequest<ChoreEntity> = ChoreEntity.fetchRequest()
        
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        fetchRequest.predicate = NSPredicate(
            format: "isCompleted == NO AND dueDate >= %@ AND dueDate < %@",
            today as NSDate, tomorrow as NSDate
        )
        
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("Error fetching today's chores: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Category Methods
    func createCategory(name: String, color: String) -> CategoryEntity {
        let category = CategoryEntity(context: viewContext)
        category.id = UUID()
        category.name = name
        category.color = color
        
        saveContext()
        return category
    }
    
    func deleteCategory(_ category: CategoryEntity) {
        viewContext.delete(category)
        saveContext()
    }
    
    func fetchCategories() -> [CategoryEntity] {
        let fetchRequest: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
        let nameSort = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [nameSort]
        
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("Error fetching categories: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Streak Methods
    func getOrCreateStreak() -> StreakEntity {
        let fetchRequest: NSFetchRequest<StreakEntity> = StreakEntity.fetchRequest()
        
        do {
            let streaks = try viewContext.fetch(fetchRequest)
            if let streak = streaks.first {
                return streak
            } else {
                let streak = StreakEntity(context: viewContext)
                streak.id = UUID()
                streak.startDate = Date()
                streak.currentStreak = 0
                streak.longestStreak = 0
                streak.totalCompletions = 0
                saveContext()
                return streak
            }
        } catch {
            print("Error fetching streak: \(error.localizedDescription)")
            let streak = StreakEntity(context: viewContext)
            streak.id = UUID()
            streak.startDate = Date()
            streak.currentStreak = 0
            streak.longestStreak = 0
            streak.totalCompletions = 0
            saveContext()
            return streak
        }
    }
    
    func updateStreak() {
        let streak = getOrCreateStreak()
        let today = Calendar.current.startOfDay(for: Date())
        
        // Update total completions
        streak.totalCompletions += 1
        
        // Check if the last completion was yesterday
        if let lastCompletionDate = streak.lastCompletedDate {
            let lastCompletionDay = Calendar.current.startOfDay(for: lastCompletionDate)
            let isYesterday = Calendar.current.isDate(lastCompletionDay, inSameDayAs: 
                                                       Calendar.current.date(byAdding: .day, value: -1, to: today)!)
            
            // If the last completion was yesterday, increase streak
            if isYesterday {
                streak.currentStreak += 1
                
                // Update longest streak if current is longer
                if streak.currentStreak > streak.longestStreak {
                    streak.longestStreak = streak.currentStreak
                }
            } else if !Calendar.current.isDate(lastCompletionDay, inSameDayAs: today) {
                // If the last completion wasn't today or yesterday, reset streak
                streak.currentStreak = 1
            }
        } else {
            // First completion ever
            streak.currentStreak = 1
            streak.longestStreak = 1
        }
        
        streak.lastCompletedDate = Date()
        saveContext()
        
        // Check for achievements
        checkStreakAchievements(streak: streak)
    }
    
    // MARK: - Achievement Methods
    func createAchievement(name: String, description: String, type: String, threshold: Double) -> AchievementEntity {
        let achievement = AchievementEntity(context: viewContext)
        achievement.id = UUID()
        achievement.name = name
        achievement.description = description
        achievement.type = type
        achievement.threshold = threshold
        achievement.progress = 0
        achievement.isAchieved = false
        
        saveContext()
        return achievement
    }
    
    func updateAchievementProgress(type: String, value: Double) {
        let fetchRequest: NSFetchRequest<AchievementEntity> = AchievementEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "type == %@ AND isAchieved == NO", type)
        
        do {
            let achievements = try viewContext.fetch(fetchRequest)
            for achievement in achievements {
                achievement.progress = value
                
                // Check if achievement is complete
                if achievement.progress >= achievement.threshold {
                    achievement.isAchieved = true
                    achievement.achievedDate = Date()
                }
            }
            saveContext()
        } catch {
            print("Error fetching achievements: \(error.localizedDescription)")
        }
    }
    
    func fetchAchievements(onlyAchieved: Bool = false) -> [AchievementEntity] {
        let fetchRequest: NSFetchRequest<AchievementEntity> = AchievementEntity.fetchRequest()
        
        if onlyAchieved {
            fetchRequest.predicate = NSPredicate(format: "isAchieved == YES")
        }
        
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("Error fetching achievements: \(error.localizedDescription)")
            return []
        }
    }
    
    func checkStreakAchievements(streak: StreakEntity) {
        // Update streak achievements
        updateAchievementProgress(type: "streak", value: Double(streak.currentStreak))
        updateAchievementProgress(type: "totalCompletions", value: Double(streak.totalCompletions))
    }
    
    // MARK: - Setup Default Data
    func setupDefaultData() {
        // Check if we already have data
        let categoriesCount = (try? viewContext.count(for: CategoryEntity.fetchRequest())) ?? 0
        let achievementsCount = (try? viewContext.count(for: AchievementEntity.fetchRequest())) ?? 0
        
        // Only setup defaults if we don't have data
        if categoriesCount == 0 {
            setupDefaultCategories()
        }
        
        if achievementsCount == 0 {
            setupDefaultAchievements()
        }
    }
    
    private func setupDefaultCategories() {
        _ = createCategory(name: "Kitchen", color: "blue")
        _ = createCategory(name: "Bathroom", color: "green")
        _ = createCategory(name: "Bedroom", color: "purple")
        _ = createCategory(name: "Living Room", color: "orange")
        _ = createCategory(name: "Other", color: "gray")
    }
    
    private func setupDefaultAchievements() {
        // Streak achievements
        _ = createAchievement(
            name: "First Steps",
            description: "Complete chores for 3 days in a row",
            type: "streak",
            threshold: 3
        )
        
        _ = createAchievement(
            name: "Consistency is Key",
            description: "Complete chores for 7 days in a row",
            type: "streak",
            threshold: 7
        )
        
        _ = createAchievement(
            name: "Habit Master",
            description: "Complete chores for 30 days in a row",
            type: "streak",
            threshold: 30
        )
        
        // Completion count achievements
        _ = createAchievement(
            name: "Getting Started",
            description: "Complete 10 chores",
            type: "totalCompletions",
            threshold: 10
        )
        
        _ = createAchievement(
            name: "Productive",
            description: "Complete 50 chores",
            type: "totalCompletions",
            threshold: 50
        )
        
        _ = createAchievement(
            name: "Chore Champion",
            description: "Complete 100 chores",
            type: "totalCompletions",
            threshold: 100
        )
    }
} 