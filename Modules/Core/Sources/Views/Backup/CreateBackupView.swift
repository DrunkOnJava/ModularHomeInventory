//
//  CreateBackupView.swift
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
//  Dependencies: SwiftUI, UniformTypeIdentifiers
//  Testing: CoreTests/CreateBackupViewTests.swift
//
//  Description: View for creating a new backup with customizable options for content inclusion and security
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI

@available(iOS 15.0, *)
public struct CreateBackupView: View {
    @StateObject private var backupService = BackupService.shared
    @Environment(\.dismiss) private var dismiss
    
    // Options
    @State private var includePhotos = true
    @State private var includeReceipts = true
    @State private var includeDocuments = true
    @State private var compressBackup = true
    @State private var encryptBackup = false
    @State private var encryptionPassword = ""
    @State private var confirmPassword = ""
    @State private var excludeDeleted = true
    
    // State
    @State private var showingPasswordMismatch = false
    @State private var showingBackupSuccess = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var createdBackupURL: URL?
    
    // Inject data sources
    @State private var items: [Item] = []
    @State private var categories: [String] = []
    @State private var locations: [Location] = []
    @State private var collections: [Collection] = []
    @State private var warranties: [Warranty] = []
    @State private var receipts: [Receipt] = []
    @State private var tags: [Tag] = []
    @State private var storageUnits: [StorageUnit] = []
    @State private var budgets: [Budget] = []
    
    private var estimatedSize: Int64 {
        backupService.estimateBackupSize(
            itemCount: items.count,
            photoCount: includePhotos ? items.reduce(0) { $0 + $1.imageIds.count } : 0,
            receiptCount: includeReceipts ? receipts.count : 0,
            compress: compressBackup
        )
    }
    
    private var isValid: Bool {
        if encryptBackup {
            return !encryptionPassword.isEmpty &&
                   encryptionPassword == confirmPassword &&
                   encryptionPassword.count >= 8
        }
        return true
    }
    
    public var body: some View {
        NavigationView {
            Form {
                // Backup contents
                Section {
                    BackupContentRow(
                        title: "Items",
                        count: items.count,
                        icon: "cube.box.fill",
                        color: .blue
                    )
                    
                    Toggle("Include Photos", isOn: $includePhotos)
                        .disabled(items.allSatisfy { $0.imageIds.isEmpty })
                    
                    Toggle("Include Receipts", isOn: $includeReceipts)
                        .disabled(receipts.isEmpty)
                    
                    Toggle("Include Documents", isOn: $includeDocuments)
                        .disabled(warranties.allSatisfy { $0.documentIds.isEmpty })
                    
                    Toggle("Exclude Deleted Items", isOn: $excludeDeleted)
                } header: {
                    Text("Backup Contents")
                } footer: {
                    Text("Photos and documents significantly increase backup size")
                        .font(.caption)
                }
                
                // Backup options
                Section {
                    Toggle("Compress Backup", isOn: $compressBackup)
                    
                    Toggle("Encrypt Backup", isOn: $encryptBackup.animation())
                    
                    if encryptBackup {
                        SecureField("Password", text: $encryptionPassword)
                            .textContentType(.newPassword)
                        
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textContentType(.newPassword)
                        
                        if !encryptionPassword.isEmpty && encryptionPassword.count < 8 {
                            Label("Password must be at least 8 characters", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        
                        if !confirmPassword.isEmpty && encryptionPassword != confirmPassword {
                            Label("Passwords don't match", systemImage: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                } header: {
                    Text("Backup Options")
                } footer: {
                    if encryptBackup {
                        Text("⚠️ Important: Store your password safely. Encrypted backups cannot be restored without the password.")
                            .font(.caption)
                    }
                }
                
                // Size estimate
                Section {
                    HStack {
                        Label("Estimated Size", systemImage: "internaldrive")
                        
                        Spacer()
                        
                        Text(ByteCountFormatter.string(fromByteCount: estimatedSize, countStyle: .file))
                            .foregroundColor(.secondary)
                    }
                } footer: {
                    Text("Actual size may vary based on content and compression")
                        .font(.caption)
                }
                
                // Create button
                Section {
                    Button(action: createBackup) {
                        if backupService.isCreatingBackup {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Creating Backup...")
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            Label("Create Backup", systemImage: "externaldrive.badge.plus")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(!isValid || backupService.isCreatingBackup)
                }
            }
            .navigationTitle("Create Backup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(backupService.isCreatingBackup)
                }
            }
            .alert("Backup Created", isPresented: $showingBackupSuccess) {
                Button("Share") {
                    if let url = createdBackupURL {
                        shareBackup(url)
                    }
                }
                Button("Done") {
                    dismiss()
                }
            } message: {
                Text("Your backup has been created successfully.")
            }
            .alert("Backup Failed", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                loadData()
            }
        }
    }
    
    private func loadData() {
        // In a real app, this would load from Core Data or the data source
        // For now, using mock data
        Task {
            // Load items, categories, etc. from your data source
        }
    }
    
    private func createBackup() {
        Task {
            do {
                var options: Set<BackupService.BackupOptions> = []
                
                if includePhotos { options.insert(.includePhotos) }
                if includeReceipts { options.insert(.includeReceipts) }
                if includeDocuments { options.insert(.includeDocuments) }
                if compressBackup { options.insert(.compress) }
                if encryptBackup {
                    options.insert(.encrypt(password: encryptionPassword))
                }
                if excludeDeleted { options.insert(.excludeDeleted) }
                
                let url = try await backupService.createBackup(
                    items: items,
                    categories: categories,
                    locations: locations,
                    collections: collections,
                    warranties: warranties,
                    receipts: receipts,
                    tags: tags,
                    storageUnits: storageUnits,
                    budgets: budgets,
                    options: options
                )
                
                createdBackupURL = url
                showingBackupSuccess = true
                
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func shareBackup(_ url: URL) {
        // This would present a share sheet
        // Implementation depends on the app's sharing infrastructure
    }
}

// MARK: - Subviews

struct BackupContentRow: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(title)
            
            Spacer()
            
            Text("\(count)")
                .foregroundColor(.secondary)
                .fontWeight(.medium)
        }
    }
}