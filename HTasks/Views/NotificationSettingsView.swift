import SwiftUI

struct NotificationSettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    
    private let weekDays = [
        (1, "Monday"),
        (2, "Tuesday"),
        (3, "Wednesday"),
        (4, "Thursday"),
        (5, "Friday"),
        (6, "Saturday"),
        (7, "Sunday")
    ]
    
    var body: some View {
        Form {
            Section(header: Text("Notifications")) {
                Toggle("Enable Notifications", isOn: $notificationManager.isNotificationsEnabled)
                
                if notificationManager.isNotificationsEnabled {
                    DatePicker("Reminder Time", selection: $notificationManager.reminderTime, displayedComponents: .hourAndMinute)
                    
                    ForEach(weekDays, id: \.0) { day in
                        Toggle(day.1, isOn: Binding(
                            get: { notificationManager.reminderDays.contains(day.0) },
                            set: { isSelected in
                                if isSelected {
                                    notificationManager.reminderDays.insert(day.0)
                                } else {
                                    notificationManager.reminderDays.remove(day.0)
                                }
                            }
                        ))
                    }
                }
            }
        }
        .navigationTitle("Notification Settings")
    }
} 