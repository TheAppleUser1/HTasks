import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var coreDataManager: CoreDataManager
    @State private var showingCategoryManagement = false
    @State private var showingNotificationSettings = false
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("useSystemTheme") private var useSystemTheme = true
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Appearance")) {
                    Toggle("Use System Theme", isOn: $useSystemTheme)
                    if !useSystemTheme {
                        Toggle("Dark Mode", isOn: $isDarkMode)
                    }
                }
                
                Section(header: Text("Categories")) {
                    Button(action: { showingCategoryManagement = true }) {
                        HStack {
                            Text("Manage Categories")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section(header: Text("Notifications")) {
                    Button(action: { showingNotificationSettings = true }) {
                        HStack {
                            Text("Notification Settings")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
            .navigationBarItems(leading: Button("Done") { dismiss() })
            .sheet(isPresented: $showingCategoryManagement) {
                CategoryManagementView()
            }
            .sheet(isPresented: $showingNotificationSettings) {
                NotificationSettingsView()
            }
        }
    }
} 