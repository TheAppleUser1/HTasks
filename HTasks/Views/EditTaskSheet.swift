import SwiftUI

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