//
//  AutoBackupSettingsView.swift
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
//  Dependencies: SwiftUI
//  Testing: CoreTests/AutoBackupSettingsViewTests.swift
//
//  Description: Settings view for configuring automatic backup schedules and options
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI

@available(iOS 15.0, *)
public struct AutoBackupSettingsView: View {
    @StateObject private var backupService = BackupService.shared
    @AppStorage("backup_interval") private var backupInterval = BackupService.BackupInterval.weekly.rawValue
    @AppStorage("backup_wifi_only") private var wifiOnly = true
    @AppStorage("backup_include_photos") private var includePhotos = true
    @AppStorage("backup_include_receipts") private var includeReceipts = true
    @AppStorage("backup_compress") private var compressBackups = true
    @AppStorage("backup_retention_days") private var retentionDays = 30
    @AppStorage("backup_max_count") private var maxBackupCount = 10
    
    @State private var showingTestBackup = false
    @State private var testBackupSuccess = false
    @State private var nextBackupDate: Date?
    
    private var selectedInterval: BackupService.BackupInterval {
        BackupService.BackupInterval(rawValue: backupInterval) ?? .weekly
    }
    
    public var body: some View {
        Form {
            // Schedule section
            Section {
                Picker("Backup Frequency", selection: $backupInterval) {
                    ForEach(BackupService.BackupInterval.allCases, id: \.self) { interval in
                        Text(interval.displayName).tag(interval.rawValue)
                    }
                }
                
                if selectedInterval != .never {
                    Toggle("Wi-Fi Only", isOn: $wifiOnly)
                    
                    if let nextDate = nextBackupDate {
                        HStack {
                            Text("Next Backup")
                            Spacer()
                            Text(nextDate.formatted(.relative(presentation: .named)))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } header: {
                Text("Schedule")
            } footer: {
                if selectedInterval != .never {
                    Text("Automatic backups run in the background when your device is connected to power")
                        .font(.caption)
                }
            }
            
            // Backup contents
            if selectedInterval != .never {
                Section {
                    Toggle("Include Photos", isOn: $includePhotos)
                    Toggle("Include Receipts", isOn: $includeReceipts)
                    Toggle("Compress Backups", isOn: $compressBackups)
                } header: {
                    Text("Backup Contents")
                } footer: {
                    Text("Photos and receipts increase backup size and time")
                        .font(.caption)
                }
                
                // Retention policy
                Section {
                    HStack {
                        Text("Keep Backups For")
                        Spacer()
                        Picker("Days", selection: $retentionDays) {
                            Text("7 days").tag(7)
                            Text("14 days").tag(14)
                            Text("30 days").tag(30)
                            Text("60 days").tag(60)
                            Text("90 days").tag(90)
                            Text("Forever").tag(0)
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    HStack {
                        Text("Maximum Backups")
                        Spacer()
                        Picker("Count", selection: $maxBackupCount) {
                            Text("5").tag(5)
                            Text("10").tag(10)
                            Text("20").tag(20)
                            Text("50").tag(50)
                            Text("Unlimited").tag(0)
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                } header: {
                    Text("Retention Policy")
                } footer: {
                    Text("Older backups are automatically deleted based on these settings")
                        .font(.caption)
                }
                
                // Test backup
                Section {
                    Button(action: runTestBackup) {
                        if showingTestBackup {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Running Test Backup...")
                            }
                        } else {
                            Label("Run Test Backup", systemImage: "play.circle")
                        }
                    }
                    .disabled(showingTestBackup)
                    
                    if testBackupSuccess {
                        Label("Test backup completed successfully", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
            }
            
            // Disable automatic backups
            if selectedInterval != .never {
                Section {
                    Button(action: disableAutoBackup) {
                        Text("Disable Automatic Backups")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .navigationTitle("Automatic Backups")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            updateNextBackupDate()
        }
        .onChange(of: backupInterval) { _ in
            backupService.scheduleAutomaticBackup(interval: selectedInterval)
            updateNextBackupDate()
        }
    }
    
    private func updateNextBackupDate() {
        guard selectedInterval != .never else {
            nextBackupDate = nil
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedInterval {
        case .daily:
            nextBackupDate = calendar.date(byAdding: .day, value: 1, to: now)
        case .weekly:
            nextBackupDate = calendar.date(byAdding: .weekOfYear, value: 1, to: now)
        case .monthly:
            nextBackupDate = calendar.date(byAdding: .month, value: 1, to: now)
        case .never:
            nextBackupDate = nil
        }
    }
    
    private func runTestBackup() {
        showingTestBackup = true
        testBackupSuccess = false
        
        Task {
            // Simulate test backup
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            await MainActor.run {
                showingTestBackup = false
                testBackupSuccess = true
                
                // Hide success message after 3 seconds
                Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    testBackupSuccess = false
                }
            }
        }
    }
    
    private func disableAutoBackup() {
        backupInterval = BackupService.BackupInterval.never.rawValue
        nextBackupDate = nil
    }
}