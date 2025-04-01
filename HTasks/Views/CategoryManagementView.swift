import SwiftUI

struct CategoryManagementView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var coreDataManager: CoreDataManager
    @State private var categories: [CategoryEntity] = []
    @State private var showingAddCategory = false
    @State private var newCategoryName = ""
    @State private var selectedColor = "blue"
    
    let availableColors = [
        "blue", "red", "green", "purple", "orange",
        "yellow", "pink", "indigo", "teal", "gray"
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(categories, id: \.id) { category in
                    HStack {
                        Circle()
                            .fill(Color(category.color ?? "blue"))
                            .frame(width: 16, height: 16)
                        
                        Text(category.name ?? "")
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        
                        Spacer()
                        
                        Button(action: {
                            coreDataManager.deleteCategory(category)
                            loadCategories()
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
                .onDelete(perform: deleteCategories)
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Categories")
            .navigationBarItems(
                leading: Button("Done") { dismiss() },
                trailing: Button(action: { showingAddCategory = true }) {
                    Image(systemName: "plus")
                }
            )
            .sheet(isPresented: $showingAddCategory) {
                AddCategorySheet(
                    newCategoryName: $newCategoryName,
                    selectedColor: $selectedColor,
                    availableColors: availableColors,
                    onAdd: {
                        if !newCategoryName.isEmpty {
                            _ = coreDataManager.createCategory(
                                name: newCategoryName,
                                color: selectedColor
                            )
                            newCategoryName = ""
                            selectedColor = "blue"
                            loadCategories()
                            showingAddCategory = false
                        }
                    }
                )
            }
        }
        .onAppear {
            loadCategories()
        }
    }
    
    private func loadCategories() {
        categories = coreDataManager.fetchCategories()
    }
    
    private func deleteCategories(at offsets: IndexSet) {
        for index in offsets {
            coreDataManager.deleteCategory(categories[index])
        }
        loadCategories()
    }
}

struct AddCategorySheet: View {
    @Binding var newCategoryName: String
    @Binding var selectedColor: String
    let availableColors: [String]
    let onAdd: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Category Details")) {
                    TextField("Category name", text: $newCategoryName)
                    
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 44))
                    ], spacing: 10) {
                        ForEach(availableColors, id: \.self) { color in
                            Circle()
                                .fill(Color(color))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(color == selectedColor ? Color.blue : Color.clear, lineWidth: 2)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("New Category")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Add") {
                    onAdd()
                }
                .disabled(newCategoryName.isEmpty)
            )
        }
    }
} 