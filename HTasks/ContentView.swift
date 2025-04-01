//
//  ContentView.swift
//  HTasks
//
//  Created by Apple on 2025. 03. 29..
//

import SwiftUI
import WidgetKit

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

struct ContentView: View {
    @State private var isWelcomeActive = true
    @State private var chores: [Chore] = []
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            if isWelcomeActive {
                WelcomeView(chores: $chores, isWelcomeActive: $isWelcomeActive)
            } else {
                HomeView(chores: $chores)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            loadChores()
            
            // Check if we should skip welcome screen
            let hasSeenWelcome = UserDefaults.standard.bool(forKey: "hasSeenWelcome")
            if hasSeenWelcome && !chores.isEmpty {
                isWelcomeActive = false
            }
        }
    }
    
    private func loadChores() {
        if let savedChores = UserDefaults.standard.data(forKey: "savedChores") {
            do {
                let decodedChores = try JSONDecoder().decode([Chore].self, from: savedChores)
                self.chores = decodedChores
                print("Loaded \(decodedChores.count) chores from UserDefaults")
            } catch {
                print("Failed to decode chores: \(error.localizedDescription)")
            }
        } else {
            print("No saved chores found in UserDefaults")
        }
    }
}

struct WelcomeView: View {
    @Binding var chores: [Chore]
    @Binding var isWelcomeActive: Bool
    @State private var newChore: String = ""
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var coreDataManager: CoreDataManager
    
    let presetChores = [
        "Wash the dishes",
        "Clean the Windows",
        "Mop the Floor",
        "Clean your room"
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to HTasks!")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            Text("Choose basic chores you want to do at home and get motivated!")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
            
            // Chore input field with modern styling
            TextField("Type your own chore", text: $newChore)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.8))
                )
                .padding(.horizontal)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            Button(action: {
                if !newChore.isEmpty {
                    addChore(newChore)
                    newChore = ""
                }
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Chore")
                }
                .fontWeight(.semibold)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? Color.blue.opacity(0.7) : Color.blue)
                )
                .foregroundColor(colorScheme == .dark ? .white : .black)
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Presets:")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .padding(.leading)
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(presetChores, id: \.self) { preset in
                            Button(action: {
                                addChore(preset)
                            }) {
                                HStack {
                                    Text(preset)
                                        .font(.headline)
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.8))
                                        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.1) : Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                )
                                .padding(EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4))
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            if !chores.isEmpty {
                Button(action: {
                    isWelcomeActive = false
                    // Mark that user has seen welcome screen
                    UserDefaults.standard.set(true, forKey: "hasSeenWelcome")
                    UserDefaults.standard.synchronize()
                }) {
                    HStack {
                        Text("Continue")
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .fontWeight(.semibold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color.green.opacity(0.7) : Color.green)
                    )
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .navigationBarHidden(true)
        .padding()
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
    }
    
    private func addChore(_ title: String) {
        let newChore = Chore(
            title: title,
            isCompleted: false,
            categoryId: nil,
            createdDate: Date(),
            dueDate: nil
        )
        chores.append(newChore)
        saveChores()
    }
    
    private func saveChores() {
        do {
            // Save the full chore data for the app to UserDefaults
            let encoded = try JSONEncoder().encode(chores)
            UserDefaults.standard.set(encoded, forKey: "savedChores")
            
            // Create detailed chore objects for the widget including categories and due dates
            let widgetChores = chores.map { chore -> [String: Any] in
                var choreDict: [String: Any] = [
                    "id": chore.id.uuidString,
                    "title": chore.title,
                    "isCompleted": chore.isCompleted,
                    "createdDate": ["timestamp": chore.createdDate.timeIntervalSince1970]
                ]
                
                // Add category information if available
                if let categoryId = chore.categoryId {
                    choreDict["categoryId"] = categoryId.uuidString
                    
                    if let category = getCategory(for: categoryId) {
                        choreDict["categoryName"] = category.name
                        choreDict["categoryColor"] = category.color
                    }
                } else {
                    choreDict["categoryId"] = NSNull()
                    choreDict["categoryName"] = NSNull()
                    choreDict["categoryColor"] = NSNull()
                }
                
                // Add due date if available
                if let dueDate = chore.dueDate {
                    choreDict["dueDate"] = ["timestamp": dueDate.timeIntervalSince1970]
                } else {
                    choreDict["dueDate"] = NSNull()
                }
                
                return choreDict
            }
            
            // Save to the shared App Group container for widget access
            let widgetData = try JSONSerialization.data(withJSONObject: widgetChores)
            if let userDefaults = UserDefaults(suiteName: "group.com.yourdomain.HTasks") {
                userDefaults.set(widgetData, forKey: "widgetChores")
            } else {
                // Fallback to standard UserDefaults if app group is not available
                UserDefaults.standard.set(widgetData, forKey: "widgetChores")
            }
            
            // Tell the widget to refresh with new data
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Failed to save chores: \(error)")
        }
    }
}

