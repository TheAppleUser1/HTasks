import SwiftUI
import CoreData

struct HomeView: View {
    @EnvironmentObject private var coreDataManager: CoreDataManager
    @State private var showingAddTask = false
    @State private var showingEditTask = false
    @State private var showingCategoryPicker = false
    @State private var selectedTask: TaskEntity?
    @State private var selectedCategory: CategoryEntity?
    @State private var searchText = ""
    @Binding var chores: [Chore]
    @State private var choreToDelete: Chore?
    @State private var showingDeleteAlert = false
    @State private var showingAddChoreSheet = false
    @State private var showingSettingsSheet = false
    @State private var newChoreTitle = ""
    @State private var newChoreDueDate: Date? = nil
    @State private var settings = UserSettings()
    @Environment(\.colorScheme) var colorScheme
    
    var filteredTasks: [TaskEntity] {
        let tasks = coreDataManager.fetchTasks()
        return tasks.filter { task in
            let matchesCategory = selectedCategory == nil || task.category == selectedCategory
            let matchesSearch = searchText.isEmpty || 
                (task.title?.localizedCaseInsensitiveContains(searchText) ?? false)
            return matchesCategory && matchesSearch
        }
    }
    
    var completedChoresCount: Int {
        chores.filter { $0.isCompleted }.count
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // VisionOS style header with completed chores count
                VStack(alignment: .leading, spacing: 8) {
                    Text("Number of chores done this week:")
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                    
                    HStack(alignment: .bottom, spacing: 8) {
                        Text("\(completedChoresCount)")
                            .font(.system(size: 60, weight: .bold, design: .rounded))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        
                        if completedChoresCount == 0 {
                            Text("u lazy or sum?")
                                .font(.system(size: 12))
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6))
                                .padding(.bottom, 12)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
                )
                .padding(.horizontal)
                .padding(.top)
                
                // Chore list with VisionOS-style design
                List {
                    ForEach(chores) { chore in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(chore.title)
                                    .font(.headline)
                                    .foregroundColor(
                                        chore.isCompleted ? 
                                            (colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.5)) : 
                                            (colorScheme == .dark ? .white : .black)
                                    )
                                    .strikethrough(chore.isCompleted)
                                
                                if let dueDate = chore.dueDate {
                                    Text(dueDate, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Spacer()
                            
                            // Checkmark button
                            Button(action: {
                                toggleChoreCompletion(chore)
                            }) {
                                Image(systemName: chore.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.title2)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .padding(5)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            
                            // Delete button
                            Button(action: {
                                choreToDelete = chore
                                if settings.showDeleteConfirmation {
                                    showingDeleteAlert = true
                                } else {
                                    deleteChore(chore)
                                }
                            }) {
                                Image(systemName: "trash.fill")
                                    .font(.title2)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .padding(5)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                        .padding(.vertical, 8)
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.8))
                                .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                        )
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                }
                .listStyle(PlainListStyle())
                .background(Color.clear)
                .alert(isPresented: $showingDeleteAlert) {
                    Alert(
                        title: Text("Are you sure you want to delete this chore?"),
                        message: Text(settings.deleteConfirmationText),
                        primaryButton: .destructive(Text("Delete").foregroundColor(colorScheme == .dark ? .white : .black)) {
                            if let choreToDelete = choreToDelete {
                                deleteChore(choreToDelete)
                            }
                        },
                        secondaryButton: .cancel(Text("No").foregroundColor(colorScheme == .dark ? .white : .black))
                    )
                }
            }
            
            // Floating add button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showingAddChoreSheet = true
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
        .navigationTitle("My Chores")
        .navigationBarItems(trailing: 
            Button(action: {
                showingSettingsSheet = true
            }) {
                Image(systemName: "gear")
                    .font(.title2)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .padding(8)
                    .contentShape(Rectangle())
            }
        )
        .background(
            LinearGradient(
                gradient: Gradient(colors: colorScheme == .dark ? 
                                  [Color.black, Color.blue.opacity(0.2)] : 
                                  [Color.white, Color.blue.opacity(0.1)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
        )
        .sheet(isPresented: $showingAddChoreSheet) {
            // Add chore sheet
            VStack(spacing: 20) {
                Text("Add New Chore")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                TextField("Chore name", text: $newChoreTitle)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.8))
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    )
                    .padding(.horizontal)
                
                // Add due date picker
                DatePicker(
                    "Due Date",
                    selection: Binding(
                        get: { newChoreDueDate ?? Date() },
                        set: { newChoreDueDate = $0 }
                    ),
                    displayedComponents: [.date]
                )
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.8))
                )
                .padding(.horizontal)
                
