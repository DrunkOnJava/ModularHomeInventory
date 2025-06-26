//
//  NotificationManager.swift
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
//  Module: Core
//  Dependencies: Foundation, UserNotifications, UIKit, Combine
//  Testing: Modules/Core/Tests/CoreTests/NotificationManagerTests.swift
//
//  Description: Central notification manager for all push notifications providing permission
//  management, notification scheduling, delivery tracking, and user interaction handling.
//  Supports rich notifications, categories, and background delivery.
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation
import UserNotifications
import UIKit
import Combine

/// Central notification manager for all push notifications
/// Swift 5.9 - No Swift 6 features
@MainActor
public final class NotificationManager: NSObject, ObservableObject {
    
    // Singleton instance
    public static let shared = NotificationManager()
    
    // Dependencies
    private let notificationCenter = UNUserNotificationCenter.current()
    private var cancellables = Set<AnyCancellable>()
    
    // Published properties
    @Published public var isAuthorized = false
    @Published public var pendingNotifications: [NotificationRequest] = []
    @Published public var notificationSettings = NotificationSettings()
    
    // Notification types
    public enum NotificationType: String, CaseIterable {
        case warrantyExpiration = "warranty_expiration"
        case priceAlert = "price_alert"
        case lowStock = "low_stock"
        case budgetAlert = "budget_alert"
        case receiptProcessed = "receipt_processed"
        case syncComplete = "sync_complete"
        case itemRecall = "item_recall"
        case maintenanceReminder = "maintenance_reminder"
        case customAlert = "custom_alert"
        
        public var displayName: String {
            switch self {
            case .warrantyExpiration: return "Warranty Expirations"
            case .priceAlert: return "Price Drop Alerts"
            case .lowStock: return "Low Stock Alerts"
            case .budgetAlert: return "Budget Alerts"
            case .receiptProcessed: return "Receipt Processing"
            case .syncComplete: return "Sync Notifications"
            case .itemRecall: return "Item Recalls"
            case .maintenanceReminder: return "Maintenance Reminders"
            case .customAlert: return "Custom Alerts"
            }
        }
        
        public var icon: String {
            switch self {
            case .warrantyExpiration: return "shield"
            case .priceAlert: return "tag"
            case .lowStock: return "exclamationmark.triangle"
            case .budgetAlert: return "dollarsign.circle"
            case .receiptProcessed: return "doc.text"
            case .syncComplete: return "arrow.triangle.2.circlepath"
            case .itemRecall: return "exclamationmark.octagon"
            case .maintenanceReminder: return "wrench.and.screwdriver"
            case .customAlert: return "bell"
            }
        }
        
        var defaultEnabled: Bool {
            switch self {
            case .warrantyExpiration, .itemRecall, .budgetAlert:
                return true
            default:
                return false
            }
        }
    }
    
    private override init() {
        super.init()
        notificationCenter.delegate = self
        loadSettings()
        checkAuthorizationStatus()
        setupNotificationCategories()
    }
    
    // MARK: - Public Methods
    
