import CoreData
import SwiftUI

class CoreDataManager: ObservableObject {
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
    
    // MARK: - Category Methods
    func createCategory(name: String, color: String) -> CategoryEntity {
        let category = CategoryEntity(context: viewContext)
        category.id = UUID()
        category.name = name
        category.color = color
        category.createdDate = Date()
        saveContext()
        return category
    }
    
    func fetchCategories() -> [CategoryEntity] {
        let request = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CategoryEntity.name, ascending: true)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Failed to fetch categories: \(error.localizedDescription)")
            return []
        }
    }
    
    func deleteCategory(_ category: CategoryEntity) {
        viewContext.delete(category)
        saveContext()
    }
    
    // MARK: - Setup Default Data
    func setupDefaultData() {
        let request = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
        
        do {
            let count = try viewContext.count(for: request)
            if count == 0 {
                // Create default categories
                let defaultCategories = [
                    ("Home", "blue"),
                    ("Work", "red"),
                    ("Shopping", "green"),
                    ("Personal", "purple"),
                    ("Health", "orange")
                ]
                
                for (name, color) in defaultCategories {
                    _ = createCategory(name: name, color: color)
                }
                
                print("Created default categories")
            }
        } catch {
            print("Failed to check for existing categories: \(error.localizedDescription)")
        }
    }
} 