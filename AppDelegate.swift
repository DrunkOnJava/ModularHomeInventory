import UIKit
import Core
// import GoogleSignIn // TODO: Enable once Gmail module is integrated

/// App delegate for handling remote notifications and app lifecycle events
/// Swift 5.9 - No Swift 6 features
class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Initialize crash reporting
        setupCrashReporting()
        
        // Check for previous crash
        checkForPreviousCrash()
        
        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
        
        // Check for notification permissions on app launch
        Task {
            await NotificationManager.shared.checkAuthorizationStatus()
        }
        
        return true
    }
    
    // MARK: - Crash Reporting
    
    private func setupCrashReporting() {
        // Check if crash reporting is enabled in settings
        let settingsStorage = UserDefaultsSettingsStorage()
        let isEnabled = settingsStorage.bool(forKey: .crashReportingEnabled) ?? true
        
        // Enable crash reporting
        CrashReportingService.shared.setEnabled(isEnabled)
        
        // Set up automatic sending if enabled
        if isEnabled && (settingsStorage.bool(forKey: .crashReportingAutoSend) ?? true) {
            Task {
                // Wait a bit before sending to not interfere with app launch
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                
                // Send pending reports
                try? await CrashReportingService.shared.sendPendingReports()
            }
        }
    }
    
    private func checkForPreviousCrash() {
        // Check if app crashed last time
        let crashedLastTime = UserDefaults.standard.bool(forKey: "app_crashed_last_time")
        
        if crashedLastTime {
            // App recovered from crash
            CrashReportingService.shared.reportNonFatal(
                "App recovered from previous crash",
                userInfo: ["recovery": "true"]
            )
            
            // Clear the flag
            UserDefaults.standard.set(false, forKey: "app_crashed_last_time")
        }
        
        // Set flag that we're running
        UserDefaults.standard.set(true, forKey: "app_crashed_last_time")
    }
    
    // MARK: - Remote Notifications
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NotificationManager.shared.registerDeviceToken(deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NotificationManager.shared.registrationFailed(error)
        
        // Report notification registration failure as non-fatal
        CrashReportingService.shared.reportError(
            error,
            userInfo: ["context": "push_notification_registration"]
        )
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Handle remote notification
        // For now, just complete with new data
        completionHandler(.newData)
    }
    
    // MARK: - Background Tasks
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Clear crash flag when entering background normally
        UserDefaults.standard.set(false, forKey: "app_crashed_last_time")
        
        // Schedule background tasks if needed
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Refresh notification status
        NotificationManager.shared.checkAuthorizationStatus()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Clear crash flag when terminating normally
        UserDefaults.standard.set(false, forKey: "app_crashed_last_time")
    }
    
    // MARK: - Google Sign In
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // return GIDSignIn.sharedInstance.handle(url) // TODO: Enable once Gmail module is integrated
        return false
    }
    
}