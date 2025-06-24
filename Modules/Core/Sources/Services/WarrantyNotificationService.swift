import Foundation
import UserNotifications
import Combine

/// Service for managing warranty expiration notifications
/// Swift 5.9 - No Swift 6 features
@MainActor
public final class WarrantyNotificationService: ObservableObject {
    
    // Singleton instance
    public static let shared = WarrantyNotificationService()
    
    // Dependencies
    private let notificationCenter = UNUserNotificationCenter.current()
    private var cancellables = Set<AnyCancellable>()
    
    // Settings
    @Published public var isEnabled = true
    @Published public var notificationDays = [30, 7, 1] // Days before expiration to notify
    
    private init() {
        requestNotificationPermission()
        loadSettings()
    }
    
    // MARK: - Public Methods
    
    /// Schedule notifications for a warranty
    public func scheduleNotifications(for warranty: Warranty) async {
        guard isEnabled else { return }
        
        // Remove existing notifications for this warranty
        await removeNotifications(for: warranty.id)
        
        // Don't schedule for expired warranties
        guard warranty.endDate > Date() else { return }
        
        // Schedule notifications for each notification day
        for days in notificationDays {
            if let notificationDate = Calendar.current.date(byAdding: .day, value: -days, to: warranty.endDate),
               notificationDate > Date() {
                await scheduleNotification(
                    for: warranty,
                    at: notificationDate,
                    daysRemaining: days
                )
            }
        }
    }
    
    /// Remove all notifications for a warranty
    public func removeNotifications(for warrantyId: UUID) async {
        let identifiers = notificationDays.map { "\(warrantyId.uuidString)_\($0)" }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    /// Update notifications for all warranties
    public func updateAllNotifications(_ warranties: [Warranty]) async {
        // Remove all existing warranty notifications
        let center = UNUserNotificationCenter.current()
        let requests = await center.pendingNotificationRequests()
        let warrantyIdentifiers = requests
            .map { $0.identifier }
            .filter { $0.contains("_") } // Warranty notifications have format "uuid_days"
        
        center.removePendingNotificationRequests(withIdentifiers: warrantyIdentifiers)
        
        // Schedule new notifications
        for warranty in warranties {
            await scheduleNotifications(for: warranty)
        }
    }
    
    /// Check and request notification permission
    public func checkNotificationPermission() async -> Bool {
        let settings = await notificationCenter.notificationSettings()
        
        switch settings.authorizationStatus {
        case .authorized, .provisional:
            return true
        case .notDetermined:
            return await requestNotificationPermission()
        case .denied:
            return false
        @unknown default:
            return false
        }
    }
    
    // MARK: - Private Methods
    
    private func scheduleNotification(for warranty: Warranty, at date: Date, daysRemaining: Int) async {
        let content = UNMutableNotificationContent()
        content.title = "Warranty Expiring Soon"
        content.body = "\(warranty.provider) warranty expires in \(daysRemaining) day\(daysRemaining == 1 ? "" : "s")"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "WARRANTY_EXPIRING"
        
        // Add warranty info to user info
        content.userInfo = [
            "warrantyId": warranty.id.uuidString,
            "itemId": warranty.itemId.uuidString,
            "daysRemaining": daysRemaining
        ]
        
        // Create date components for the notification
        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        
        // Create trigger
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )
        
        // Create request
        let identifier = "\(warranty.id.uuidString)_\(daysRemaining)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        do {
            try await notificationCenter.add(request)
            print("Scheduled warranty notification for \(warranty.provider) in \(daysRemaining) days")
        } catch {
            print("Error scheduling notification: \(error)")
        }
    }
    
    @discardableResult
    private func requestNotificationPermission() -> Bool {
        var granted = false
        let semaphore = DispatchSemaphore(value: 0)
        
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            granted = success
            if let error = error {
                print("Error requesting notification permission: \(error)")
            }
            semaphore.signal()
        }
        
        semaphore.wait()
        
        // Set up notification categories
        setupNotificationCategories()
        
        return granted
    }
    
    private func setupNotificationCategories() {
        let viewAction = UNNotificationAction(
            identifier: "VIEW_WARRANTY",
            title: "View Details",
            options: .foreground
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "Dismiss",
            options: .destructive
        )
        
        let category = UNNotificationCategory(
            identifier: "WARRANTY_EXPIRING",
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([category])
    }
    
    private func loadSettings() {
        isEnabled = UserDefaults.standard.bool(forKey: "warrantyNotificationsEnabled")
        if let savedDays = UserDefaults.standard.array(forKey: "warrantyNotificationDays") as? [Int] {
            notificationDays = savedDays
        }
        
        // Save settings when they change
        $isEnabled
            .dropFirst()
            .sink { enabled in
                UserDefaults.standard.set(enabled, forKey: "warrantyNotificationsEnabled")
            }
            .store(in: &cancellables)
        
        $notificationDays
            .dropFirst()
            .sink { days in
                UserDefaults.standard.set(days, forKey: "warrantyNotificationDays")
            }
            .store(in: &cancellables)
    }
}

// MARK: - Warranty Expiration Check Service

/// Service that periodically checks for expiring warranties
public final class WarrantyExpirationCheckService {
    
    // Singleton instance
    public static let shared = WarrantyExpirationCheckService()
    
    private var timer: Timer?
    private let notificationService = WarrantyNotificationService.shared
    
    private init() {}
    
    /// Start monitoring warranties for expiration
    public func startMonitoring(warrantyRepository: any WarrantyRepository) {
        // Check daily at 10 AM
        let calendar = Calendar.current
        let now = Date()
        
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: now)
        dateComponents.hour = 10
        dateComponents.minute = 0
        dateComponents.second = 0
        
        guard let scheduledDate = calendar.date(from: dateComponents) else { return }
        
        let fireDate = scheduledDate > now ? scheduledDate : calendar.date(byAdding: .day, value: 1, to: scheduledDate)!
        
        timer = Timer(fire: fireDate, interval: 24 * 60 * 60, repeats: true) { _ in
            Task {
                await self.checkExpiringWarranties(repository: warrantyRepository)
            }
        }
        
        RunLoop.main.add(timer!, forMode: .common)
        
        // Also check immediately
        Task {
            await checkExpiringWarranties(repository: warrantyRepository)
        }
    }
    
    /// Stop monitoring
    public func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkExpiringWarranties(repository: any WarrantyRepository) async {
        do {
            // Get all warranties
            let warranties = try await repository.fetchAll()
            
            // Update notifications for all warranties
            await notificationService.updateAllNotifications(warranties)
            
            // Log expiring warranties
            let expiringWarranties = warranties.filter { warranty in
                if case .expiringSoon = warranty.status {
                    return true
                }
                return false
            }
            
            if !expiringWarranties.isEmpty {
                print("Found \(expiringWarranties.count) expiring warranties")
            }
        } catch {
            print("Error checking expiring warranties: \(error)")
        }
    }
}