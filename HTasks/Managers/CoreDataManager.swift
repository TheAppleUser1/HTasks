import Foundation
import CoreData
import UserNotifications
import UIKit

// Core Data model types
@objc(TaskEntity)
public class TaskEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var dueDate: Date?
    @NSManaged public var createdDate: Date?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var category: CategoryEntity?
}

@objc(CategoryEntity)
public class CategoryEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var color: UIColor?
    @NSManaged public var tasks: NSSet?
}

extension TaskEntity {
    static func fetchRequest() -> NSFetchRequest<TaskEntity> {
        return NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
    }
}

extension CategoryEntity {
    static func fetchRequest() -> NSFetchRequest<CategoryEntity> {
        return NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
    }
}

class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    let container: NSPersistentContainer
    let notificationManager = NotificationManager.shared
    
    init() {
        container = NSPersistentContainer(name: "HTasksModel")
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        setupDefaultData()
    }
    
    func saveContext() {
        if container.viewContext.hasChanges {
            do {
                try container.viewContext.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
    
    func createTask(title: String, dueDate: Date?, category: CategoryEntity?) -> TaskEntity {
        let task = TaskEntity(context: container.viewContext)
        task.id = UUID()
        task.title = title
        task.dueDate = dueDate
        task.category = category
        task.createdDate = Date()
        task.isCompleted = false
        
        if task.dueDate != nil {
            notificationManager.scheduleTaskReminder(for: task)
        }
        
        saveContext()
        return task
    }
    
    func updateTask(_ task: TaskEntity) {
        if task.dueDate != nil {
            notificationManager.scheduleTaskReminder(for: task)
        } else {
            notificationManager.cancelTaskReminder(for: task)
        }
        saveContext()
    }
    
    func deleteTask(_ task: TaskEntity) {
        notificationManager.cancelTaskReminder(for: task)
        container.viewContext.delete(task)
        saveContext()
    }
    
    func fetchTasks() -> [TaskEntity] {
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskEntity.createdDate, ascending: false)]
        
        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("Error fetching tasks: \(error)")
            return []
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
    
    private func setupDefaultData() {
        let categories = fetchCategories()
        if categories.isEmpty {
            let defaultCategories = [
                ("Personal", UIColor.systemBlue),
                ("Work", UIColor.systemGreen),
                ("Shopping", UIColor.systemOrange),
                ("Health", UIColor.systemRed),
                ("Other", UIColor.systemGray)
            ]
            
            for (name, color) in defaultCategories {
                let category = CategoryEntity(context: container.viewContext)
                category.id = UUID()
                category.name = name
                category.color = color
            }
            
            saveContext()
        }
    }
} 