    /// Request notification permission
    public func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .badge, .sound, .providesAppNotificationSettings]
            )
            
            await MainActor.run {
                self.isAuthorized = granted
            }
            
            if granted {
                await UIApplication.shared.registerForRemoteNotifications()
            }
            
            return granted
        } catch {
            print("Error requesting notification authorization: \(error)")
            return false
        }
    }
    
    /// Check current authorization status
    public func checkAuthorizationStatus() {
        Task {
            let settings = await notificationCenter.notificationSettings()
            
            await MainActor.run {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    /// Schedule a notification
    public func scheduleNotification(_ request: NotificationRequest) async throws {
        guard isAuthorized else {
            throw NotificationError.notAuthorized
        }
        
        guard notificationSettings.isEnabled(for: request.type) else {
            print("Notifications disabled for type: \(request.type.displayName)")
            return
        }
        
        let content = createContent(for: request)
        let trigger = createTrigger(for: request)
        
        let notificationRequest = UNNotificationRequest(
            identifier: request.id,
            content: content,
            trigger: trigger
        )
        
        try await notificationCenter.add(notificationRequest)
        
        await MainActor.run {
            self.pendingNotifications.append(request)
        }
    }
    
    /// Cancel a notification
    public func cancelNotification(id: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
        pendingNotifications.removeAll { $0.id == id }
    }
    
    /// Cancel all notifications of a specific type
    public func cancelNotifications(ofType type: NotificationType) {
        let identifiers = pendingNotifications
            .filter { $0.type == type }
            .map { $0.id }
        
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        pendingNotifications.removeAll { $0.type == type }
    }
    
    /// Get pending notifications
    public func loadPendingNotifications() async {
        let requests = await notificationCenter.pendingNotificationRequests()
        
        let notifications = requests.compactMap { request -> NotificationRequest? in
            // Parse notification request back to our model
            guard let typeString = request.content.userInfo["type"] as? String,
                  let type = NotificationType(rawValue: typeString) else {
                return nil
            }
            
            return NotificationRequest(
                id: request.identifier,
                type: type,
                title: request.content.title,
                body: request.content.body,
                scheduledDate: (request.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate(),
                userInfo: request.content.userInfo
            )
        }
        
        await MainActor.run {
            self.pendingNotifications = notifications
        }
    }
    
    /// Handle device token registration
    public func registerDeviceToken(_ token: Data) {
        let tokenParts = token.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
        
        // In a real app, send this to your backend server
        // await sendTokenToServer(token)
    }
    
    /// Handle registration failure
    public func registrationFailed(_ error: Error) {
        print("Remote notification registration failed: \(error)")
    }
    
    // MARK: - Private Methods
    
    private func createContent(for request: NotificationRequest) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = request.title
        content.body = request.body
        content.sound = request.sound ?? .default
        content.badge = request.badge
        content.categoryIdentifier = request.type.rawValue
        
        var userInfo = request.userInfo
        userInfo["type"] = request.type.rawValue
        content.userInfo = userInfo
        
        // Add attachments if available
        if let imageURL = request.imageURL {
            if let attachment = try? UNNotificationAttachment(
                identifier: "image",
                url: imageURL,
                options: nil
            ) {
                content.attachments = [attachment]
            }
        }
        
        return content
    }
    
    private func createTrigger(for request: NotificationRequest) -> UNNotificationTrigger? {
        if let date = request.scheduledDate {
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: date
            )
            return UNCalendarNotificationTrigger(
                dateMatching: components,
                repeats: request.repeats
            )
        } else if request.timeInterval > 0 {
            return UNTimeIntervalNotificationTrigger(
                timeInterval: request.timeInterval,
                repeats: request.repeats
            )
        }
        
        return nil
    }
    
    private func setupNotificationCategories() {
        var categories: [UNNotificationCategory] = []
        
        // Warranty expiration category
        let warrantyActions = [
            UNNotificationAction(
                identifier: "VIEW_WARRANTY",
                title: "View Details",
                options: .foreground
            ),
            UNNotificationAction(
                identifier: "RENEW_WARRANTY",
                title: "Renew",
                options: .foreground
            )
        ]
        
        categories.append(UNNotificationCategory(
            identifier: NotificationType.warrantyExpiration.rawValue,
            actions: warrantyActions,
            intentIdentifiers: [],
            options: []
        ))
        
        // Price alert category
        let priceActions = [
            UNNotificationAction(
                identifier: "VIEW_ITEM",
                title: "View Item",
                options: .foreground
            ),
            UNNotificationAction(
                identifier: "BUY_NOW",
                title: "Buy Now",
                options: .foreground
            )
        ]
        
        categories.append(UNNotificationCategory(
            identifier: NotificationType.priceAlert.rawValue,
            actions: priceActions,
            intentIdentifiers: [],
            options: []
        ))
        
        // Budget alert category
        let budgetActions = [
            UNNotificationAction(
                identifier: "VIEW_BUDGET",
                title: "View Budget",
                options: .foreground
            ),
            UNNotificationAction(
                identifier: "ADJUST_BUDGET",
                title: "Adjust",
                options: .foreground
            )
        ]
        
        categories.append(UNNotificationCategory(
            identifier: NotificationType.budgetAlert.rawValue,
            actions: budgetActions,
            intentIdentifiers: [],
            options: []
        ))
        
        notificationCenter.setNotificationCategories(Set(categories))
    }
    
    private func loadSettings() {
        notificationSettings = NotificationSettings.load()
        
        // Save settings when they change
        notificationSettings.$enabledTypes
            .dropFirst()
            .sink { _ in
                self.notificationSettings.save()
            }
            .store(in: &cancellables)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        // Handle notification tap
        NotificationCenter.default.post(
            name: .notificationTapped,
            object: nil,
            userInfo: userInfo
        )
        
        // Handle specific actions
        switch response.actionIdentifier {
        case "VIEW_WARRANTY", "VIEW_ITEM", "VIEW_BUDGET":
            NotificationCenter.default.post(
                name: .notificationActionTapped,
                object: nil,
                userInfo: ["action": response.actionIdentifier, "userInfo": userInfo]
            )
        default:
            break
        }
        
        completionHandler()
    }
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        openSettingsFor notification: UNNotification?
    ) {
        // Open app's notification settings
        NotificationCenter.default.post(
            name: .openNotificationSettings,
            object: nil
        )
    }
}

