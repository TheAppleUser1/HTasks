import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var coreDataManager: CoreDataManager
    @State private var showingAddTask = false
    @State private var showingEditTask = false
    @State private var showingCategoryPicker = false
    @State private var selectedTask: TaskEntity?
    @State private var selectedCategory: CategoryEntity?
    @State private var searchText = ""
    
    var filteredTasks: [TaskEntity] {
        let tasks = coreDataManager.fetchTasks()
        return tasks.filter { task in
            let matchesCategory = selectedCategory == nil || task.category == selectedCategory
            let matchesSearch = searchText.isEmpty || 
                (task.title?.localizedCaseInsensitiveContains(searchText) ?? false)
            return matchesCategory && matchesSearch
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredTasks) { task in
                    TaskRow(
                        task: task,
                        onToggle: { task in
                            coreDataManager.saveContext()
                        },
                        onEdit: {
                            selectedTask = task
                            showingEditTask = true
                        },
                        onDelete: {
                            coreDataManager.deleteTask(task)
                        }
                    )
                }
            }
            .navigationTitle("Tasks")
            .searchable(text: $searchText, prompt: "Search tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddTask = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingCategoryPicker = true
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskSheet(coreDataManager: coreDataManager)
            }
            .sheet(isPresented: $showingEditTask) {
                if let task = selectedTask {
                    EditTaskSheet(task: task)
                }
            }
            .sheet(isPresented: $showingCategoryPicker) {
                CategoryPickerView(selectedCategory: $selectedCategory)
            }
        }
    }
} 