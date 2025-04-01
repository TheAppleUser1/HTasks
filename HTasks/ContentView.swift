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
        self.title = title
        self.isCompleted = isCompleted
        self.categoryId = categoryId
        self.createdDate = createdDate
        self.dueDate = dueDate
    }
    
    init(from entity: TaskEntity) {
        self.id = entity.id ?? UUID()
        self.title = entity.title ?? "Untitled"
        self.isCompleted = entity.isCompleted
        self.categoryId = entity.category?.id
        self.createdDate = entity.createdDate ?? Date()
        self.dueDate = entity.dueDate
    }
}

struct UserSettings: Codable {
    var showDeleteConfirmation: Bool = true
    var deleteConfirmationText: String = "We offer no liability if your mother gets mad :P"
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

#Preview {
    ContentView()
}

