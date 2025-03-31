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
        // Setup
        UINavigationBar.appearance().tintColor = .label
        
        // Request notification permissions
        Task {
            _ = await notificationManager.requestAuthorization()
        }
        
        // Setup CoreData
        coreDataManager.setupDefaultData()
        
        // Reload widgets
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Force-unwrap is safe here as we're not actually using the result
                    _ = coreDataManager.viewContext
                }
        }
    }
}
