import UIKit
import Core

/// App delegate for handling remote notifications and app lifecycle events
/// Swift 5.9 - No Swift 6 features
class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
        
        // Check for notification permissions on app launch
        Task {
            await NotificationManager.shared.checkAuthorizationStatus()
        }
        
        return true
    }
    
    // MARK: - Remote Notifications
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NotificationManager.shared.registerDeviceToken(deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NotificationManager.shared.registrationFailed(error)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Handle remote notification
        // For now, just complete with new data
        completionHandler(.newData)
    }
    
    // MARK: - Background Tasks
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Schedule background tasks if needed
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Refresh notification status
        NotificationManager.shared.checkAuthorizationStatus()
    }
}