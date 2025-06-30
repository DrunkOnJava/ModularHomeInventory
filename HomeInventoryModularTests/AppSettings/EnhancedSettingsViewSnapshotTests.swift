//
//  EnhancedSettingsViewSnapshotTests.swift
//  HomeInventoryModularTests
//
//  Snapshot tests for EnhancedSettingsView component
//

import XCTest
import SnapshotTesting
import SwiftUI
@testable import AppSettings
@testable import Core
@testable import SharedUI

final class EnhancedSettingsViewSnapshotTests: XCTestCase {
    
    // MARK: - Mock Data
    
    private var mockUserSettings: UserSettings {
        UserSettings(
            id: UUID(),
            userId: "user123",
            appearance: AppearanceSettings(
                theme: .system,
                accentColor: .blue,
                useSystemFont: false,
                fontSize: .medium
            ),
            notifications: NotificationSettings(
                warrantyExpiration: true,
                warrantyExpirationDays: 30,
                maintenanceReminders: true,
                priceAlerts: false,
                dailySummary: true,
                summaryTime: DateComponents(hour: 9, minute: 0)
            ),
            privacy: PrivacySettings(
                biometricEnabled: true,
                autoLockTimeout: 300, // 5 minutes
                hideValues: false,
                privateModeEnabled: false
            ),
            scanner: ScannerSettings(
                autoScan: true,
                soundEnabled: true,
                hapticEnabled: true,
                autoSaveScans: false,
                barcodeFormats: [.ean13, .upca, .qr]
            ),
            sync: SyncSettings(
                autoSync: true,
                syncOverCellular: false,
                syncPhotos: true,
                syncInterval: 3600 // 1 hour
            ),
            backup: BackupSettings(
                autoBackup: true,
                backupFrequency: .weekly,
                includePhotos: true,
                backupLocation: .icloud
            )
        )
    }
    
    // MARK: - Tests
    
    func testEnhancedSettings_Default() {
        withSnapshotTesting(record: .all) {
            let view = NavigationView {
                EnhancedSettingsView(userSettings: mockUserSettings)
            }
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testEnhancedSettings_GeneralSection() {
        withSnapshotTesting(record: .all) {
            let view = NavigationView {
                EnhancedSettingsView(
                    userSettings: mockUserSettings,
                    initialSection: .general
                )
            }
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testEnhancedSettings_PrivacySection() {
        withSnapshotTesting(record: .all) {
            let view = NavigationView {
                EnhancedSettingsView(
                    userSettings: mockUserSettings,
                    initialSection: .privacy
                )
            }
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testEnhancedSettings_NotificationsSection() {
        withSnapshotTesting(record: .all) {
            let view = NavigationView {
                EnhancedSettingsView(
                    userSettings: mockUserSettings,
                    initialSection: .notifications
                )
            }
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testEnhancedSettings_ScannerSection() {
        withSnapshotTesting(record: .all) {
            let view = NavigationView {
                EnhancedSettingsView(
                    userSettings: mockUserSettings,
                    initialSection: .scanner
                )
            }
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testEnhancedSettings_DataSection() {
        withSnapshotTesting(record: .all) {
            let view = NavigationView {
                EnhancedSettingsView(
                    userSettings: mockUserSettings,
                    initialSection: .data
                )
            }
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testEnhancedSettings_AboutSection() {
        withSnapshotTesting(record: .all) {
            let view = NavigationView {
                EnhancedSettingsView(
                    userSettings: mockUserSettings,
                    initialSection: .about
                )
            }
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testEnhancedSettings_iPad() {
        withSnapshotTesting(record: .all) {
            let view = NavigationView {
                EnhancedSettingsView(userSettings: mockUserSettings)
            }
            .navigationViewStyle(DoubleColumnNavigationViewStyle())
            .frame(width: 1024, height: 1366)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPadPro12_9))
        }
    }
    
    func testEnhancedSettings_DarkMode() {
        withSnapshotTesting(record: .all) {
            let view = NavigationView {
                EnhancedSettingsView(userSettings: mockUserSettings)
            }
            .frame(width: 390, height: 844)
            .preferredColorScheme(.dark)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testEnhancedSettings_WithPremium() {
        withSnapshotTesting(record: .all) {
            let view = NavigationView {
                EnhancedSettingsView(
                    userSettings: mockUserSettings,
                    isPremium: true
                )
            }
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testEnhancedSettings_Accessibility() {
        withSnapshotTesting(record: .all) {
            let view = NavigationView {
                EnhancedSettingsView(userSettings: mockUserSettings)
            }
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(
                of: hostingController,
                as: .image(on: .iPhone13Pro, traits: .init(preferredContentSizeCategory: .accessibilityLarge))
            )
        }
    }
}