import SwiftUI
import FirebaseCore

@main
struct HTasksApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
} 