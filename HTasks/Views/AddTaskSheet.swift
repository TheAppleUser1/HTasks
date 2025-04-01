import SwiftUI

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