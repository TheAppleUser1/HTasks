//
//  HTasksApp.swift
//  HTasks
//
//  Created by Apple on 2025. 03. 29..
//

import SwiftUI
import CoreData

@main
struct HTasksApp: App {
    @StateObject private var coreDataManager = CoreDataManager.shared
    @StateObject private var achievementManager = AchievementManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(coreDataManager)
                .environmentObject(achievementManager)
                .onAppear {
                    // Setup default data in Core Data
                    coreDataManager.setupDefaultData()
                }
        }
    }
}
