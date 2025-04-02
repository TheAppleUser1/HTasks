import Foundation
import UserNotifications
import CoreData

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isNotificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isNotificationsEnabled, forKey: "notificationsEnabled")
            if isNotificationsEnabled {
                requestPermission()
            }
        }
    }
    
    @Published var reminderTime: Date {
        didSet {
            UserDefaults.standard.set(reminderTime, forKey: "reminderTime")
            scheduleNotifications()
        }
    }
    
    @Published var reminderDays: Set<Int> {
        didSet {
            UserDefaults.standard.set(Array(reminderDays), forKey: "reminderDays")
            scheduleNotifications()
        }
    }
    
    private init() {
        self.isNotificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        self.reminderTime = UserDefaults.standard.object(forKey: "reminderTime") as? Date ?? Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        self.reminderDays = Set(UserDefaults.standard.array(forKey: "reminderDays") as? [Int] ?? [1, 2, 3, 4, 5])
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isNotificationsEnabled = granted
                if granted {
                    self.scheduleNotifications()
                }
            }
        }
    }
    
    func scheduleNotifications() {
        guard isNotificationsEnabled else { return }
        
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        let calendar = Calendar.current
        
        for day in reminderDays {
            var components = calendar.dateComponents([.hour, .minute], from: reminderTime)
            components.weekday = day
            
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
    
    func scheduleTaskReminder(for task: TaskEntity) {
        guard isNotificationsEnabled, let dueDate = task.dueDate else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Task Due"
        content.body = "\(task.title ?? "Task") is due today"
        content.sound = .default
        
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        components.hour = 9
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "task-\(task.id?.uuidString ?? UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelTaskReminder(for task: TaskEntity) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["task-\(task.id?.uuidString ?? UUID().uuidString)"]
        )
    }
} 