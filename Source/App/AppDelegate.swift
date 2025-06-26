//
//  AppDelegate.swift
//  HomeInventoryModular
//
//  Apple Configuration:
//  Bundle Identifier: com.homeinventory.app
//  Display Name: Home Inventory
//  Version: 1.0.5
//  Build: 5
//  Deployment Target: iOS 17.0
//  Supported Devices: iPhone & iPad
//  Team ID: 2VXBQV4XC9
//
//  Makefile Configuration:
//  Default Simulator: iPhone 16 Pro Max (DD192264-DFAA-4582-B2FE-D6FC444C9DDF)
//  iPad Simulator: iPad Pro 13-inch (M4) (CE6D038C-840B-4BDB-AA63-D61FA0755C4A)
//  App Bundle ID: com.homeinventory.app
//  Build Path: build/Build/Products/Debug-iphonesimulator/
//
//  Google Sign-In Configuration:
//  Client ID: 316432172622-6huvbn752v0ep68jkfdftrh8fgpesikg.apps.googleusercontent.com
//  URL Scheme: com.googleusercontent.apps.316432172622-6huvbn752v0ep68jkfdftrh8fgpesikg
//  OAuth Scope: https://www.googleapis.com/auth/gmail.readonly
//  Config Files: GoogleSignIn-Info.plist (project root), GoogleServices.plist (Gmail module)
//
//  Key Commands:
//  Build and run: make build run
//  Fast build (skip module prebuild): make build-fast run
//  iPad build and run: make build-ipad run-ipad
//  Clean build: make clean build run
//  Run tests: make test
//
//  Project Structure:
//  Main Target: HomeInventoryModular
//  Test Targets: HomeInventoryModularTests, HomeInventoryModularUITests
//  Swift Version: 5.9 (DO NOT upgrade to Swift 6)
//  Minimum iOS Version: 17.0
//
//  Architecture: Modular SPM packages with local package dependencies
//  Repository: https://github.com/DrunkOnJava/ModularHomeInventory.git
//  Module: Main App Target
//  Dependencies: UIKit, Core, GoogleSignIn
//  Testing: HomeInventoryModularTests/AppDelegateTests.swift
//
//  Description: App delegate handling remote notifications, app lifecycle events, and Google Sign-In configuration
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import UIKit
import Core
import GoogleSignIn

/// App delegate for handling remote notifications and app lifecycle events
/// Swift 5.9 - No Swift 6 features
class AppDelegate: NSObject, UIApplicationDelegate {
    
    private let launchOptimizer = AppLaunchOptimizer.shared
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Start launch optimization tracking
        launchOptimizer.startPhase(.appDelegate)
        
        // Configure launch optimization (temporarily disabled due to import issue)
        // launchOptimizer.configure(LaunchConfiguration(
        //     deferNonCriticalWork: true,
        //     preloadCriticalData: true,
        //     optimizeImageLoading: true,
        //     useLaunchScreenCache: true,
        //     enableMetricsCollection: true
        // ))
        
        // Defer non-critical initialization
        launchOptimizer.deferWork { [weak self] in
            self?.setupCrashReporting()
            self?.checkForPreviousCrash()
        }
        
        // Configure Google Sign-In
        if let path = Bundle.main.path(forResource: "GoogleSignIn-Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let clientId = plist["GIDClientID"] as? String {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
            print("[AppDelegate] Google Sign-In configured with client ID: \(clientId)")
        } else {
            print("[AppDelegate] Warning: GoogleSignIn-Info.plist not found or invalid")
        }
        
        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
        
        // Defer notification check
        launchOptimizer.deferWork {
            Task {
                await NotificationManager.shared.checkAuthorizationStatus()
            }
        }
        
        // Register critical data preloading
        launchOptimizer.registerPreloadTask("user-settings") {
            // Preload user settings
            _ = UserDefaultsSettingsStorage()
        }
        
        launchOptimizer.registerPreloadTask("categories") {
            // Preload category data
            _ = ItemCategory.allCases
        }
        
        // Optimize launch images
        launchOptimizer.optimizeLaunchImages()
        
        // End app delegate phase
        launchOptimizer.endPhase(.appDelegate)
        
        return true
    }
    
    // MARK: - Crash Reporting
    
    private func setupCrashReporting() {
        // Check if crash reporting is enabled in settings
        let settingsStorage = UserDefaultsSettingsStorage()
        let isEnabled = settingsStorage.bool(forKey: .crashReportingEnabled) ?? true
        
        // Enable crash reporting
        CrashReportingService.shared.setEnabled(isEnabled)
        
        // Defer automatic crash report sending
        if isEnabled && (settingsStorage.bool(forKey: .crashReportingAutoSend) ?? true) {
            launchOptimizer.deferWork {
                Task {
                    // Wait longer since this is deferred
                    try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
                    
                    // Send pending reports
                    try? await CrashReportingService.shared.sendPendingReports()
                }
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
        return GIDSignIn.sharedInstance.handle(url)
    }
    
}