struct HomeView: View {
    @Binding var chores: [Chore]
    @State private var choreToDelete: Chore?
    @State private var showingDeleteAlert = false
    @State private var showingAddChoreSheet = false
    @State private var showingSettingsSheet = false
    @State private var settings = UserSettings()
    @State private var newChoreTitle = ""
    @State private var presentCategoryManagement = false
    @State private var presentAnalytics = false
    @State private var selectedCategoryId: UUID?
    @State private var dueDate = Date()
    @State private var showingDueDatePicker = false
    @EnvironmentObject private var coreDataManager: CoreDataManager
    @Environment(\.colorScheme) var colorScheme
    
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
                            // Try to find category for this chore
                            let category = getCategory(for: chore.categoryId)
                            
                            Text(chore.title)
                                .font(.headline)
                                .foregroundColor(
                                    chore.isCompleted ? 
                                        (colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.5)) : 
                                        (colorScheme == .dark ? .white : .black)
                                )
                                .strikethrough(chore.isCompleted)
                            
                            if let category = category {
                                Circle()
                                    .fill(Color(category.color ?? "blue"))
                                    .frame(width: 8, height: 8)
                                    .padding(.leading, 4)
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
            NavigationView {
                VStack(spacing: 20) {
                    Form {
                        Section(header: Text("Chore Details")) {
                            TextField("Chore name", text: $newChoreTitle)
                                .padding(.vertical, 8)
                            
                            // Category Picker
                            HStack {
                                Text("Category")
                                Spacer()
                                NavigationLink {
                                    CategoryPickerView(selectedCategoryId: $selectedCategoryId)
                                } label: {
                                    HStack {
                                        if let selectedCategory = getSelectedCategory() {
                                            Circle()
                                                .fill(Color(selectedCategory.color ?? "blue"))
                                                .frame(width: 12, height: 12)
                                            Text(selectedCategory.name ?? "")
                                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                                        } else {
                                            Text("None")
                                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                            
                            // Due Date
                            Toggle("Set Due Date", isOn: $showingDueDatePicker)
                                .padding(.vertical, 8)
                            
                            if showingDueDatePicker {
                                DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date])
                                    .datePickerStyle(GraphicalDatePickerStyle())
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(colorScheme == .dark ? Color.black : Color.white)

                    HStack(spacing: 15) {
                        Button(action: {
                            showingAddChoreSheet = false
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
                                let newChore = Chore(
                                    title: newChoreTitle,
                                    categoryId: selectedCategoryId,
                                    createdDate: Date(),
                                    dueDate: showingDueDatePicker ? dueDate : nil
                                )
                                chores.append(newChore)
                                saveChores()
                                newChoreTitle = ""
                                selectedCategoryId = nil
                                dueDate = Date()
                                showingDueDatePicker = false
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
                        .disabled(newChoreTitle.isEmpty)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .navigationTitle("Add New Chore")
                .navigationBarHidden(true)
            }
            .onAppear {
                resetForm()
            }
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
                
                // Add navigation buttons to new screens
                VStack(alignment: .leading, spacing: 20) {
                    Text("Organization")
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    // Categories Button
                    Button(action: {
                        showingSettingsSheet = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            presentCategoryManagement = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "tag.fill")
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            Text("Manage Categories")
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6))
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.8))
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        )
                    }
                    
                    // Analytics Button
                    Button(action: {
                        showingSettingsSheet = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            presentAnalytics = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            Text("Analytics & Achievements")
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6))
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.8))
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        )
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
        .sheet(isPresented: $presentCategoryManagement) {
            CategoryManagementView()
        }
        .sheet(isPresented: $presentAnalytics) {
            AnalyticsView()
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
            // Save the full chore data for the app to UserDefaults
            let encoded = try JSONEncoder().encode(chores)
            UserDefaults.standard.set(encoded, forKey: "savedChores")
            
            // Create detailed chore objects for the widget including categories and due dates
            let widgetChores = chores.map { chore -> [String: Any] in
                var choreDict: [String: Any] = [
                    "id": chore.id.uuidString,
                    "title": chore.title,
                    "isCompleted": chore.isCompleted,
                    "createdDate": ["timestamp": chore.createdDate.timeIntervalSince1970]
                ]
                
                // Add category information if available
                if let categoryId = chore.categoryId {
                    choreDict["categoryId"] = categoryId.uuidString
                    
                    if let category = getCategory(for: categoryId) {
                        choreDict["categoryName"] = category.name
                        choreDict["categoryColor"] = category.color
                    }
                } else {
                    choreDict["categoryId"] = NSNull()
                    choreDict["categoryName"] = NSNull()
                    choreDict["categoryColor"] = NSNull()
                }
                
                // Add due date if available
                if let dueDate = chore.dueDate {
                    choreDict["dueDate"] = ["timestamp": dueDate.timeIntervalSince1970]
                } else {
                    choreDict["dueDate"] = NSNull()
                }
                
                return choreDict
            }
            
            // Save to the shared App Group container for widget access
            let widgetData = try JSONSerialization.data(withJSONObject: widgetChores)
            if let userDefaults = UserDefaults(suiteName: "group.com.yourdomain.HTasks") {
                userDefaults.set(widgetData, forKey: "widgetChores")
            } else {
                // Fallback to standard UserDefaults if app group is not available
                UserDefaults.standard.set(widgetData, forKey: "widgetChores")
            }
            
            // Tell the widget to refresh with new data
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Failed to save chores: \(error)")
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
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: "userSettings")
            UserDefaults.standard.synchronize()
            print("Successfully saved settings")
        }
    }
    
    private func resetForm() {
        newChoreTitle = ""
        selectedCategoryId = nil
        dueDate = Date()
        showingDueDatePicker = false
    }
    
    private func getSelectedCategory() -> CategoryEntity? {
        guard let categoryId = selectedCategoryId else { return nil }
        
        let categories = coreDataManager.fetchCategories()
        return categories.first { $0.id?.uuidString == categoryId.uuidString }
    }
    
    private func getCategory(for categoryId: UUID?) -> CategoryEntity? {
        guard let categoryId = categoryId else { return nil }
        
        let categories = coreDataManager.fetchCategories()
        return categories.first { $0.id?.uuidString == categoryId.uuidString }
    }
}

