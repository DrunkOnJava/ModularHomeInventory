//
//  MaintenanceReminderService.swift
//  Core
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
//  Dependencies: Foundation, SwiftUI, UserNotifications
//  Testing: CoreTests/MaintenanceReminderServiceTests.swift
//
//  Description: Service for managing maintenance reminders and service notifications
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation
import SwiftUI
import UserNotifications

@available(iOS 15.0, *)
public final class MaintenanceReminderService: ObservableObject {
    public static let shared = MaintenanceReminderService()
    
    // MARK: - Published Properties
    
    @Published public var reminders: [MaintenanceReminder] = []
    @Published public var upcomingReminders: [MaintenanceReminder] = []
    @Published public var overdueReminders: [MaintenanceReminder] = []
    @Published public var completedReminders: [MaintenanceReminder] = []
    @Published public var isLoading = false
    @Published public var error: MaintenanceError?
    
    // MARK: - Types
    
    public struct MaintenanceReminder: Identifiable, Codable, Equatable {
        public let id: UUID
        public var itemId: UUID
        public var itemName: String
        public var title: String
        public var description: String?
        public var type: MaintenanceType
        public var frequency: MaintenanceFrequency
        public var lastServiceDate: Date?
        public var nextServiceDate: Date
        public var cost: Decimal?
        public var provider: String?
        public var notes: String?
        public var isEnabled: Bool
        public var notificationSettings: NotificationSettings
        public var completionHistory: [CompletionRecord]
        public var attachmentIds: [UUID]
        public var createdAt: Date
        public var updatedAt: Date
        
        public var isOverdue: Bool {
            nextServiceDate < Date() && isEnabled
        }
        
        public var daysUntilDue: Int {
            Calendar.current.dateComponents([.day], from: Date(), to: nextServiceDate).day ?? 0
        }
        
        public var status: ReminderStatus {
            if !isEnabled {
                return .disabled
            } else if isOverdue {
                return .overdue
            } else if daysUntilDue <= 7 {
                return .upcoming
            } else {
                return .scheduled
            }
        }
        
        public init(
            id: UUID = UUID(),
            itemId: UUID,
            itemName: String,
            title: String,
            description: String? = nil,
            type: MaintenanceType,
            frequency: MaintenanceFrequency,
            lastServiceDate: Date? = nil,
            nextServiceDate: Date,
            cost: Decimal? = nil,
            provider: String? = nil,
            notes: String? = nil,
            isEnabled: Bool = true,
            notificationSettings: NotificationSettings = NotificationSettings(),
            completionHistory: [CompletionRecord] = [],
            attachmentIds: [UUID] = [],
            createdAt: Date = Date(),
            updatedAt: Date = Date()
        ) {
            self.id = id
            self.itemId = itemId
            self.itemName = itemName
            self.title = title
            self.description = description
            self.type = type
            self.frequency = frequency
            self.lastServiceDate = lastServiceDate
            self.nextServiceDate = nextServiceDate
            self.cost = cost
            self.provider = provider
            self.notes = notes
            self.isEnabled = isEnabled
            self.notificationSettings = notificationSettings
            self.completionHistory = completionHistory
            self.attachmentIds = attachmentIds
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }
    
    public enum MaintenanceType: String, Codable, CaseIterable {
        case cleaning = "Cleaning"
        case inspection = "Inspection"
        case service = "Service"
        case replacement = "Replacement"
        case calibration = "Calibration"
        case testing = "Testing"
        case lubrication = "Lubrication"
        case filter = "Filter Change"
        case battery = "Battery Replacement"
        case software = "Software Update"
        case backup = "Backup"
        case custom = "Custom"
        
        public var icon: String {
            switch self {
            case .cleaning: return "sparkles"
            case .inspection: return "magnifyingglass.circle"
            case .service: return "wrench.and.screwdriver"
            case .replacement: return "arrow.triangle.2.circlepath"
            case .calibration: return "dial.min"
            case .testing: return "checkmark.shield"
            case .lubrication: return "drop.fill"
            case .filter: return "slider.horizontal.3"
            case .battery: return "battery.25"
            case .software: return "arrow.down.circle"
            case .backup: return "externaldrive"
            case .custom: return "star"
            }
        }
        
        public var defaultDescription: String {
            switch self {
            case .cleaning: return "Regular cleaning and maintenance"
            case .inspection: return "Visual inspection and check"
            case .service: return "Professional service required"
            case .replacement: return "Part replacement needed"
            case .calibration: return "Calibration required"
            case .testing: return "Functional testing"
            case .lubrication: return "Lubrication needed"
            case .filter: return "Filter replacement"
            case .battery: return "Battery replacement"
            case .software: return "Software/firmware update"
            case .backup: return "Data backup required"
            case .custom: return "Custom maintenance task"
            }
        }
    }
    
