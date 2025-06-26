//
//  SettingsComponentSnapshotTests.swift
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
final class SettingsComponentSnapshotTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Uncomment the line below to record new snapshots
        // isRecording = true
    }
    
    // MARK: - Component Tests
    
    func testSettingsBackgroundView() {
        let view = SettingsBackgroundView()
        
        assertSnapshot(
            matching: view.frame(width: 375, height: 200),
            as: .image,
            named: "Background_Standard"
        )
        
        assertSnapshot(
            matching: view.frame(width: 768, height: 300),
            as: .image,
            named: "Background_iPad"
        )
    }
    
    func testEnhancedSettingsComponents() {
        // Test individual setting rows
        let toggleRow = EnhancedSettingsComponents.SettingToggleRow(
            title: "Enable Notifications",
            systemImage: "bell.fill",
            isOn: .constant(true),
            tintColor: .blue
        )
        
        assertSnapshot(
            matching: toggleRow.frame(height: 60),
            as: .image(on: .iPhone13),
            named: "ToggleRow_On"
        )
        
        // Test with toggle off
        let toggleRowOff = EnhancedSettingsComponents.SettingToggleRow(
            title: "Enable Notifications",
            systemImage: "bell.fill",
            isOn: .constant(false),
            tintColor: .blue
        )
        
        assertSnapshot(
            matching: toggleRowOff.frame(height: 60),
            as: .image(on: .iPhone13),
            named: "ToggleRow_Off"
        )
        
        // Test navigation row
        let navRow = EnhancedSettingsComponents.SettingNavigationRow(
            title: "Privacy Policy",
            systemImage: "lock.shield.fill",
            tintColor: .green
        )
        
        assertSnapshot(
            matching: navRow.frame(height: 60),
            as: .image(on: .iPhone13),
            named: "NavigationRow"
        )
        
        // Test action row
        let actionRow = EnhancedSettingsComponents.SettingActionRow(
            title: "Export Data",
            systemImage: "square.and.arrow.up",
            tintColor: .orange,
            action: {}
        )
        
        assertSnapshot(
            matching: actionRow.frame(height: 60),
            as: .image(on: .iPhone13),
            named: "ActionRow"
        )
    }
    
    // MARK: - View State Tests
    
    func testClearCacheViewStates() {
        let viewModel = SettingsViewModel()
        
        // Normal state
        let normalView = ClearCacheView(viewModel: viewModel)
        assertSnapshot(
            matching: normalView,
            as: .image(on: .iPhone13ProMax),
            named: "ClearCache_Normal"
        )
        
        // Simulated loading state (would need to modify view to expose this)
        // This demonstrates how you would test different states
    }
    
    func testRateAppView() {
        let view = RateAppView()
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPhone13),
            named: "RateApp_Light"
        )
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPhone13, traits: .init(userInterfaceStyle: .dark)),
            named: "RateApp_Dark"
        )
    }
    
    func testShareAppView() {
        let view = ShareAppView()
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPhone13ProMax),
            named: "ShareApp"
        )
    }
    
    // MARK: - Complex View Tests
    
    func testBarcodeFormatSettingsView() {
        let viewModel = SettingsSnapshotTestData.createMockViewModel()
        let view = BarcodeFormatSettingsView(viewModel: viewModel)
        
        assertSettingsSnapshots(matching: view, named: "BarcodeFormats")
    }
    
    func testSpotlightSettingsView() {
        let viewModel = SettingsSnapshotTestData.createMockViewModel()
        let view = SpotlightSettingsView(viewModel: viewModel)
        
        assertSettingsSnapshots(matching: view, named: "Spotlight")
    }
    
    func testVoiceOverSettingsView() {
        let viewModel = SettingsSnapshotTestData.createMockViewModel(
            voiceOverEnabled: true,
            highContrastEnabled: true
        )
        let view = VoiceOverSettingsView(viewModel: viewModel)
        
        assertSettingsSnapshot(
            matching: view,
            device: .iPhone13ProMax,
            named: "VoiceOver_Enabled"
        )
        
        // Test with VoiceOver disabled
        viewModel.voiceOverEnabled = false
        assertSettingsSnapshot(
            matching: view,
            device: .iPhone13ProMax,
            named: "VoiceOver_Disabled"
        )
    }
    
    func testCrashReportingSettingsView() {
        let viewModel = SettingsViewModel()
        let view = CrashReportingSettingsView(viewModel: viewModel)
        
        assertSettingsSnapshots(matching: view, named: "CrashReporting")
    }
    
    func testLaunchPerformanceView() {
        let viewModel = SettingsViewModel()
        let view = LaunchPerformanceView(viewModel: viewModel)
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPhone13ProMax),
            named: "LaunchPerformance"
        )
    }
    
    // MARK: - Integration Tests
    
    func testFullSettingsFlowWithNavigation() {
        // This tests the full settings view with navigation context
        let viewModel = SettingsSnapshotTestData.createMockViewModel()
        let view = SettingsSnapshotWrapper {
            EnhancedSettingsView(viewModel: viewModel)
        }
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPhone13ProMax),
            named: "FullSettings_WithNav"
        )
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPadPro11),
            named: "FullSettings_iPad_WithNav"
        )
    }
    
    // MARK: - Edge Cases
    
    func testSettingsWithLongText() {
        // Test how settings handle long text
        let viewModel = SettingsViewModel()
        viewModel.userEmail = "verylongemailaddress@extremelylongdomainname.com"
        
        let view = EnhancedSettingsView(viewModel: viewModel)
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPhone13Mini),
            named: "Settings_LongText_Mini"
        )
    }
    
    func testSettingsInLandscape() {
        // Test landscape orientation on iPad
        let viewModel = SettingsViewModel()
        let view = EnhancedSettingsView(viewModel: viewModel)
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPadPro11(.landscape)),
            named: "Settings_iPad_Landscape"
        )
    }
}