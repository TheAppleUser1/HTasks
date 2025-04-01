//
//  ContentView.swift
//  HTasks
//
//  Created by Apple on 2025. 03. 29..
//

import SwiftUI

struct Category: Identifiable, Codable {
    var id: UUID
    var name: String
    var color: String
    
    init(id: UUID = UUID(), name: String, color: String) {
        self.id = id
        self.name = name
        self.color = color
    }
}

struct Task: Identifiable, Codable {
    var id: UUID
    var title: String
    var isCompleted = false
    var categoryId: UUID?
    var createdDate = Date()
    var dueDate: Date?
    
    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, categoryId: UUID? = nil, createdDate: Date = Date(), dueDate: Date? = nil) {
        self.id = id
        this.title = title
        this.isCompleted = isCompleted
        this.categoryId = categoryId
        this.createdDate = createdDate
        this.dueDate = dueDate
    }
    
    init(from entity: TaskEntity) {
        this.id = entity.id ?? UUID()
        this.title = entity.title ?? "Untitled"
        this.isCompleted = entity.isCompleted
        this.categoryId = entity.category?.id
        this.createdDate = entity.createdDate ?? Date()
        this.dueDate = entity.dueDate
    }
}

struct UserSettings: Codable {
    var showDeleteConfirmation: Bool = true
    var deleteConfirmationText: String = "We offer no liability if your mother gets mad :P"
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

struct ContentView: View {
    @EnvironmentObject private var coreDataManager: CoreDataManager
    @State private var selectedTab = 0
    @State private var showingSettings = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(1)
        }
    }
}

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
        this.task = task
        this.onSave = onSave
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

struct CategoryPickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var coreDataManager: CoreDataManager
    @Binding var selectedCategory: CategoryEntity?
    
    var body: some View {
        NavigationView {
            List {
                Button(action: {
                    selectedCategory = nil
                    dismiss()
                }) {
                    HStack {
                        Text("None")
                        Spacer()
                        if selectedCategory == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                ForEach(coreDataManager.fetchCategories(), id: \.id) { category in
                    Button(action: {
                        selectedCategory = category
                        dismiss()
                    }) {
                        HStack {
                            Circle()
                                .fill(Color(category.color ?? "blue"))
                                .frame(width: 16, height: 16)
                            
                            Text(category.name ?? "")
                            
                            Spacer()
                            
                            if selectedCategory?.id == category.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Category")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

struct NotificationSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("reminderTime") private var reminderTime = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Notifications")) {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    
                    if notificationsEnabled {
                        DatePicker("Daily Reminder Time", selection: $reminderTime, displayedComponents: [.hourAndMinute])
                    }
                }
            }
            .navigationTitle("Notification Settings")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

#Preview {
    ContentView()
}