    public enum MaintenanceFrequency: Codable, Equatable, Hashable, CaseIterable {
        case daily
        case weekly
        case biweekly
        case monthly
        case quarterly
        case semiannual
        case annual
        case biannual
        case custom(days: Int)
        
        public var displayName: String {
            switch self {
            case .daily: return "Daily"
            case .weekly: return "Weekly"
            case .biweekly: return "Every 2 Weeks"
            case .monthly: return "Monthly"
            case .quarterly: return "Quarterly"
            case .semiannual: return "Every 6 Months"
            case .annual: return "Annually"
            case .biannual: return "Every 2 Years"
            case .custom(let days): return "Every \(days) days"
            }
        }
        
        public var days: Int {
            switch self {
            case .daily: return 1
            case .weekly: return 7
            case .biweekly: return 14
            case .monthly: return 30
            case .quarterly: return 90
            case .semiannual: return 180
            case .annual: return 365
            case .biannual: return 730
            case .custom(let days): return days
            }
        }
        
        public static var allCases: [MaintenanceFrequency] {
            [.daily, .weekly, .biweekly, .monthly, .quarterly, .semiannual, .annual, .biannual]
        }
    }
    
    public struct NotificationSettings: Codable, Equatable {
        public var enabled: Bool = true
        public var daysBeforeReminder: [Int] = [7, 1] // Remind 7 days and 1 day before
        public var timeOfDay: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
        public var sound: Bool = true
        public var badge: Bool = true
        
        public init(
            enabled: Bool = true,
            daysBeforeReminder: [Int] = [7, 1],
            timeOfDay: Date? = nil,
            sound: Bool = true,
            badge: Bool = true
        ) {
            self.enabled = enabled
            self.daysBeforeReminder = daysBeforeReminder
            self.timeOfDay = timeOfDay ?? Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
            self.sound = sound
            self.badge = badge
        }
    }
    
    public struct CompletionRecord: Codable, Equatable, Identifiable {
        public let id: UUID
        public let completedDate: Date
        public let completedBy: String?
        public let cost: Decimal?
        public let provider: String?
        public let notes: String?
        public let attachmentIds: [UUID]
        
        public init(
            id: UUID = UUID(),
            completedDate: Date = Date(),
            completedBy: String? = nil,
            cost: Decimal? = nil,
            provider: String? = nil,
            notes: String? = nil,
            attachmentIds: [UUID] = []
        ) {
            self.id = id
            self.completedDate = completedDate
            self.completedBy = completedBy
            self.cost = cost
            self.provider = provider
            self.notes = notes
            self.attachmentIds = attachmentIds
        }
    }
    
    public enum ReminderStatus {
        case overdue
        case upcoming
        case scheduled
        case disabled
        
        public var color: Color {
            switch self {
            case .overdue: return .red
            case .upcoming: return .orange
            case .scheduled: return .green
            case .disabled: return .gray
            }
        }
        
        public var icon: String {
            switch self {
            case .overdue: return "exclamationmark.triangle.fill"
            case .upcoming: return "clock.badge.exclamationmark.fill"
            case .scheduled: return "clock.fill"
            case .disabled: return "clock.badge.xmark.fill"
            }
        }
    }
    
    public enum MaintenanceError: LocalizedError {
        case reminderNotFound
        case invalidFrequency
        case notificationPermissionDenied
        case saveFailed(String)
        case loadFailed(String)
        
        public var errorDescription: String? {
            switch self {
            case .reminderNotFound:
                return "Maintenance reminder not found"
            case .invalidFrequency:
                return "Invalid maintenance frequency"
            case .notificationPermissionDenied:
                return "Notification permission denied. Please enable notifications in Settings."
            case .saveFailed(let reason):
                return "Failed to save reminder: \(reason)"
            case .loadFailed(let reason):
                return "Failed to load reminders: \(reason)"
            }
        }
    }
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    private let notificationCenter = UNUserNotificationCenter.current()
    private let storageKey = "maintenance_reminders"
    private var notificationTimer: Timer?
    
    // MARK: - Initialization
    
    private init() {
        loadReminders()
        setupNotificationObservers()
        updateReminderCategories()
        scheduleAllNotifications()
    }
    
    // MARK: - Templates
    
    public struct MaintenanceTemplate {
        public let id: UUID
        public let title: String
        public let description: String
        public let type: MaintenanceType
        public let frequency: MaintenanceFrequency
        public let estimatedCost: Decimal?
        public let recommendedProvider: String?
        public let applicableCategories: [ItemCategory]
        
