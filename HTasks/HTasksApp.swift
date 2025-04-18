import SwiftUI
import FirebaseCore
import FirebaseMessaging
import UserNotifications

// AppDelegate to handle push notification setup and callbacks
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Set delegates
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        
        // Request permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            print("Notification permission granted: \(granted)")
            guard granted else { return }
            // Get the notification settings to check authorization status
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                guard settings.authorizationStatus == .authorized else { return }
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }
        return true
    }
    
    // Handle APNs registration success
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        print("Registered for Remote Notifications with token: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
    }
    
    // Handle APNs registration failure
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    // Receive FCM token
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(fcmToken ?? "nil")")
        guard let token = fcmToken else { return }
        // TODO: Save the token to Firestore for the logged-in user
        FirebaseService.shared.updateUserFCMToken(token: token)
    }
    
    // Handle notification presentation while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        print("Received foreground notification: \(userInfo)")
        // Show alert, sound, badge
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle user tapping on notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("Received background/tapped notification: \(userInfo)")
        // Handle the tap action, e.g., navigate to a specific view
        completionHandler()
    }
}

@main
struct HTasksApp: App {
    // Inject the App Delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
} 