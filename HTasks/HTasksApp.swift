//
//  HTasksApp.swift
//  HTasks
//
//  Created by Apple on 2025. 03. 29..
//

import SwiftUI
import CoreData
import WidgetKit

@main
struct HTasksApp: App {
    @StateObject private var coreDataManager = CoreDataManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    
    init() {
        // Setup UI appearance
        UINavigationBar.appearance().tintColor = .label
    }
    
    func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(coreDataManager)
                .environmentObject(notificationManager)
                .onAppear {
                    // Setup default data in Core Data
                    coreDataManager.setupDefaultData()
                    
                    // Request notification permissions
                    notificationManager.requestAuthorization()
                    
                    // Reload widgets
                    reloadWidgets()
                }
                .onChange(of: coreDataManager.viewContext.hasChanges) { _, _ in
                    reloadWidgets()
                }
        }
    }
}
