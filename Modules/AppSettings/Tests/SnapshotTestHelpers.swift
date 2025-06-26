//
//  SnapshotTestHelpers.swift
//  AppSettingsTests
//
//  Created for HomeInventoryModular
//

import XCTest
import SnapshotTesting
import SwiftUI

// ⚠️ IMPORTANT: This project MUST use Swift 5.9 - DO NOT use Swift 6 features

/// Helper extension for AppSettings snapshot tests
extension XCTestCase {
    
    /// Assert snapshots for common device configurations used in settings
    func assertSettingsSnapshots<V: SwiftUI.View>(
        matching view: V,
        named name: String? = nil,
        record: Bool = false,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        let configurations: [(config: ViewImageConfig, name: String, traits: UITraitCollection?)] = [
            // Light mode
            (.iPhone13, "iPhone_Standard", nil),
            (.iPhone13ProMax, "iPhone_ProMax", nil),
            (.iPadPro11, "iPad_Pro", nil),
            
            // Dark mode
            (.iPhone13, "iPhone_Standard_Dark", UITraitCollection(userInterfaceStyle: .dark)),
            (.iPhone13ProMax, "iPhone_ProMax_Dark", UITraitCollection(userInterfaceStyle: .dark)),
            
            // Accessibility
            (.iPhone13ProMax, "iPhone_ProMax_LargeText", 
             UITraitCollection(preferredContentSizeCategory: .accessibilityLarge))
        ]
        
        for (config, deviceName, traits) in configurations {
            let finalName = name.map { "\($0)_\(deviceName)" } ?? deviceName
            
            if let traits = traits {
                assertSnapshot(
                    matching: view,
                    as: .image(on: config, traits: traits),
                    named: finalName,
                    record: record,
                    file: file,
                    testName: testName,
                    line: line
                )
            } else {
                assertSnapshot(
                    matching: view,
                    as: .image(on: config),
                    named: finalName,
                    record: record,
                    file: file,
                    testName: testName,
                    line: line
                )
            }
        }
    }
    
    /// Assert snapshot for a single configuration
    func assertSettingsSnapshot<V: SwiftUI.View>(
        matching view: V,
        device: ViewImageConfig = .iPhone13ProMax,
        traits: UITraitCollection? = nil,
        named name: String? = nil,
        record: Bool = false,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        if let traits = traits {
            assertSnapshot(
                matching: view,
                as: .image(on: device, traits: traits),
                named: name,
                record: record,
                file: file,
                testName: testName,
                line: line
            )
        } else {
            assertSnapshot(
                matching: view,
                as: .image(on: device),
                named: name,
                record: record,
                file: file,
                testName: testName,
                line: line
            )
        }
    }
}

/// Mock data for settings snapshot tests
struct SettingsSnapshotTestData {
    
    /// Create a mock SettingsViewModel with test data
    static func createMockViewModel(
        notificationsEnabled: Bool = true,
        soundEnabled: Bool = true,
        biometricEnabled: Bool = false,
        autoSyncEnabled: Bool = true,
        voiceOverEnabled: Bool = false,
        highContrastEnabled: Bool = false
    ) -> SettingsViewModel {
        let viewModel = SettingsViewModel()
        viewModel.notificationsEnabled = notificationsEnabled
        viewModel.soundEnabled = soundEnabled
        viewModel.biometricEnabled = biometricEnabled
        viewModel.autoSyncEnabled = autoSyncEnabled
        viewModel.voiceOverEnabled = voiceOverEnabled
        viewModel.highContrastEnabled = highContrastEnabled
        return viewModel
    }
    
    /// Common categories for testing
    static let mockCategories = [
        "Electronics",
        "Furniture", 
        "Kitchen",
        "Clothing",
        "Books",
        "Tools",
        "Sports Equipment",
        "Toys & Games",
        "Office Supplies",
        "Home Decor"
    ]
}

/// Helper to wrap views in common containers for consistent snapshots
struct SettingsSnapshotWrapper<Content: View>: View {
    let title: String?
    let content: Content
    
    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        NavigationView {
            content
                .navigationTitle(title ?? "Settings")
                .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}