import SwiftUI
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private let center = UNUserNotificationCenter.current()
    @Published var isAuthorized = false
    
    private init() {
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            print("Error requesting notification permission: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Scheduling Notifications
    
    func scheduleReminderNotification(for chore: ChoreEntity) {
        guard isAuthorized else {
            print("Notifications not authorized")
            return
        }
        
        // Skip if no due date
        guard let dueDate = chore.dueDate else {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Chore Reminder"
        content.body = "Don't forget to \(chore.title ?? "complete your chore")"
        content.sound = .default
        
        // Add category info if available
        if let category = chore.category?.name {
            content.subtitle = "Category: \(category)"
        }
        
        // Set higher priority notification for high priority chores
        if chore.priority > 1 {
            content.interruptionLevel = .timeSensitive
        }
        
        // Schedule for:
        // 1. One hour before due date
        // 2. At due date time
        // 3. Day after due date if still not completed
        
        // Calculate trigger times
        let oneHourBefore = Calendar.current.date(byAdding: .hour, value: -1, to: dueDate)
        
        if let oneHourBefore = oneHourBefore, oneHourBefore > Date() {
            scheduleTimedNotification(
                for: chore.id?.uuidString ?? UUID().uuidString + "-reminder1",
                title: "Chore Coming Up",
                body: "You have \"\(chore.title ?? "a chore")\" due in an hour",
                date: oneHourBefore,
                categoryInfo: chore.category?.name
            )
        }
        
        if dueDate > Date() {
            scheduleTimedNotification(
                for: chore.id?.uuidString ?? UUID().uuidString + "-reminder2",
                title: "Chore Due Now",
                body: "Time to \(chore.title ?? "complete your chore")",
                date: dueDate,
                categoryInfo: chore.category?.name
            )
        }
        
        // Day after reminder only for non-completed chores
        let dayAfter = Calendar.current.date(byAdding: .day, value: 1, to: dueDate)
        if let dayAfter = dayAfter, dayAfter > Date() {
            scheduleTimedNotification(
                for: chore.id?.uuidString ?? UUID().uuidString + "-reminder3",
                title: "Overdue Chore",
                body: "\(chore.title ?? "Your chore") is overdue",
                date: dayAfter,
                categoryInfo: chore.category?.name
            )
        }
    }
    
    func scheduleTimedNotification(for identifier: String, title: String, body: String, date: Date, categoryInfo: String? = nil) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        if let categoryInfo = categoryInfo {
            content.subtitle = "Category: \(categoryInfo)"
        }
        
        // Create date components from date
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // Create request
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Add request
        center.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleMotivationalNotification(for streak: StreakEntity) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Keep Your Streak Going!"
        
        // Different messages based on streak length
        if streak.currentStreak >= 7 {
            content.body = "Amazing! You've completed chores for \(streak.currentStreak) days in a row. Keep it up!"
        } else if streak.currentStreak >= 3 {
            content.body = "Great job! You're on a \(streak.currentStreak)-day streak. Don't break the chain!"
        } else {
            content.body = "You're on a \(streak.currentStreak)-day streak. Complete a chore today to keep it going!"
        }
        
        content.sound = .default
        
        // Schedule for 10am if no chore has been completed by then
        var components = DateComponents()
        components.hour = 10
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "streak-reminder",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Error scheduling streak notification: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleAchievementNotification(for achievement: AchievementEntity) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Achievement Unlocked!"
        content.body = "You've earned the \"\(achievement.name ?? "")\" achievement!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "achievement-\(achievement.id?.uuidString ?? UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Error scheduling achievement notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Cancel Notifications
    
    func cancelNotification(for choreId: UUID?) {
        guard let id = choreId?.uuidString else { return }
        
        center.removePendingNotificationRequests(withIdentifiers: [
            id + "-reminder1",
            id + "-reminder2",
            id + "-reminder3",
            id
        ])
    }
    
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }
    
    // MARK: - Utility Methods
    
    func generateMotivationalMessage() -> String {
        let messages = [
            "You've got this! One chore at a time.",
            "Small steps lead to big changes.",
            "Progress is progress, no matter how small.",
            "Keep going! Future you will thank present you.",
            "Consistency is the key to success.",
            "Building good habits starts with one task.",
            "Every completed chore is a win!",
            "You're crushing it!",
            "Momentum builds with each task you complete.",
            "Your future self is proud of your current self."
        ]
        
        return messages.randomElement() ?? messages[0]
    }
} 