        public static let commonTemplates: [MaintenanceTemplate] = [
            MaintenanceTemplate(
                id: UUID(),
                title: "HVAC Filter Change",
                description: "Replace HVAC system air filter",
                type: .filter,
                frequency: .monthly,
                estimatedCost: 25,
                recommendedProvider: nil,
                applicableCategories: [.appliances]
            ),
            MaintenanceTemplate(
                id: UUID(),
                title: "Smoke Detector Battery",
                description: "Replace smoke detector batteries",
                type: .battery,
                frequency: .semiannual,
                estimatedCost: 10,
                recommendedProvider: nil,
                applicableCategories: [.electronics]
            ),
            MaintenanceTemplate(
                id: UUID(),
                title: "Vehicle Oil Change",
                description: "Change engine oil and filter",
                type: .service,
                frequency: .quarterly,
                estimatedCost: 50,
                recommendedProvider: "Local mechanic",
                applicableCategories: [.other] // Vehicles category not available
            ),
            MaintenanceTemplate(
                id: UUID(),
                title: "Computer Backup",
                description: "Backup important data",
                type: .backup,
                frequency: .weekly,
                estimatedCost: 0,
                recommendedProvider: nil,
                applicableCategories: [.electronics]
            ),
            MaintenanceTemplate(
                id: UUID(),
                title: "Appliance Deep Clean",
                description: "Deep clean appliance",
                type: .cleaning,
                frequency: .quarterly,
                estimatedCost: 0,
                recommendedProvider: nil,
                applicableCategories: [.appliances]
            )
        ]
    }
}

// MARK: - Public Methods

extension MaintenanceReminderService {
    /// Create a new maintenance reminder
    public func createReminder(_ reminder: MaintenanceReminder) async throws {
        var newReminder = reminder
        newReminder.updatedAt = Date()
        
        reminders.append(newReminder)
        updateReminderCategories()
        
        if newReminder.isEnabled && newReminder.notificationSettings.enabled {
            try await scheduleNotifications(for: newReminder)
        }
        
        saveReminders()
    }
    
    /// Update an existing reminder
    public func updateReminder(_ reminder: MaintenanceReminder) async throws {
        guard let index = reminders.firstIndex(where: { $0.id == reminder.id }) else {
            throw MaintenanceError.reminderNotFound
        }
        
        var updatedReminder = reminder
        updatedReminder.updatedAt = Date()
        
        reminders[index] = updatedReminder
        updateReminderCategories()
        
        // Reschedule notifications
        await cancelNotifications(for: reminder.id)
        if updatedReminder.isEnabled && updatedReminder.notificationSettings.enabled {
            try await scheduleNotifications(for: updatedReminder)
        }
        
        saveReminders()
    }
    
    /// Delete a reminder
    public func deleteReminder(_ reminderId: UUID) async throws {
        guard let index = reminders.firstIndex(where: { $0.id == reminderId }) else {
            throw MaintenanceError.reminderNotFound
        }
        
        await cancelNotifications(for: reminderId)
        reminders.remove(at: index)
        updateReminderCategories()
        saveReminders()
    }
    
    /// Mark a reminder as completed
    public func completeReminder(
        _ reminderId: UUID,
        cost: Decimal? = nil,
        provider: String? = nil,
        notes: String? = nil,
        attachmentIds: [UUID] = []
    ) async throws {
        guard let index = reminders.firstIndex(where: { $0.id == reminderId }) else {
            throw MaintenanceError.reminderNotFound
        }
        
        var reminder = reminders[index]
        
        // Create completion record
        let completion = CompletionRecord(
            completedDate: Date(),
            completedBy: nil, // Would get from user session
            cost: cost,
            provider: provider,
            notes: notes,
            attachmentIds: attachmentIds
        )
        
        reminder.completionHistory.append(completion)
        reminder.lastServiceDate = Date()
        
        // Calculate next service date
        reminder.nextServiceDate = calculateNextServiceDate(
            from: Date(),
            frequency: reminder.frequency
        )
        
        reminder.updatedAt = Date()
        
        reminders[index] = reminder
        updateReminderCategories()
        
        // Reschedule notifications
        await cancelNotifications(for: reminderId)
        if reminder.isEnabled && reminder.notificationSettings.enabled {
            try await scheduleNotifications(for: reminder)
        }
        
        saveReminders()
    }
    
    /// Get reminders for a specific item
    public func reminders(for itemId: UUID) -> [MaintenanceReminder] {
        reminders.filter { $0.itemId == itemId }
    }
    
    /// Get reminders by status
    public func reminders(with status: ReminderStatus) -> [MaintenanceReminder] {
        reminders.filter { $0.status == status }
    }
    
    /// Request notification permission
    public func requestNotificationPermission() async throws -> Bool {
        let settings = await notificationCenter.notificationSettings()
        
        switch settings.authorizationStatus {
        case .notDetermined:
            return try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
        case .authorized:
            return true
        case .denied, .ephemeral, .provisional:
            throw MaintenanceError.notificationPermissionDenied
        @unknown default:
            return false
        }
    }
    
