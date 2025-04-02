import SwiftUI

struct EditTaskSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var coreDataManager: CoreDataManager
    let task: TaskEntity
    @State private var title: String
    @State private var dueDate: Date
    @State private var hasDueDate: Bool
    @State private var selectedCategory: CategoryEntity?
    @State private var showingCategoryPicker = false
    
    init(task: TaskEntity) {
        self.task = task
        self._title = State(initialValue: task.title ?? "")
        self._dueDate = State(initialValue: task.dueDate ?? Date())
        self._hasDueDate = State(initialValue: task.dueDate != nil)
        self._selectedCategory = State(initialValue: task.category)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Title", text: $title)
                    
                    Toggle("Set Due Date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Due Date", 
                            selection: $dueDate,
                            displayedComponents: [.date]
                        )
                    }
                    
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
                    task.dueDate = hasDueDate ? dueDate : nil
                    task.category = selectedCategory
                    coreDataManager.updateTask(task)
                    dismiss()
                }
                .disabled(title.isEmpty)
            )
            .sheet(isPresented: $showingCategoryPicker) {
                CategoryPickerView(selectedCategory: $selectedCategory)
            }
        }
    }
} 