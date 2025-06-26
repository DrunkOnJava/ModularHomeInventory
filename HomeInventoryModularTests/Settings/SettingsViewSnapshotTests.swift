import XCTest
import SnapshotTesting
import SwiftUI
@testable import AppSettings
@testable import Core
@testable import SharedUI

final class SettingsViewSnapshotTests: SnapshotTestCase {
    
    func testSettingsView_Main() {
        let view = NavigationStack {
            EnhancedSettingsView()
        }
        
        assertSnapshot(matching: view, as: .image(on: .iPhone16ProMax))
    }
    
    func testSettingsView_DarkMode() {
        let view = NavigationStack {
            EnhancedSettingsView()
        }
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPhone16ProMax, traits: .init(userInterfaceStyle: .dark))
        )
    }
    
    func testSettingsView_iPad() {
        let view = NavigationStack {
            EnhancedSettingsView()
        }
        
        assertSnapshot(matching: view, as: .image(on: .iPadPro11))
    }
    
    func testSettingsSection_Scanner() {
        let section = List {
            Section("Scanner Settings") {
                Toggle("Sound Effects", isOn: .constant(true))
                Toggle("Haptic Feedback", isOn: .constant(true))
                Toggle("Auto-Save Scans", isOn: .constant(false))
                Toggle("Flash Light", isOn: .constant(false))
            }
        }
        .frame(height: 250)
        
        assertSnapshot(matching: section, as: .image(on: .iPhone16ProMax))
    }
    
    func testSettingsSection_Notifications() {
        let section = List {
            Section("Notifications") {
                Toggle("Warranty Expiration", isOn: .constant(true))
                Toggle("Service Reminders", isOn: .constant(true))
                Toggle("Price Alerts", isOn: .constant(false))
                HStack {
                    Text("Reminder Time")
                    Spacer()
                    Text("30 days before")
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(height: 250)
        
        assertSnapshot(matching: section, as: .image(on: .iPhone16ProMax))
    }
    
    func testAboutView() {
        let view = NavigationStack {
            AboutView()
        }
        
        assertSnapshot(matching: view, as: .image(on: .iPhone16ProMax))
    }
}