                HStack(spacing: 15) {
                    Button(action: {
                        showingAddChoreSheet = false
                        newChoreDueDate = nil  // Reset due date
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
                        if !newChoreTitle.isEmpty {
                            let newChore = Chore(title: newChoreTitle, dueDate: newChoreDueDate)
                            chores.append(newChore)
                            saveChores()
                            newChoreTitle = ""
                            newChoreDueDate = nil
                            showingAddChoreSheet = false
                        }
                    }) {
                        Text("Add")
                            .fontWeight(.medium)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(colorScheme == .dark ? Color.blue.opacity(0.7) : Color.blue)
                            )
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 30)
            .background(
                colorScheme == .dark ? Color.black : Color.white
            )
            .presentationDetents([.height(350)])  // Increase height to accommodate date picker
        }
        .sheet(isPresented: $showingSettingsSheet) {
            // Settings sheet
            VStack(spacing: 24) {
                Text("Settings")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("Customization")
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    Toggle("Show Confirmation when clicking delete", isOn: $settings.showDeleteConfirmation)
                        .onChange(of: settings.showDeleteConfirmation) { _, newValue in
                            saveSettings()
                        }
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Change the Confirmation text when clicking delete")
                            .foregroundColor(settings.showDeleteConfirmation ? 
                                            (colorScheme == .dark ? .white : .black) : 
                                            (colorScheme == .dark ? .white.opacity(0.4) : .black.opacity(0.4)))
                        
                        TextField("Confirmation message", text: $settings.deleteConfirmationText)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.8))
                                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            )
                            .disabled(!settings.showDeleteConfirmation)
                            .opacity(settings.showDeleteConfirmation ? 1.0 : 0.4)
                            .onChange(of: settings.deleteConfirmationText) { _, newValue in
                                saveSettings()
                            }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button(action: {
                    showingSettingsSheet = false
                }) {
                    Text("Done")
                        .fontWeight(.medium)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(colorScheme == .dark ? Color.blue.opacity(0.7) : Color.blue)
                        )
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
                .padding()
            }
            .background(
                colorScheme == .dark ? Color.black : Color.white
            )
            .presentationDetents([.medium])
        }
        .onAppear {
            loadSettings()
        }
    }
    
    private func toggleChoreCompletion(_ chore: Chore) {
        if let index = chores.firstIndex(where: { $0.id == chore.id }) {
            chores[index].isCompleted.toggle()
            saveChores()
        }
    }
    
    private func deleteChore(_ chore: Chore) {
        if let index = chores.firstIndex(where: { $0.id == chore.id }) {
            chores.remove(at: index)
            saveChores()
        }
    }
    
    private func saveChores() {
        do {
            let encoded = try JSONEncoder().encode(chores)
            UserDefaults.standard.set(encoded, forKey: "savedChores")
            UserDefaults.standard.synchronize()
            print("Successfully saved \(chores.count) chores from HomeView")
        } catch {
            print("Failed to encode chores: \(error.localizedDescription)")
        }
    }
    
    private func loadSettings() {
        if let savedSettings = UserDefaults.standard.data(forKey: "userSettings") {
            do {
                let decodedSettings = try JSONDecoder().decode(UserSettings.self, from: savedSettings)
                self.settings = decodedSettings
                print("Loaded user settings from UserDefaults")
            } catch {
                print("Failed to decode settings: \(error.localizedDescription)")
            }
        } else {
            // Use default settings already initialized
            print("No saved settings found in UserDefaults, using defaults")
        }
    }
    
    private func saveSettings() {
        do {
            let encoded = try JSONEncoder().encode(settings)
            UserDefaults.standard.set(encoded, forKey: "userSettings")
            UserDefaults.standard.synchronize()
            print("Successfully saved user settings")
        } catch {
            print("Failed to encode settings: \(error.localizedDescription)")
        }
    }
} 