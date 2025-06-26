//
//  SettingsSnapshotTests.swift
//  AppSettingsTests
//
//  Created for HomeInventoryModular
//

import XCTest
import SnapshotTesting
import SwiftUI
@testable import AppSettings
@testable import Core
@testable import SharedUI

// ⚠️ IMPORTANT: This project MUST use Swift 5.9 - DO NOT use Swift 6 features
final class SettingsSnapshotTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Uncomment the line below to record new snapshots
        // isRecording = true
    }
    
    // MARK: - Main Settings View Tests
    
    func testEnhancedSettingsView() {
        let viewModel = SettingsViewModel()
        let view = EnhancedSettingsView(viewModel: viewModel)
        
        // Test on different devices
        assertSnapshot(
            matching: view,
            as: .image(on: .iPhone13ProMax),
            named: "iPhone_ProMax"
        )
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPadPro11),
            named: "iPad_Pro"
        )
        
        // Test dark mode
        assertSnapshot(
            matching: view,
            as: .image(on: .iPhone13ProMax, traits: .init(userInterfaceStyle: .dark)),
            named: "iPhone_ProMax_Dark"
        )
    }
    
    // MARK: - Individual Settings Sections Tests
    
    func testAboutView() {
        let view = AboutView()
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPhone13),
            named: "iPhone_Standard"
        )
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPhone13, traits: .init(userInterfaceStyle: .dark)),
            named: "iPhone_Dark"
        )
    }
    
    func testPrivacyPolicyView() {
        let view = PrivacyPolicyView()
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPhone13ProMax),
            named: "iPhone_ProMax"
        )
        
        // Test with accessibility large text
        assertSnapshot(
            matching: view,
            as: .image(on: .iPhone13ProMax, traits: .init(preferredContentSizeCategory: .accessibilityLarge)),
            named: "iPhone_ProMax_AccessibilityLarge"
        )
    }
    
    func testTermsOfServiceView() {
        let view = TermsOfServiceView()
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPhone13ProMax),
            named: "iPhone_ProMax"
        )
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPadPro11),
            named: "iPad_Pro"
        )
    }
    
    func testNotificationSettingsView() {
        let viewModel = SettingsViewModel()
        let view = NotificationSettingsView(viewModel: viewModel)
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPhone13),
            named: "iPhone_Standard"
        )
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPhone13, traits: .init(userInterfaceStyle: .dark)),
            named: "iPhone_Dark"
        )
    }
    
    func testSyncSettingsView() {
        let viewModel = SettingsViewModel()
        let view = SyncSettingsView(viewModel: viewModel)
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPhone13ProMax),
            named: "iPhone_ProMax"
        )
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPadPro11),
            named: "iPad_Pro"
        )
    }
    
    func testAccessibilitySettingsView() {
        let viewModel = SettingsViewModel()
        let view = AccessibilitySettingsView(viewModel: viewModel)
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPhone13),
            named: "iPhone_Standard"
        )
        
        // Test with high contrast
        assertSnapshot(
            matching: view,
            as: .image(on: .iPhone13, traits: .init(accessibilityContrast: .high)),
            named: "iPhone_HighContrast"
        )
    }
    
    func testBiometricSettingsView() {
        let viewModel = SettingsViewModel()
        let view = BiometricSettingsView(viewModel: viewModel)
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPhone13ProMax),
            named: "iPhone_ProMax"
        )
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPhone13ProMax, traits: .init(userInterfaceStyle: .dark)),
            named: "iPhone_ProMax_Dark"
        )
    }
    
    func testScannerSettingsView() {
        let viewModel = SettingsViewModel()
        let view = ScannerSettingsView(viewModel: viewModel)
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPhone13),
            named: "iPhone_Standard"
        )
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPadPro11),
            named: "iPad_Pro"
        )
    }
    
    func testCategoryManagementView() {
        let viewModel = SettingsViewModel()
        let view = CategoryManagementView(viewModel: viewModel)
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPhone13ProMax),
            named: "iPhone_ProMax"
        )
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPadPro11),
            named: "iPad_Pro"
        )
    }
    
    func testExportDataView() {
        let viewModel = SettingsViewModel()
        let view = ExportDataView(viewModel: viewModel)
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPhone13),
            named: "iPhone_Standard"
        )
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPhone13, traits: .init(userInterfaceStyle: .dark)),
            named: "iPhone_Dark"
        )
    }
    
    // MARK: - Edge Cases and States
    
    func testSettingsViewWithDifferentStates() {
        let viewModel = SettingsViewModel()
        
        // Test with notifications enabled
        viewModel.notificationsEnabled = true
        viewModel.soundEnabled = true
        viewModel.biometricEnabled = true
        
        let view = EnhancedSettingsView(viewModel: viewModel)
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPhone13ProMax),
            named: "iPhone_ProMax_AllEnabled"
        )
        
        // Test with everything disabled
        viewModel.notificationsEnabled = false
        viewModel.soundEnabled = false
        viewModel.biometricEnabled = false
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPhone13ProMax),
            named: "iPhone_ProMax_AllDisabled"
        )
    }
    
    // MARK: - Accessibility Tests
    
    func testSettingsViewAccessibility() {
        let viewModel = SettingsViewModel()
        let view = EnhancedSettingsView(viewModel: viewModel)
        
        // Test with different text sizes
        let textSizes: [(UIContentSizeCategory, String)] = [
            (.extraSmall, "ExtraSmall"),
            (.large, "Large"),
            (.accessibilityMedium, "AccessibilityMedium"),
            (.accessibilityExtraExtraExtraLarge, "AccessibilityXXXL")
        ]
        
        for (size, name) in textSizes {
            assertSnapshot(
                matching: view,
                as: .image(on: .iPhone13ProMax, traits: .init(preferredContentSizeCategory: size)),
                named: "iPhone_ProMax_TextSize_\(name)"
            )
        }
    }
    
    // MARK: - RTL Layout Tests
    
    func testSettingsViewRTL() {
        let viewModel = SettingsViewModel()
        let view = EnhancedSettingsView(viewModel: viewModel)
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPhone13ProMax, traits: .init(layoutDirection: .rightToLeft)),
            named: "iPhone_ProMax_RTL"
        )
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPadPro11, traits: .init(layoutDirection: .rightToLeft)),
            named: "iPad_Pro_RTL"
        )
    }
}