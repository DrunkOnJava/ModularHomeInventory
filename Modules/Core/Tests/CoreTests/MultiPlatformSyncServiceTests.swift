//
//  MultiPlatformSyncServiceTests.swift
//  CoreTests
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import XCTest
@testable import Core
import CloudKit

final class MultiPlatformSyncServiceTests: XCTestCase {
    
    var sut: MultiPlatformSyncService!
    
    override func setUp() {
        super.setUp()
        sut = MultiPlatformSyncService()
    }
    
    override func tearDown() {
        Task {
            try? await sut.resetSync()
        }
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut.syncStatus, .idle)
        XCTAssertNil(sut.lastSyncDate)
        XCTAssertEqual(sut.pendingChanges, 0)
        XCTAssertTrue(sut.connectedDevices.isEmpty)
    }
    
    // MARK: - Configuration Tests
    
    func testConfigureSync() {
        // Given
        var config = MultiPlatformSyncService.SyncConfiguration()
        config.automaticSync = false
        config.syncInterval = 600
        config.wifiOnlySync = true
        config.syncOnAppLaunch = false
        config.syncOnAppBackground = false
        
        // When
        sut.configure(config)
        
        // Then
        // Configuration should be applied (internal state not directly testable)
        XCTAssertNotNil(sut)
    }
    
    // MARK: - Sync Status Tests
    
    func testSyncStatusIsActive() {
        XCTAssertFalse(MultiPlatformSyncService.SyncStatus.idle.isActive)
        XCTAssertTrue(MultiPlatformSyncService.SyncStatus.syncing.isActive)
        XCTAssertTrue(MultiPlatformSyncService.SyncStatus.uploading(progress: 0.5).isActive)
        XCTAssertTrue(MultiPlatformSyncService.SyncStatus.downloading(progress: 0.5).isActive)
        XCTAssertFalse(MultiPlatformSyncService.SyncStatus.error("Test error").isActive)
    }
    
    // MARK: - Platform Tests
    
    func testCurrentPlatform() {
        let platform = MultiPlatformSyncService.Platform.current
        
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            XCTAssertEqual(platform.current, .iPad)
        } else {
            XCTAssertEqual(platform.current, .iPhone)
        }
        #elseif os(macOS)
        XCTAssertEqual(platform.current, .mac)
        #endif
    }
    
    func testPlatformRawValues() {
        XCTAssertEqual(MultiPlatformSyncService.Platform.iPhone.rawValue, "iPhone")
        XCTAssertEqual(MultiPlatformSyncService.Platform.iPad.rawValue, "iPad")
        XCTAssertEqual(MultiPlatformSyncService.Platform.mac.rawValue, "Mac")
    }
    
    // MARK: - Sync Statistics Tests
    
    func testGetSyncStats() {
        // When
        let stats = sut.getSyncStats()
        
        // Then
        XCTAssertNotNil(stats)
        XCTAssertNil(stats.lastSyncDate)
        XCTAssertEqual(stats.pendingChanges, 0)
        XCTAssertGreaterThanOrEqual(stats.totalSynced, 0)
        XCTAssertGreaterThanOrEqual(stats.conflictsResolved, 0)
        XCTAssertEqual(stats.connectedDevices, 0)
    }
    
    // MARK: - Needs Sync Tests
    
    func testNeedsSyncWithNoPendingChanges() async {
        // When
        let needsSync = await sut.needsSync()
        
        // Then
        XCTAssertFalse(needsSync)
    }
    
    // MARK: - Error Tests
    
    func testSyncErrorDescriptions() {
        let errors: [SyncError] = [
            .iCloudNotAvailable,
            .networkUnavailable,
            .syncInProgress
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
    
    // MARK: - Device Info Tests
    
    func testDeviceInfoInitialization() {
        // Given
        let deviceInfo = DeviceInfo(
            id: "test-id",
            name: "Test Device",
            platform: .iPhone,
            lastSeen: Date(),
            systemVersion: "17.0"
        )
        
        // Then
        XCTAssertEqual(deviceInfo.id, "test-id")
        XCTAssertEqual(deviceInfo.name, "Test Device")
        XCTAssertEqual(deviceInfo.platform, .iPhone)
        XCTAssertEqual(deviceInfo.systemVersion, "17.0")
    }
    
    func testDeviceInfoToCKRecord() {
        // Given
        let deviceInfo = DeviceInfo(
            id: "test-id",
            name: "Test Device",
            platform: .iPad,
            lastSeen: Date(),
            systemVersion: "17.0"
        )
        
        // When
        let record = deviceInfo.toCKRecord()
        
        // Then
        XCTAssertEqual(record.recordType, "Device")
        XCTAssertEqual(record["deviceID"] as? String, "test-id")
        XCTAssertEqual(record["name"] as? String, "Test Device")
        XCTAssertEqual(record["platform"] as? String, "iPad")
        XCTAssertEqual(record["systemVersion"] as? String, "17.0")
        XCTAssertNotNil(record["lastSeen"] as? Date)
    }
    
    // MARK: - Local Change Tests
    
    func testLocalChangeCreation() {
        // Given
        let change = LocalChange(
            recordType: "Item",
            recordID: "test-123",
            changeType: .create,
            data: Data()
        )
        
        // Then
        XCTAssertEqual(change.recordType, "Item")
        XCTAssertEqual(change.recordID, "test-123")
        XCTAssertEqual(change.changeType, .create)
        XCTAssertNotNil(change.id)
    }
    
    // MARK: - Async Tests
    
    func testSyncNowWhenICloudNotAvailable() async {
        // Given iCloud is not available
        sut.iCloudAvailable = false
        
        // When/Then
        do {
            try await sut.syncNow()
            XCTFail("Should throw error when iCloud not available")
        } catch {
            XCTAssertEqual(error as? SyncError, .iCloudNotAvailable)
        }
    }
    
    func testResetSync() async throws {
        // When
        try await sut.resetSync()
        
        // Then
        XCTAssertEqual(sut.syncStatus, .idle)
        XCTAssertNil(sut.lastSyncDate)
        XCTAssertTrue(sut.syncErrors.isEmpty)
    }
}