struct CategoryPickerView: View {
    @Binding var selectedCategoryId: UUID?
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var coreDataManager: CoreDataManager
    @State private var categories: [CategoryEntity] = []
    
    var body: some View {
        List {
            Button {
                selectedCategoryId = nil
                dismiss()
            } label: {
                HStack {
                    Text("No Category")
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    Spacer()
                    
                    if selectedCategoryId == nil {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
            }
            .listRowBackground(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.8))
                    .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
            )
            
            ForEach(categories, id: \.id) { category in
                Button {
                    selectedCategoryId = category.id as UUID?
                    dismiss()
                } label: {
                    HStack {
                        Circle()
                            .fill(Color(category.color ?? "blue"))
                            .frame(width: 16, height: 16)
                        
                        Text(category.name ?? "")
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        
                        Spacer()
                        
                        if let selectedId = selectedCategoryId, selectedId == category.id as UUID? {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.8))
                        .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                )
            }
        }
        .listStyle(PlainListStyle())
        .navigationTitle("Select Category")
        .onAppear {
            loadCategories()
        }
    }
    
    private func loadCategories() {
        categories = coreDataManager.fetchCategories()
    }
}

extension Category {
    init(from entity: CategoryEntity) {
        self.id = entity.id ?? UUID()
        self.name = entity.name ?? "Unnamed"
        self.color = entity.color ?? "blue"
    }
}

#Preview {
    ContentView()
}