    /// Toggle reminder enabled state
    public func toggleReminder(_ reminderId: UUID) async throws {
        guard let index = reminders.firstIndex(where: { $0.id == reminderId }) else {
            throw MaintenanceError.reminderNotFound
        }
        
        reminders[index].isEnabled.toggle()
        reminders[index].updatedAt = Date()
        
        if reminders[index].isEnabled && reminders[index].notificationSettings.enabled {
            try await scheduleNotifications(for: reminders[index])
        } else {
            await cancelNotifications(for: reminderId)
        }
        
        updateReminderCategories()
        saveReminders()
    }
    
    /// Create reminder from template
    public func createFromTemplate(
        itemId: UUID,
        itemName: String,
        template: MaintenanceTemplate
    ) async throws {
        let reminder = MaintenanceReminder(
            itemId: itemId,
            itemName: itemName,
            title: template.title,
            description: template.description,
            type: template.type,
            frequency: template.frequency,
            nextServiceDate: calculateNextServiceDate(from: Date(), frequency: template.frequency),
            cost: template.estimatedCost,
            provider: template.recommendedProvider
        )
        
        try await createReminder(reminder)
    }
}

// MARK: - Private Methods

extension MaintenanceReminderService {
    private func calculateNextServiceDate(from date: Date, frequency: MaintenanceFrequency) -> Date {
        Calendar.current.date(byAdding: .day, value: frequency.days, to: date) ?? date
    }
    
    private func updateReminderCategories() {
        let now = Date()
        
        upcomingReminders = reminders
            .filter { $0.isEnabled && !$0.isOverdue && $0.daysUntilDue <= 30 }
            .sorted { $0.nextServiceDate < $1.nextServiceDate }
        
        overdueReminders = reminders
            .filter { $0.isEnabled && $0.isOverdue }
            .sorted { $0.nextServiceDate < $1.nextServiceDate }
        
        completedReminders = reminders
            .filter { !$0.completionHistory.isEmpty }
            .sorted { ($0.completionHistory.last?.completedDate ?? Date.distantPast) > ($1.completionHistory.last?.completedDate ?? Date.distantPast) }
    }
}

// MARK: - Notification Methods

extension MaintenanceReminderService {
    private func scheduleNotifications(for reminder: MaintenanceReminder) async throws {
        guard reminder.notificationSettings.enabled else { return }
        
        let calendar = Calendar.current
        
        for daysBefore in reminder.notificationSettings.daysBeforeReminder {
            guard let notificationDate = calendar.date(
                byAdding: .day,
                value: -daysBefore,
                to: reminder.nextServiceDate
            ) else { continue }
            
            // Only schedule future notifications
            guard notificationDate > Date() else { continue }
            
            // Create notification content
            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.body = daysBefore == 0 
                ? "Maintenance due today for \(reminder.itemName)"
                : "Maintenance due in \(daysBefore) day\(daysBefore == 1 ? "" : "s") for \(reminder.itemName)"
            
            if reminder.notificationSettings.sound {
                content.sound = .default
            }
            
            if reminder.notificationSettings.badge {
                content.badge = 1
            }
            
            content.userInfo = [
                "reminderId": reminder.id.uuidString,
                "type": "maintenance_reminder"
            ]
            
            // Create trigger
            let dateComponents = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: notificationDate
            )
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: false
            )
            
            // Create request
            let requestId = "\(reminder.id.uuidString)_\(daysBefore)"
            let request = UNNotificationRequest(
                identifier: requestId,
                content: content,
                trigger: trigger
            )
            
            try await notificationCenter.add(request)
        }
    }
    
    private func cancelNotifications(for reminderId: UUID) async {
        let identifiers = (0...30).map { "\(reminderId.uuidString)_\($0)" }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    private func scheduleAllNotifications() {
        Task {
            for reminder in reminders where reminder.isEnabled && reminder.notificationSettings.enabled {
                try? await scheduleNotifications(for: reminder)
            }
        }
    }
    
    private func setupNotificationObservers() {
        // Check for overdue reminders daily
        notificationTimer = Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { _ in
            self.updateReminderCategories()
        }
    }
}

// MARK: - Persistence

extension MaintenanceReminderService {
    private func saveReminders() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(reminders)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            self.error = .saveFailed(error.localizedDescription)
        }
    }
    
    private func loadReminders() {
        guard let data = userDefaults.data(forKey: storageKey) else {
            reminders = []
            return
        }
        
        do {
            let decoder = JSONDecoder()
            reminders = try decoder.decode([MaintenanceReminder].self, from: data)
            updateReminderCategories()
        } catch {
            self.error = .loadFailed(error.localizedDescription)
            reminders = []
        }
    }
}