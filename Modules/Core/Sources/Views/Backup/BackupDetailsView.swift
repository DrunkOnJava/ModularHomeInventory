//
//  BackupDetailsView.swift
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
//  Testing: CoreTests/BackupDetailsViewTests.swift
//
//  Description: Detailed view for a specific backup
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI

@available(iOS 15.0, *)
public struct BackupDetailsView: View {
    let backup: BackupService.BackupInfo
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingShareSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var showingRestoreView = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .medium
        return formatter
    }()
    
    public var body: some View {
        NavigationView {
            List {
                // Overview section
                Section {
                    BackupDetailRow(label: "Created", value: dateFormatter.string(from: backup.createdDate))
                    BackupDetailRow(label: "Size", value: backup.formattedFileSize)
                    BackupDetailRow(label: "Device", value: backup.deviceName)
                    BackupDetailRow(label: "App Version", value: backup.appVersion)
                    
                    if backup.isEncrypted {
                        HStack {
                            Label("Encryption", systemImage: "lock.fill")
                                .foregroundColor(.orange)
                            Spacer()
                            Text("Enabled")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if backup.compressionRatio > 1.0 {
                        BackupDetailRow(
                            label: "Compression",
                            value: String(format: "%.1fx", backup.compressionRatio)
                        )
                    }
                } header: {
                    Text("Backup Information")
                }
                
                // Contents section
                Section {
                    ContentRow(
                        icon: "cube.box.fill",
                        label: "Items",
                        count: backup.itemCount,
                        color: .blue
                    )
                    
                    if backup.photoCount > 0 {
                        ContentRow(
                            icon: "photo.fill",
                            label: "Photos",
                            count: backup.photoCount,
                            color: .green
                        )
                    }
                    
                    if backup.receiptCount > 0 {
                        ContentRow(
                            icon: "doc.text.fill",
                            label: "Receipts",
                            count: backup.receiptCount,
                            color: .orange
                        )
                    }
                } header: {
                    Text("Contents")
                }
                
                // Technical details
                Section {
                    BackupDetailRow(label: "Backup ID", value: backup.id.uuidString, monospaced: true)
                    BackupDetailRow(label: "Checksum", value: String(backup.checksum.prefix(16)) + "...", monospaced: true)
                } header: {
                    Text("Technical Details")
                }
                
                // Actions
                Section {
                    Button(action: { showingRestoreView = true }) {
                        Label("Restore from This Backup", systemImage: "arrow.down.doc.fill")
                    }
                    
                    Button(action: shareBackup) {
                        Label("Share Backup", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: { showingDeleteConfirmation = true }) {
                        Label("Delete Backup", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Backup Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(activityItems: [BackupService.shared.exportBackup(backup)])
            }
            .sheet(isPresented: $showingRestoreView) {
                RestoreBackupView()
            }
            .alert("Delete Backup", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    deleteBackup()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this backup? This action cannot be undone.")
            }
        }
    }
    
    private func shareBackup() {
        showingShareSheet = true
    }
    
    private func deleteBackup() {
        do {
            try BackupService.shared.deleteBackup(backup)
            dismiss()
        } catch {
            // Handle error
            print("Failed to delete backup: \(error)")
        }
    }
}

// MARK: - Subviews

struct BackupDetailRow: View {
    let label: String
    let value: String
    var monospaced: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(monospaced ? .system(.body, design: .monospaced) : .body)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}

struct ContentRow: View {
    let icon: String
    let label: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(label)
            
            Spacer()
            
            Text("\(count)")
                .foregroundColor(.secondary)
                .fontWeight(.medium)
        }
    }
}