//
//  HTasksApp.swift
//  HTasks
//
//  Created by Apple on 2025. 03. 29..
//

import SwiftUI

@main
struct HTasksApp: App {
    @State private var showWelcome = true
    
    var body: some Scene {
        WindowGroup {
            if showWelcome {
                WelcomeView()
                    .onAppear {
                        // Transition to main view after animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation {
                                showWelcome = false
                            }
                        }
                    }
            } else {
                ContentView()
            }
        }
    }
}
