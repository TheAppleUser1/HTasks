import SwiftUI
import CoreData

struct CategoryManagementView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var coreDataManager = CoreDataManager.shared
    
    @State private var categories: [CategoryEntity] = []
    @State private var showingAddCategorySheet = false
    @State private var editingCategory: CategoryEntity?
    
    let availableColors = [
        "blue", "green", "purple", "orange", "red", "yellow", "pink", "gray", "indigo", "teal", "cyan"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient matching app style
                LinearGradient(
                    gradient: Gradient(colors: colorScheme == .dark ? 
                                      [Color.black, Color.blue.opacity(0.2)] : 
                                      [Color.white, Color.blue.opacity(0.1)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                VStack {
                    if categories.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "tag.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue.opacity(0.6))
                            
                            Text("No Categories Yet")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            Text("Categories help you organize your chores")
                                .font(.subheadline)
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            Button(action: {
                                showingAddCategorySheet = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Category")
                                }
                                .fontWeight(.semibold)
                                .padding()
                                .frame(maxWidth: 200)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(colorScheme == .dark ? Color.blue.opacity(0.7) : Color.blue)
                                )
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            }
                            .padding(.top, 12)
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(categories, id: \.id) { category in
                                CategoryRow(category: category) {
                                    editingCategory = category
                                    showingAddCategorySheet = true
                                }
                                .listRowBackground(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.8))
                                        .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                                )
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .swipeActions {
                                    Button(role: .destructive) {
                                        deleteCategory(category)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
                
                // Floating add button for non-empty list
                if !categories.isEmpty {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                editingCategory = nil
                                showingAddCategorySheet = true
                            }) {
                                Image(systemName: "plus")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(colorScheme == .dark ? .black : .white)
                                    .frame(width: 60, height: 60)
                                    .background(
                                        Circle()
                                            .fill(colorScheme == .dark ? .white : .black)
                                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                                    )
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle("Categories")
            .navigationBarItems(trailing: Button(action: {
                dismiss()
            }) {
                Text("Done")
                    .fontWeight(.medium)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            })
            .sheet(isPresented: $showingAddCategorySheet) {
                CategoryFormView(
                    category: editingCategory,
                    isEditing: editingCategory != nil,
                    availableColors: availableColors,
                    onSave: { name, colorName in
                        if let editingCategory = editingCategory {
                            updateCategory(editingCategory, name: name, color: colorName)
                        } else {
                            addCategory(name: name, color: colorName)
                        }
                        editingCategory = nil
                    }
                )
                .presentationDetents([.height(350)])
            }
        }
        .onAppear {
            loadCategories()
        }
    }
    
    private func loadCategories() {
        categories = coreDataManager.fetchCategories()
        
        // Add default categories if none exist
        if categories.isEmpty {
            coreDataManager.setupDefaultData()
            categories = coreDataManager.fetchCategories()
        }
    }
    
    private func addCategory(name: String, color: String) {
        _ = coreDataManager.createCategory(name: name, color: color)
        loadCategories()
    }
    
    private func updateCategory(_ category: CategoryEntity, name: String, color: String) {
        category.name = name
        category.color = color
        coreDataManager.saveContext()
        loadCategories()
    }
    
    private func deleteCategory(_ category: CategoryEntity) {
        coreDataManager.deleteCategory(category)
        loadCategories()
    }
}

struct CategoryRow: View {
    let category: CategoryEntity
    let onEdit: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color(category.color ?? "blue"))
                .frame(width: 24, height: 24)
            
            Text(category.name ?? "")
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            Spacer()
            
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                    .padding(8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.vertical, 8)
    }
}

struct CategoryFormView: View {
    let category: CategoryEntity?
    let isEditing: Bool
    let availableColors: [String]
    let onSave: (String, String) -> Void
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var categoryName: String = ""
    @State private var selectedColor: String = "blue"
    
    init(category: CategoryEntity?, isEditing: Bool, availableColors: [String], onSave: @escaping (String, String) -> Void) {
        self.category = category
        self.isEditing = isEditing
        self.availableColors = availableColors
        self.onSave = onSave
        
        // Initialize state variables based on category
        _categoryName = State(initialValue: category?.name ?? "")
        _selectedColor = State(initialValue: category?.color ?? "blue")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text(isEditing ? "Edit Category" : "New Category")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .padding(.top, 20)
                .padding(.bottom, 16)
            
            // Category name
            VStack(alignment: .leading, spacing: 8) {
                Text("Category Name")
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                TextField("e.g., Kitchen, Bathroom", text: $categoryName)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.8))
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    )
            }
            .padding(.horizontal)
            
            // Color selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Category Color")
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .padding(.top, 16)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(availableColors, id: \.self) { color in
                            ColorButton(
                                color: Color(color),
                                isSelected: selectedColor == color,
                                action: {
                                    selectedColor = color
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 15) {
                Button(action: {
                    dismiss()
                }) {
                    Text("Cancel")
                        .fontWeight(.medium)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(colorScheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(0.3), lineWidth: 1)
                        )
                }
                
                Button(action: {
                    if !categoryName.isEmpty {
                        onSave(categoryName, selectedColor)
                        dismiss()
                    }
                }) {
                    Text(isEditing ? "Update" : "Add")
                        .fontWeight(.medium)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(colorScheme == .dark ? Color.blue.opacity(0.7) : Color.blue)
                        )
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
                .disabled(categoryName.isEmpty)
                .opacity(categoryName.isEmpty ? 0.6 : 1)
            }
            .padding()
        }
        .background(
            colorScheme == .dark ? Color.black : Color.white
        )
    }
}

struct ColorButton: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 36, height: 36)
                
                if isSelected {
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 2)
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
        }
    }
} 