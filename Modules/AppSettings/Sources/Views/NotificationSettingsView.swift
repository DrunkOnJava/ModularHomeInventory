//
//  NotificationSettingsView.swift
//  AppSettings Module
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
//  Module: AppSettings
//  Dependencies: SwiftUI, Core
//  Testing: Modules/AppSettings/Tests/AppSettingsTests/NotificationSettingsViewTests.swift
//
//  Description: Comprehensive notification settings management with authorization handling,
//  notification type toggles, quiet hours configuration, and test notification functionality
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core

/// View for managing notification settings
/// Swift 5.9 - No Swift 6 features
struct NotificationSettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var showingPermissionAlert = false
    @State private var isLoadingPermission = false
    
    var body: some View {
        List {
            // Authorization Status Section
            Section {
                HStack {
                    Label("Notifications", systemImage: "bell")
                    Spacer()
                    
                    if notificationManager.isAuthorized {
                        Text("Enabled")
                            .foregroundColor(.green)
                    } else {
                        Button("Enable") {
                            requestPermission()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(isLoadingPermission)
                    }
                }
                
                if !notificationManager.isAuthorized {
                    Text("Enable notifications to receive alerts about warranties, price drops, and more.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Notification Types Section
            if notificationManager.isAuthorized {
                Section {
                    ForEach(NotificationManager.NotificationType.allCases, id: \.self) { type in
                        NotificationTypeRow(
                            type: type,
                            isEnabled: notificationManager.notificationSettings.isEnabled(for: type),
                            onToggle: {
                                notificationManager.notificationSettings.toggle(type)
                            }
                        )
                    }
                } header: {
                    Text("Notification Types")
                } footer: {
                    Text("Choose which types of notifications you want to receive.")
                }
                
                // Sound & Badge Settings
                Section {
                    Toggle(isOn: $notificationManager.notificationSettings.soundEnabled) {
                        Label("Sound", systemImage: "speaker.wave.2")
                    }
                    
                    Toggle(isOn: $notificationManager.notificationSettings.badgeEnabled) {
                        Label("Badge App Icon", systemImage: "app.badge")
                    }
                } header: {
                    Text("Alert Settings")
                }
                
                // Quiet Hours
                Section {
                    Toggle(isOn: $notificationManager.notificationSettings.quietHoursEnabled) {
                        Label("Quiet Hours", systemImage: "moon")
                    }
                    
                    if notificationManager.notificationSettings.quietHoursEnabled {
                        QuietHoursRow(
                            startTime: $notificationManager.notificationSettings.quietHoursStart,
                            endTime: $notificationManager.notificationSettings.quietHoursEnd
                        )
                    }
                } header: {
                    Text("Do Not Disturb")
                } footer: {
                    Text("Notifications will be silenced during quiet hours.")
                }
                
                // Test Notification
                Section {
                    Button(action: sendTestNotification) {
                        Label("Send Test Notification", systemImage: "bell.badge")
                    }
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            notificationManager.checkAuthorizationStatus()
            Task {
                await notificationManager.loadPendingNotifications()
            }
        }
        .alert("Notification Permission", isPresented: $showingPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable notifications in Settings to receive alerts.")
        }
    }
    
    private func requestPermission() {
        isLoadingPermission = true
        
        Task {
            let granted = await notificationManager.requestAuthorization()
            
            await MainActor.run {
                isLoadingPermission = false
                if !granted {
                    showingPermissionAlert = true
                }
            }
        }
    }
    
    private func sendTestNotification() {
        Task {
            let request = NotificationRequest(
                type: .customAlert,
                title: "Test Notification",
                body: "Your notifications are working correctly!",
                timeInterval: 5
            )
            
            do {
                try await notificationManager.scheduleNotification(request)
            } catch {
                print("Failed to send test notification: \(error)")
            }
        }
    }
}

// MARK: - Subviews

struct NotificationTypeRow: View {
    let type: NotificationManager.NotificationType
    let isEnabled: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Toggle(isOn: .init(
            get: { isEnabled },
            set: { _ in onToggle() }
        )) {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.displayName)
                        .font(.body)
                    
                    Text(descriptionForType(type))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } icon: {
                Image(systemName: type.icon)
                    .foregroundColor(.accentColor)
            }
        }
    }
    
    private func descriptionForType(_ type: NotificationManager.NotificationType) -> String {
        switch type {
        case .warrantyExpiration:
            return "Get notified before warranties expire"
        case .priceAlert:
            return "Alert when tracked items drop in price"
        case .lowStock:
            return "Notify when items reach low quantity"
        case .budgetAlert:
            return "Alert when approaching budget limits"
        case .receiptProcessed:
            return "Notify when receipts are processed"
        case .syncComplete:
            return "Alert when sync operations complete"
        case .itemRecall:
            return "Important safety recall notifications"
        case .maintenanceReminder:
            return "Remind about scheduled maintenance"
        case .customAlert:
            return "Custom alerts and reminders"
        }
    }
}

struct QuietHoursRow: View {
    @Binding var startTime: DateComponents
    @Binding var endTime: DateComponents
    
    @State private var startDate = Date()
    @State private var endDate = Date()
    
    var body: some View {
        VStack(spacing: 12) {
            DatePicker("From", selection: $startDate, displayedComponents: .hourAndMinute)
                .onChange(of: startDate) { newValue in
                    let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                    startTime = components
                }
            
            DatePicker("To", selection: $endDate, displayedComponents: .hourAndMinute)
                .onChange(of: endDate) { newValue in
                    let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                    endTime = components
                }
        }
        .onAppear {
            // Convert DateComponents to Date for the pickers
            var calendar = Calendar.current
            calendar.timeZone = TimeZone.current
            
            if let hour = startTime.hour, let minute = startTime.minute {
                startDate = calendar.date(from: DateComponents(hour: hour, minute: minute)) ?? Date()
            }
            
            if let hour = endTime.hour, let minute = endTime.minute {
                endDate = calendar.date(from: DateComponents(hour: hour, minute: minute)) ?? Date()
            }
        }
    }
}

// MARK: - Preview

struct NotificationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NotificationSettingsView()
        }
    }
}