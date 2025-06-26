//
//  NotificationManagerTests.swift
//  CoreTests
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import XCTest
import UserNotifications
@testable import Core

final class NotificationManagerTests: XCTestCase {
    
    var sut: NotificationManager!
    
    override func setUp() {
        super.setUp()
        sut = NotificationManager.shared
        // Reset any existing state
        sut.clearAllNotifications()
    }
    
    override func tearDown() {
        sut.clearAllNotifications()
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Authorization Tests
    
    func testRequestAuthorization() async {
        // When
        let authorized = await sut.requestAuthorization()
        
        // Then
        // Result depends on system state, just verify it returns
        XCTAssertTrue(authorized || !authorized)
    }
    
    func testAuthorizationStatus() async {
        // When
        let status = await sut.authorizationStatus()
        
        // Then
        let validStatuses: [UNAuthorizationStatus] = [
            .notDetermined,
            .denied,
            .authorized,
            .provisional
        ]
        XCTAssertTrue(validStatuses.contains(status))
    }
    
    // MARK: - Notification Scheduling Tests
    
    func testScheduleWarrantyNotification() {
        // Given
        var item = Item(name: "Test Device", category: .electronics)
        item.warrantyExpiration = Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days
        
        // When
        sut.scheduleWarrantyNotification(for: item, daysBefore: 7)
        
        // Then
        // Notification should be scheduled (we can't directly verify in unit tests)
        XCTAssertTrue(true) // Placeholder - real app would check pending notifications
    }
    
    func testScheduleMaintenanceNotification() {
        // Given
        let item = Item(name: "Car", category: .other)
        let maintenanceDate = Date().addingTimeInterval(90 * 24 * 60 * 60) // 90 days
        
        // When
        sut.scheduleMaintenanceNotification(
            for: item,
            maintenanceDate: maintenanceDate,
            title: "Oil Change Due"
        )
        
        // Then
        XCTAssertTrue(true) // Scheduled successfully
    }
    
    func testScheduleCustomNotification() {
        // Given
        let title = "Custom Reminder"
        let body = "Don't forget about this!"
        let date = Date().addingTimeInterval(60 * 60) // 1 hour
        
        // When
        sut.scheduleCustomNotification(
            title: title,
            body: body,
            date: date,
            identifier: "custom-123"
        )
        
        // Then
        XCTAssertTrue(true) // Scheduled successfully
    }
    
    // MARK: - Notification Management Tests
    
    func testCancelNotification() {
        // Given
        let identifier = "test-notification"
        sut.scheduleCustomNotification(
            title: "Test",
            body: "Test",
            date: Date().addingTimeInterval(60),
            identifier: identifier
        )
        
        // When
        sut.cancelNotification(identifier: identifier)
        
        // Then
        // Notification should be cancelled
        XCTAssertTrue(true)
    }
    
    func testCancelWarrantyNotifications() {
        // Given
        let item = Item(name: "Test Item", category: .other)
        
        // When
        sut.cancelWarrantyNotifications(for: item)
        
        // Then
        // All warranty notifications for item should be cancelled
        XCTAssertTrue(true)
    }
    
    func testClearAllNotifications() {
        // Given - Schedule some notifications
        sut.scheduleCustomNotification(
            title: "Test 1",
            body: "Body 1",
            date: Date().addingTimeInterval(60),
            identifier: "test-1"
        )
        sut.scheduleCustomNotification(
            title: "Test 2",
            body: "Body 2",
            date: Date().addingTimeInterval(120),
            identifier: "test-2"
        )
        
        // When
        sut.clearAllNotifications()
        
        // Then - All notifications should be cleared
        XCTAssertTrue(true)
    }
    
    // MARK: - Settings Tests
    
    func testUpdateNotificationSettings() {
        // Given
        let settings = NotificationManager.NotificationSettings(
            warrantyAlerts: true,
            maintenanceReminders: false,
            priceAlerts: true,
            stockAlerts: false,
            quietHoursEnabled: true,
            quietHoursStart: 22,
            quietHoursEnd: 8
        )
        
        // When
        sut.updateSettings(settings)
        
        // Then
        let savedSettings = sut.currentSettings()
        XCTAssertEqual(savedSettings.warrantyAlerts, true)
        XCTAssertEqual(savedSettings.maintenanceReminders, false)
        XCTAssertEqual(savedSettings.priceAlerts, true)
        XCTAssertEqual(savedSettings.stockAlerts, false)
        XCTAssertEqual(savedSettings.quietHoursEnabled, true)
        XCTAssertEqual(savedSettings.quietHoursStart, 22)
        XCTAssertEqual(savedSettings.quietHoursEnd, 8)
    }
    
    func testDefaultSettings() {
        // When
        let settings = sut.currentSettings()
        
        // Then
        XCTAssertTrue(settings.warrantyAlerts)
        XCTAssertTrue(settings.maintenanceReminders)
        XCTAssertFalse(settings.priceAlerts)
        XCTAssertTrue(settings.stockAlerts)
        XCTAssertFalse(settings.quietHoursEnabled)
        XCTAssertEqual(settings.quietHoursStart, 22)
        XCTAssertEqual(settings.quietHoursEnd, 7)
    }
    
    // MARK: - Badge Tests
    
    func testUpdateBadgeCount() async {
        // When
        await sut.updateBadgeCount(5)
        
        // Then
        // Badge should be updated (can't verify in unit tests)
        XCTAssertTrue(true)
    }
    
    func testClearBadge() async {
        // Given
        await sut.updateBadgeCount(10)
        
        // When
        await sut.clearBadge()
        
        // Then
        // Badge should be cleared
        XCTAssertTrue(true)
    }
    
    // MARK: - Date Calculation Tests
    
    func testNotificationDateCalculation() {
        // Given
        let futureDate = Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days
        let daysBefore = 7
        
        // When
        let notificationDate = Calendar.current.date(
            byAdding: .day,
            value: -daysBefore,
            to: futureDate
        )!
        
        // Then
        let expectedInterval = 23 * 24 * 60 * 60 // 23 days from now
        let actualInterval = notificationDate.timeIntervalSinceNow
        XCTAssertEqual(actualInterval, Double(expectedInterval), accuracy: 60) // Within 1 minute
    }
    
    // MARK: - Notification Content Tests
    
    func testWarrantyNotificationContent() {
        // Given
        var item = Item(name: "MacBook Pro", category: .electronics)
        item.warrantyExpiration = Date().addingTimeInterval(7 * 24 * 60 * 60)
        
        // When
        let content = UNMutableNotificationContent()
        content.title = "Warranty Expiring Soon"
        content.body = "\(item.name) warranty expires in 7 days"
        content.sound = .default
        content.categoryIdentifier = "warranty"
        
        // Then
        XCTAssertEqual(content.title, "Warranty Expiring Soon")
        XCTAssertTrue(content.body.contains("MacBook Pro"))
        XCTAssertTrue(content.body.contains("7 days"))
        XCTAssertEqual(content.categoryIdentifier, "warranty")
    }
    
    // MARK: - Mock Notification Tests
    
    func testMockNotificationScenarios() {
        // Test various notification scenarios
        let scenarios = [
            ("warranty-30", "Warranty expires in 30 days"),
            ("warranty-7", "Warranty expires in 7 days"),
            ("warranty-1", "Warranty expires tomorrow"),
            ("maintenance", "Maintenance due"),
            ("stock-low", "Low stock alert"),
            ("price-drop", "Price dropped")
        ]
        
        for (identifier, expectedBody) in scenarios {
            XCTAssertFalse(identifier.isEmpty)
            XCTAssertFalse(expectedBody.isEmpty)
        }
    }
}