import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var coreDataManager: CoreDataManager
    @State private var showingAddTask = false
    @State private var showingSettings = false
    @State private var searchText = ""
    @State private var selectedCategory: CategoryEntity?
    @State private var showingCategoryPicker = false
    @State private var showingEditTask = false
    @State private var selectedTask: TaskEntity?
    
    var filteredTasks: [TaskEntity] {
        var tasks = coreDataManager.fetchTasks()
        
        if let category = selectedCategory {
            tasks = tasks.filter { $0.category?.id == category.id }
        }
        
        if !searchText.isEmpty {
            tasks = tasks.filter { ($0.title?.localizedCaseInsensitiveContains(searchText) ?? false) }
        }
        
        return tasks
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredTasks, id: \.id) { task in
                    TaskRow(task: task) { updatedTask in
                        coreDataManager.updateTask(updatedTask)
                    } onEdit: {
                        selectedTask = task
                        showingEditTask = true
                    } onDelete: {
                        coreDataManager.deleteTask(task)
                    }
                }
                .onDelete(perform: deleteTasks)
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Tasks")
            .searchable(text: $searchText, prompt: "Search tasks")
            .navigationBarItems(
                leading: Button(action: { showingCategoryPicker = true }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                },
                trailing: Button(action: { showingAddTask = true }) {
                    Image(systemName: "plus")
                }
            )
            .sheet(isPresented: $showingAddTask) {
                AddTaskSheet { title, dueDate, category in
                    _ = coreDataManager.createTask(
                        title: title,
                        dueDate: dueDate,
                        category: category
                    )
                }
            }
            .sheet(isPresented: $showingEditTask) {
                if let task = selectedTask {
                    EditTaskSheet(task: task) { updatedTask in
                        coreDataManager.updateTask(updatedTask)
                    }
                }
            }
            .sheet(isPresented: $showingCategoryPicker) {
                CategoryPickerSheet(selectedCategory: $selectedCategory)
            }
        }
    }
    
    private func deleteTasks(at offsets: IndexSet) {
        for index in offsets {
            coreDataManager.deleteTask(filteredTasks[index])
        }
    }
}

struct TaskRow: View {
    let task: TaskEntity
    let onToggle: (TaskEntity) -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Button(action: {
                task.isCompleted.toggle()
                onToggle(task)
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            
            VStack(alignment: .leading) {
                Text(task.title ?? "")
                    .strikethrough(task.isCompleted)
                
                if let dueDate = task.dueDate {
                    Text(dueDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Menu {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                }
                
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.gray)
            }
        }
    }
}

struct AddTaskSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var coreDataManager: CoreDataManager
    @State private var title = ""
    @State private var dueDate = Date()
    @State private var selectedCategory: CategoryEntity?
    @State private var showingCategoryPicker = false
    
    let onAdd: (String, Date?, CategoryEntity?) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Title", text: $title)
                    
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date])
                    
                    Button(action: { showingCategoryPicker = true }) {
                        HStack {
                            Text("Category")
                            Spacer()
                            Text(selectedCategory?.name ?? "None")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Add") {
                    onAdd(title, dueDate, selectedCategory)
                    dismiss()
                }
                .disabled(title.isEmpty)
            )
            .sheet(isPresented: $showingCategoryPicker) {
                CategoryPickerSheet(selectedCategory: $selectedCategory)
            }
        }
    }
}

struct EditTaskSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var coreDataManager: CoreDataManager
    let task: TaskEntity
    let onSave: (TaskEntity) -> Void
    
    @State private var title: String
    @State private var dueDate: Date
    @State private var selectedCategory: CategoryEntity?
    @State private var showingCategoryPicker = false
    
    init(task: TaskEntity, onSave: @escaping (TaskEntity) -> Void) {
        self.task = task
        self.onSave = onSave
        _title = State(initialValue: task.title ?? "")
        _dueDate = State(initialValue: task.dueDate ?? Date())
        _selectedCategory = State(initialValue: task.category)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Title", text: $title)
                    
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date])
                    
                    Button(action: { showingCategoryPicker = true }) {
                        HStack {
                            Text("Category")
                            Spacer()
                            Text(selectedCategory?.name ?? "None")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    task.title = title
                    task.dueDate = dueDate
                    task.category = selectedCategory
                    onSave(task)
                    dismiss()
                }
                .disabled(title.isEmpty)
            )
            .sheet(isPresented: $showingCategoryPicker) {
                CategoryPickerSheet(selectedCategory: $selectedCategory)
            }
        }
    }
} 