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

struct Chore: Identifiable, Codable {
    var id: UUID
    var title: String
    var isCompleted = false
    var categoryId: UUID?
    var createdDate = Date()
    var dueDate: Date?
    
    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, categoryId: UUID? = nil, createdDate: Date = Date(), dueDate: Date? = nil) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.categoryId = categoryId
        self.createdDate = createdDate
        self.dueDate = dueDate
    }
    
    init(from entity: ChoreEntity) {
        self.id = entity.id ?? UUID()
        self.title = entity.title ?? "Untitled"
        self.isCompleted = entity.isCompleted
        self.categoryId = entity.categoryID
        self.createdDate = entity.createdDate ?? Date()
        self.dueDate = entity.dueDate
    }
}

struct UserSettings: Codable {
    var showDeleteConfirmation: Bool = true
    var deleteConfirmationText: String = "We offer no liability if your mother gets mad :P"
}

struct ChoreRow: View {
    let chore: ChoreEntity
    let onToggle: (ChoreEntity) -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Button(action: {
                chore.isCompleted.toggle()
                onToggle(chore)
            }) {
                Image(systemName: chore.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(chore.isCompleted ? .green : .gray)
            }
            
            VStack(alignment: .leading) {
                Text(chore.title ?? "")
                    .strikethrough(chore.isCompleted)
                
                if let dueDate = chore.dueDate {
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
    @State private var showingAddChore = false
    @State private var showingSettings = false
    @State private var searchText = ""
    @State private var selectedCategory: CategoryEntity?
    @State private var showingCategoryPicker = false
    @State private var showingEditChore = false
    @State private var selectedChore: ChoreEntity?
    
    var filteredChores: [ChoreEntity] {
        var chores = coreDataManager.fetchChores()
        
        if let category = selectedCategory {
            chores = chores.filter { $0.category?.id == category.id }
        }
        
        if !searchText.isEmpty {
            chores = chores.filter { ($0.title?.localizedCaseInsensitiveContains(searchText) ?? false) }
        }
        
        return chores
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredChores, id: \.id) { chore in
                    ChoreRow(chore: chore) { updatedChore in
                        coreDataManager.updateChore(updatedChore)
                    } onEdit: {
                        selectedChore = chore
                        showingEditChore = true
                    } onDelete: {
                        coreDataManager.deleteChore(chore)
                    }
                }
                .onDelete(perform: deleteChores)
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Chores")
            .searchable(text: $searchText, prompt: "Search chores")
            .navigationBarItems(
                leading: Button(action: { showingCategoryPicker = true }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                },
                trailing: Button(action: { showingAddChore = true }) {
                    Image(systemName: "plus")
                }
            )
            .sheet(isPresented: $showingAddChore) {
                AddChoreSheet { title, dueDate, category in
                    _ = coreDataManager.createChore(
                        title: title,
                        dueDate: dueDate,
                        category: category
                    )
                }
            }
            .sheet(isPresented: $showingEditChore) {
                if let chore = selectedChore {
                    EditChoreSheet(chore: chore) { updatedChore in
                        coreDataManager.updateChore(updatedChore)
                    }
                }
            }
            .sheet(isPresented: $showingCategoryPicker) {
                CategoryPickerSheet(selectedCategory: $selectedCategory)
            }
        }
    }
    
    private func deleteChores(at offsets: IndexSet) {
        for index in offsets {
            coreDataManager.deleteChore(filteredChores[index])
        }
    }
}

struct AddChoreSheet: View {
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
                Section(header: Text("Chore Details")) {
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
            .navigationTitle("New Chore")
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

struct EditChoreSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var coreDataManager: CoreDataManager
    let chore: ChoreEntity
    let onSave: (ChoreEntity) -> Void
    
    @State private var title: String
    @State private var dueDate: Date
    @State private var selectedCategory: CategoryEntity?
    @State private var showingCategoryPicker = false
    
    init(chore: ChoreEntity, onSave: @escaping (ChoreEntity) -> Void) {
        self.chore = chore
        self.onSave = onSave
        _title = State(initialValue: chore.title ?? "")
        _dueDate = State(initialValue: chore.dueDate ?? Date())
        _selectedCategory = State(initialValue: chore.category)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Chore Details")) {
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
            .navigationTitle("Edit Chore")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    chore.title = title
                    chore.dueDate = dueDate
                    chore.category = selectedCategory
                    onSave(chore)
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

