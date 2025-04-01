import Foundation
import CoreData
import UserNotifications

class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    private let container: NSPersistentContainer
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private init() {
        container = NSPersistentContainer(name: "HTasksModel")
        
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        
        // Request notification permissions
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
    }
    
    func setupDefaultData() {
        let context = container.viewContext
        
        // Check if we already have categories
        let fetchRequest: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
        
        do {
            let count = try context.count(for: fetchRequest)
            if count == 0 {
                // Create default categories
                let categories = [
                    ("Personal", "blue"),
                    ("Work", "red"),
                    ("Home", "green"),
                    ("Shopping", "purple")
                ]
                
                for (name, color) in categories {
                    let category = CategoryEntity(context: context)
                    category.id = UUID()
                    category.name = name
                    category.color = color
                    category.createdDate = Date()
                }
                
                try context.save()
                print("Default categories created")
            }
        } catch {
            print("Error setting up default data: \(error)")
        }
    }
    
    // MARK: - Category Operations
    
    func createCategory(name: String, color: String) -> CategoryEntity? {
        let context = container.viewContext
        let category = CategoryEntity(context: context)
        category.id = UUID()
        category.name = name
        category.color = color
        category.createdDate = Date()
        
        do {
            try context.save()
            return category
        } catch {
            print("Error creating category: \(error)")
            context.rollback()
            return nil
        }
    }
    
    func fetchCategories() -> [CategoryEntity] {
        let request: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CategoryEntity.name, ascending: true)]
        
        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("Error fetching categories: \(error)")
            return []
        }
    }
    
    func deleteCategory(_ category: CategoryEntity) {
        let context = container.viewContext
        context.delete(category)
        
        do {
            try context.save()
        } catch {
            print("Error deleting category: \(error)")
            context.rollback()
        }
    }
    
    // MARK: - Task Operations
    
    func createTask(title: String, dueDate: Date?, category: CategoryEntity?) -> TaskEntity? {
        let context = container.viewContext
        let task = TaskEntity(context: context)
        task.id = UUID()
        task.title = title
        task.dueDate = dueDate
        task.category = category
        task.createdDate = Date()
        task.isCompleted = false
        
        do {
            try context.save()
            
            // Schedule notification if due date is set
            if let dueDate = dueDate {
                scheduleTaskNotification(for: task)
            }
            
            return task
        } catch {
            print("Error creating task: \(error)")
            context.rollback()
            return nil
        }
    }
    
    func fetchTasks() -> [TaskEntity] {
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TaskEntity.isCompleted, ascending: true),
            NSSortDescriptor(keyPath: \TaskEntity.dueDate, ascending: true)
        ]
        
        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("Error fetching tasks: \(error)")
            return []
        }
    }
    
    func updateTask(_ task: TaskEntity) {
        let context = container.viewContext
        
        do {
            try context.save()
            
            // Update notification if due date changed
            if let dueDate = task.dueDate {
                scheduleTaskNotification(for: task)
            } else {
                cancelTaskNotification(for: task)
            }
        } catch {
            print("Error updating task: \(error)")
            context.rollback()
        }
    }
    
    func deleteTask(_ task: TaskEntity) {
        let context = container.viewContext
        context.delete(task)
        
        do {
            try context.save()
            cancelTaskNotification(for: task)
        } catch {
            print("Error deleting task: \(error)")
            context.rollback()
        }
    }
    
    // MARK: - Notification Management
    
    private func scheduleTaskNotification(for task: TaskEntity) {
        guard let taskId = task.id?.uuidString,
              let title = task.title,
              let dueDate = task.dueDate else { return }
        
        // Cancel any existing notification for this task
        cancelTaskNotification(for: task)
        
        // Schedule notification for 1 hour before due date
        let notificationDate = dueDate.addingTimeInterval(-3600)
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
        
        let content = UNMutableNotificationContent()
        content.title = "Task Due Soon"
        content.body = "\(title) is due in 1 hour"
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: taskId, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    private func cancelTaskNotification(for task: TaskEntity) {
        guard let taskId = task.id?.uuidString else { return }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [taskId])
    }
} 