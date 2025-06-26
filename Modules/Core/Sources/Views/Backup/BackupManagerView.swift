//
//  BackupManagerView.swift
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
//  Testing: CoreTests/BackupManagerViewTests.swift
//
//  Description: Main view for managing backups, creating new backups, and restoring from existing ones
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI

@available(iOS 15.0, *)
public struct BackupManagerView: View {
    @StateObject private var backupService = BackupService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingCreateBackup = false
    @State private var showingRestoreBackup = false
    @State private var showingDeleteConfirmation = false
    @State private var backupToDelete: BackupService.BackupInfo?
    @State private var showingBackupDetails = false
    @State private var selectedBackup: BackupService.BackupInfo?
    @State private var showingShareSheet = false
    @State private var shareURL: URL?
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ZStack {
                if backupService.availableBackups.isEmpty && !backupService.isCreatingBackup {
                    EmptyBackupsView(showingCreateBackup: $showingCreateBackup)
                } else {
                    backupList
                }
                
                if backupService.isCreatingBackup || backupService.isRestoringBackup {
                    BackupProgressOverlay(
                        operation: backupService.isCreatingBackup ? "Creating Backup" : "Restoring Backup",
                        progress: backupService.backupProgress,
                        currentStep: backupService.currentOperation
                    )
                }
            }
            .navigationTitle("Backups")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateBackup = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                    .disabled(backupService.isCreatingBackup || backupService.isRestoringBackup)
                }
            }
            .sheet(isPresented: $showingCreateBackup) {
                CreateBackupView()
            }
            .sheet(isPresented: $showingRestoreBackup) {
                RestoreBackupView()
            }
            .sheet(isPresented: $showingBackupDetails) {
                if let backup = selectedBackup {
                    BackupDetailsView(backup: backup)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = shareURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .alert("Delete Backup", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    if let backup = backupToDelete {
                        deleteBackup(backup)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this backup? This action cannot be undone.")
            }
        }
    }
    
    private var backupList: some View {
        List {
            // Last backup info
            if let lastBackupDate = backupService.lastBackupDate {
                Section {
                    HStack {
                        Label("Last Backup", systemImage: "clock.badge.checkmark.fill")
                            .foregroundColor(.green)
                        
                        Spacer()
                        
                        Text(lastBackupDate.formatted(.relative(presentation: .named)))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // Auto backup settings
            Section {
                NavigationLink(destination: AutoBackupSettingsView()) {
                    Label("Automatic Backups", systemImage: "arrow.clockwise.circle.fill")
                }
            }
            
            // Available backups
            Section {
                ForEach(backupService.availableBackups) { backup in
                    BackupRow(
                        backup: backup,
                        onTap: {
                            selectedBackup = backup
                            showingBackupDetails = true
                        },
                        onShare: { shareBackup(backup) },
                        onDelete: {
                            backupToDelete = backup
                            showingDeleteConfirmation = true
                        }
                    )
                }
            } header: {
                HStack {
                    Text("Available Backups")
                    Spacer()
                    Text("\(backupService.availableBackups.count)")
                        .foregroundColor(.secondary)
                }
            } footer: {
                if !backupService.availableBackups.isEmpty {
                    Text("Swipe left on a backup for more options")
                        .font(.caption)
                }
            }
            
            // Storage info
            Section {
                StorageInfoView()
            } header: {
                Text("Storage")
            }
        }
        .refreshable {
            await refreshBackups()
        }
    }
    
    private func shareBackup(_ backup: BackupService.BackupInfo) {
        shareURL = backupService.exportBackup(backup)
        showingShareSheet = true
    }
    
    private func deleteBackup(_ backup: BackupService.BackupInfo) {
        do {
            try backupService.deleteBackup(backup)
        } catch {
            // Handle error
            print("Failed to delete backup: \(error)")
        }
    }
    
    private func refreshBackups() async {
        // Refresh backup list
    }
}

// MARK: - Subviews

struct EmptyBackupsView: View {
    @Binding var showingCreateBackup: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "externaldrive.badge.timemachine")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Backups Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Create a backup to protect your inventory data")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { showingCreateBackup = true }) {
                Label("Create First Backup", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
        .padding(40)
    }
}

struct BackupRow: View {
    let backup: BackupService.BackupInfo
    let onTap: () -> Void
    let onShare: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(backup.createdDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            Label("\(backup.itemCount) items", systemImage: "cube.box")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Label(backup.formattedFileSize, systemImage: "internaldrive")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if backup.isEncrypted {
                                Label("Encrypted", systemImage: "lock.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 16) {
                    if backup.photoCount > 0 {
                        Label("\(backup.photoCount) photos", systemImage: "photo")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    if backup.receiptCount > 0 {
                        Label("\(backup.receiptCount) receipts", systemImage: "doc.text")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Label("v\(backup.appVersion)", systemImage: "app.badge")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
            
            Button(action: onShare) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            .tint(.blue)
        }
    }
}

struct BackupProgressOverlay: View {
    let operation: String
    let progress: Double
    let currentStep: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text(operation)
                    .font(.headline)
                    .foregroundColor(.white)
                
                VStack(spacing: 8) {
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .white))
                        .frame(width: 200)
                    
                    Text("\(Int(progress * 100))%")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(currentStep)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.8))
            )
        }
    }
}

struct StorageInfoView: View {
    @State private var usedSpace: Int64 = 0
    @State private var availableSpace: Int64 = 0
    
    private var totalSpace: Int64 {
        usedSpace + availableSpace
    }
    
    private var usagePercentage: Double {
        guard totalSpace > 0 else { return 0 }
        return Double(usedSpace) / Double(totalSpace)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Backup Storage")
                    .font(.subheadline)
                
                Spacer()
                
                Text("\(ByteCountFormatter.string(fromByteCount: usedSpace, countStyle: .file)) used")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(usagePercentage > 0.8 ? Color.orange : Color.blue)
                        .frame(width: geometry.size.width * usagePercentage, height: 8)
                }
            }
            .frame(height: 8)
            
            Text("\(ByteCountFormatter.string(fromByteCount: availableSpace, countStyle: .file)) available")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .onAppear {
            calculateStorageInfo()
        }
    }
    
    private func calculateStorageInfo() {
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(
                forPath: NSHomeDirectory()
            )
            
            if let totalSpace = attributes[.systemSize] as? Int64,
               let freeSpace = attributes[.systemFreeSize] as? Int64 {
                self.availableSpace = freeSpace
                self.usedSpace = totalSpace - freeSpace
            }
        } catch {
            print("Error calculating storage: \(error)")
        }
    }
}