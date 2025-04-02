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
    @StateObject private var notificationManager = NotificationManager.shared
    
    init() {
        ValueTransformer.setValueTransformer(
            UIColorTransformer(),
            forName: NSValueTransformerName("UIColorTransformer")
        )
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(coreDataManager)
                .environmentObject(notificationManager)
        }
    }
}