// MARK: - Models

/// Notification request model
public struct NotificationRequest {
    public let id: String
    public let type: NotificationManager.NotificationType
    public let title: String
    public let body: String
    public var scheduledDate: Date?
    public var timeInterval: TimeInterval = 0
    public var repeats: Bool = false
    public var sound: UNNotificationSound?
    public var badge: NSNumber?
    public var imageURL: URL?
    public var userInfo: [AnyHashable: Any] = [:]
    
    public init(
        id: String = UUID().uuidString,
        type: NotificationManager.NotificationType,
        title: String,
        body: String,
        scheduledDate: Date? = nil,
        timeInterval: TimeInterval = 0,
        repeats: Bool = false,
        sound: UNNotificationSound? = nil,
        badge: NSNumber? = nil,
        imageURL: URL? = nil,
        userInfo: [AnyHashable: Any] = [:]
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.body = body
        self.scheduledDate = scheduledDate
        self.timeInterval = timeInterval
        self.repeats = repeats
        self.sound = sound
        self.badge = badge
        self.imageURL = imageURL
        self.userInfo = userInfo
    }
}

/// Notification settings model
@MainActor
public final class NotificationSettings: ObservableObject {
    @Published public var enabledTypes: Set<NotificationManager.NotificationType>
    @Published public var soundEnabled = true
    @Published public var badgeEnabled = true
    @Published public var quietHoursEnabled = false
    @Published public var quietHoursStart = DateComponents(hour: 22, minute: 0)
    @Published public var quietHoursEnd = DateComponents(hour: 7, minute: 0)
    
    private static let enabledTypesKey = "notification_enabled_types"
    private static let soundEnabledKey = "notification_sound_enabled"
    private static let badgeEnabledKey = "notification_badge_enabled"
    private static let quietHoursEnabledKey = "notification_quiet_hours_enabled"
    
    init() {
        // Load default enabled types
        self.enabledTypes = Set(NotificationManager.NotificationType.allCases.filter { $0.defaultEnabled })
    }
    
    public func isEnabled(for type: NotificationManager.NotificationType) -> Bool {
        enabledTypes.contains(type)
    }
    
    public func toggle(_ type: NotificationManager.NotificationType) {
        if enabledTypes.contains(type) {
            enabledTypes.remove(type)
        } else {
            enabledTypes.insert(type)
        }
    }
    
    static func load() -> NotificationSettings {
        let settings = NotificationSettings()
        
        if let savedTypes = UserDefaults.standard.array(forKey: enabledTypesKey) as? [String] {
            settings.enabledTypes = Set(savedTypes.compactMap { NotificationManager.NotificationType(rawValue: $0) })
        }
        
        settings.soundEnabled = UserDefaults.standard.bool(forKey: soundEnabledKey)
        settings.badgeEnabled = UserDefaults.standard.bool(forKey: badgeEnabledKey)
        settings.quietHoursEnabled = UserDefaults.standard.bool(forKey: quietHoursEnabledKey)
        
        return settings
    }
    
    func save() {
        UserDefaults.standard.set(enabledTypes.map { $0.rawValue }, forKey: Self.enabledTypesKey)
        UserDefaults.standard.set(soundEnabled, forKey: Self.soundEnabledKey)
        UserDefaults.standard.set(badgeEnabled, forKey: Self.badgeEnabledKey)
        UserDefaults.standard.set(quietHoursEnabled, forKey: Self.quietHoursEnabledKey)
    }
}

/// Notification errors
public enum NotificationError: LocalizedError {
    case notAuthorized
    case schedulingFailed
    
    public var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Notifications are not authorized"
        case .schedulingFailed:
            return "Failed to schedule notification"
        }
    }
}

// MARK: - Notification Names

public extension Notification.Name {
    static let notificationTapped = Notification.Name("notificationTapped")
    static let notificationActionTapped = Notification.Name("notificationActionTapped")
    static let openNotificationSettings = Notification.Name("openNotificationSettings")
}