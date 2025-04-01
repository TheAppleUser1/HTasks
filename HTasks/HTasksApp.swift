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
        
        // Setup CoreData
        coreDataManager.setupDefaultData()
        
        // Reload widgets
        reloadWidgets()
    }
    
    func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(coreDataManager)
                .onAppear {
                    // Request notification permissions
                    NotificationManager.shared.requestAuthorization()
                }
                .onChange(of: coreDataManager.viewContext.hasChanges) { _, _ in
                    reloadWidgets()
                }
        }
    }
}
