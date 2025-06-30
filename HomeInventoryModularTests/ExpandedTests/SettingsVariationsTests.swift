import XCTest
import SnapshotTesting
import SwiftUI

final class SettingsVariationsTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set isRecording = true to generate new snapshots
        isRecording = false
    }
    
    func testGeneralSettingsView() {
        let view = GeneralSettingsView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testPrivacySettingsView() {
        let view = PrivacySettingsView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testNotificationSettingsView() {
        let view = NotificationSettingsView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testDataStorageSettingsView() {
        let view = DataStorageSettingsView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testAboutScreenView() {
        let view = AboutScreenView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
}

// MARK: - Helper Views

struct GeneralSettingsView: View {
    var body: some View {
        NavigationView {
            Form {
                Section("Appearance") {
                    Picker("Theme", selection: .constant(0)) {
                        Label("System", systemImage: "iphone").tag(0)
                        Label("Light", systemImage: "sun.max").tag(1)
                        Label("Dark", systemImage: "moon").tag(2)
                    }
                    
                    Picker("App Icon", selection: .constant(0)) {
                        Text("Default").tag(0)
                        Text("Dark").tag(1)
                        Text("Colorful").tag(2)
                    }
                }
                
                Section("Display") {
                    Toggle("Compact View", isOn: .constant(false))
                    Toggle("Show Item Values", isOn: .constant(true))
                    Toggle("Show Thumbnails", isOn: .constant(true))
                    
                    Picker("Default Sort", selection: .constant(0)) {
                        Text("Recently Added").tag(0)
                        Text("Name (A-Z)").tag(1)
                        Text("Value (High-Low)").tag(2)
                    }
                }
                
                Section("Currency") {
                    Picker("Currency", selection: .constant(0)) {
                        Text("USD ($)").tag(0)
                        Text("EUR (€)").tag(1)
                        Text("GBP (£)").tag(2)
                        Text("JPY (¥)").tag(3)
                    }
                }
                
                Section("Units") {
                    Picker("Weight", selection: .constant(0)) {
                        Text("Pounds (lb)").tag(0)
                        Text("Kilograms (kg)").tag(1)
                    }
                    
                    Picker("Dimensions", selection: .constant(0)) {
                        Text("Inches (in)").tag(0)
                        Text("Centimeters (cm)").tag(1)
                    }
                }
            }
            .navigationTitle("General")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct PrivacySettingsView: View {
    var body: some View {
        NavigationView {
            Form {
                Section("Security") {
                    Toggle("Require Authentication", isOn: .constant(true))
                    
                    HStack {
                        Image(systemName: "faceid")
                            .foregroundColor(.green)
                        Text("Face ID")
                        Spacer()
                        Text("Enabled")
                            .foregroundColor(.secondary)
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    
                    Toggle("Auto-Lock", isOn: .constant(true))
                    
                    Picker("Auto-Lock After", selection: .constant(1)) {
                        Text("Immediately").tag(0)
                        Text("1 Minute").tag(1)
                        Text("5 Minutes").tag(2)
                        Text("15 Minutes").tag(3)
                    }
                }
                
                Section("Data Privacy") {
                    Toggle("Analytics", isOn: .constant(false))
                    Toggle("Crash Reports", isOn: .constant(false))
                    Toggle("Share Usage Data", isOn: .constant(false))
                }
                
                Section("Export Restrictions") {
                    Toggle("Include Photos in Export", isOn: .constant(true))
                    Toggle("Include Purchase Info", isOn: .constant(false))
                    Toggle("Include Serial Numbers", isOn: .constant(true))
                }
                
                Section {
                    Button(action: {}) {
                        Text("Clear Cache")
                    }
                    
                    Button(action: {}) {
                        Text("Reset Privacy Settings")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct NotificationSettingsView: View {
    var body: some View {
        NavigationView {
            Form {
                Section("Push Notifications") {
                    Toggle("Enable Notifications", isOn: .constant(true))
                }
                
                Section("Notification Types") {
                    NotificationToggle(
                        icon: "exclamationmark.shield",
                        title: "Warranty Expiration",
                        subtitle: "30 days before expiry",
                        isOn: true
                    )
                    
                    NotificationToggle(
                        icon: "arrow.triangle.2.circlepath",
                        title: "Backup Reminders",
                        subtitle: "Weekly reminders",
                        isOn: true
                    )
                    
                    NotificationToggle(
                        icon: "dollarsign.circle",
                        title: "Price Alerts",
                        subtitle: "When values change",
                        isOn: false
                    )
                    
                    NotificationToggle(
                        icon: "bell",
                        title: "General Updates",
                        subtitle: "New features & tips",
                        isOn: true
                    )
                }
                
                Section("Notification Schedule") {
                    Toggle("Do Not Disturb", isOn: .constant(false))
                    
                    DatePicker("Quiet Hours Start", selection: .constant(Date(timeIntervalSince1970: 1698710400)), displayedComponents: .hourAndMinute)
                    
                    DatePicker("Quiet Hours End", selection: .constant(Date(timeIntervalSince1970: 1698739200)), displayedComponents: .hourAndMinute)
                }
                
                Section("Badge") {
                    Toggle("Show Badge Count", isOn: .constant(true))
                    Picker("Badge Shows", selection: .constant(0)) {
                        Text("All Notifications").tag(0)
                        Text("Important Only").tag(1)
                        Text("None").tag(2)
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct NotificationToggle: View {
    let icon: String
    let title: String
    let subtitle: String
    let isOn: Bool
    
    var body: some View {
        Toggle(isOn: .constant(isOn)) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                VStack(alignment: .leading) {
                    Text(title)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct DataStorageSettingsView: View {
    var body: some View {
        NavigationView {
            Form {
                Section("Storage") {
                    HStack {
                        Text("Photos")
                        Spacer()
                        Text("2.4 GB")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Documents")
                        Spacer()
                        Text("124 MB")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Cache")
                        Spacer()
                        Text("89 MB")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Total")
                            .fontWeight(.semibold)
                        Spacer()
                        Text("2.6 GB")
                            .foregroundColor(.secondary)
                            .fontWeight(.semibold)
                    }
                }
                
                Section("iCloud Sync") {
                    Toggle("iCloud Sync", isOn: .constant(true))
                    Toggle("Sync Photos", isOn: .constant(true))
                    Toggle("Sync Documents", isOn: .constant(true))
                    
                    HStack {
                        Text("Last Sync")
                        Spacer()
                        Text("2 minutes ago")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Auto-Backup") {
                    Toggle("Enable Auto-Backup", isOn: .constant(true))
                    
                    Picker("Backup Frequency", selection: .constant(1)) {
                        Text("Daily").tag(0)
                        Text("Weekly").tag(1)
                        Text("Monthly").tag(2)
                    }
                    
                    Toggle("Only on Wi-Fi", isOn: .constant(true))
                    Toggle("Include Photos", isOn: .constant(true))
                }
                
                Section {
                    Button(action: {}) {
                        Label("Backup Now", systemImage: "icloud.and.arrow.up")
                    }
                    
                    Button(action: {}) {
                        Label("Export All Data", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: {}) {
                        Text("Clear Cache")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Data & Storage")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct AboutScreenView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 40) {
                    // App icon and version
                    VStack(spacing: 16) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text("Home Inventory")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Version 2.1.0 (Build 142)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Info sections
                    VStack(spacing: 24) {
                        AboutSection(
                            title: "What's New",
                            items: [
                                "• Enhanced photo capture",
                                "• Improved search functionality",
                                "• Bug fixes and performance improvements"
                            ]
                        )
                        
                        AboutSection(
                            title: "Support",
                            items: [
                                "• Email: support@homeinventory.app",
                                "• Website: www.homeinventory.app",
                                "• Twitter: @homeinventoryapp"
                            ]
                        )
                    }
                    .padding(.horizontal)
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        Button(action: {}) {
                            Label("Rate on App Store", systemImage: "star")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        
                        Button(action: {}) {
                            Label("Share App", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray5))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Footer
                    VStack(spacing: 8) {
                        Text("Made with ❤️ in San Francisco")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 16) {
                            Button("Privacy Policy") {}
                                .font(.footnote)
                            Button("Terms of Service") {}
                                .font(.footnote)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct AboutSection: View {
    let title: String
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}