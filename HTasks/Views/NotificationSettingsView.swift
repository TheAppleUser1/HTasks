import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("reminderTime") private var reminderTime = Date()
    @AppStorage("reminderDays") private var reminderDays = Set<Int>([1, 2, 3, 4, 5]) // Monday to Friday
    
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
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    .onChange(of: notificationsEnabled) { newValue in
                        if newValue {
                            requestNotificationPermission()
                        }
                    }
                
                if notificationsEnabled {
                    DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .onChange(of: reminderTime) { _ in
                            updateNotificationSchedule()
                        }
                    
                    ForEach(weekDays, id: \.0) { day in
                        Toggle(day.1, isOn: Binding(
                            get: { reminderDays.contains(day.0) },
                            set: { isSelected in
                                if isSelected {
                                    reminderDays.insert(day.0)
                                } else {
                                    reminderDays.remove(day.0)
                                }
                                updateNotificationSchedule()
                            }
                        ))
                    }
                }
            }
        }
        .navigationTitle("Notification Settings")
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
    }
    
    private func updateNotificationSchedule() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        guard notificationsEnabled else { return }
        
        let calendar = Calendar.current
        let now = Date()
        
        for day in reminderDays {
            var components = calendar.dateComponents([.hour, .minute], from: reminderTime)
            components.weekday = day
            
            if let nextDate = calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime) {
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let content = UNMutableNotificationContent()
                content.title = "Task Reminder"
                content.body = "Check your tasks for today"
                content.sound = .default
                
                let request = UNNotificationRequest(
                    identifier: "taskReminder-\(day)",
                    content: content,
                    trigger: trigger
                )
                
                UNUserNotificationCenter.current().add(request)
            }
        }
    }
} 