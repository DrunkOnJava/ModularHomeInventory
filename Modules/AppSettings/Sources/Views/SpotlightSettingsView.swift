//
//  SpotlightSettingsView.swift
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
//  Dependencies: SwiftUI, Core, SharedUI
//  Testing: Modules/AppSettings/Tests/AppSettingsTests/SpotlightSettingsViewTests.swift
//
//  Description: iOS Spotlight search integration settings with indexing status, reindexing controls,
//  privacy information, and configuration for making inventory items searchable from home screen
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

//
//  SpotlightSettingsView.swift
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
//  Dependencies: SwiftUI, Core, SharedUI
//  Testing: Modules/AppSettings/Tests/Views/SpotlightSettingsViewTests.swift
//
//  Description: Spotlight search integration settings allowing configuration of system search visibility and indexing preferences
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core
import SharedUI

/// Settings view for configuring Spotlight search integration
/// Swift 5.9 - No Swift 6 features
struct SpotlightSettingsView: View {
    @StateObject private var spotlightManager = SpotlightIntegrationManager.shared
    @State private var showingReindexConfirmation = false
    @State private var showingClearConfirmation = false
    @State private var isReindexing = false
    
    var body: some View {
        List {
            // Status Section
            statusSection
            
            // Settings Section
            settingsSection
            
            // Actions Section
            actionsSection
            
            // Info Section
            infoSection
        }
        .navigationTitle("Spotlight Search")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Reindex All Items?", isPresented: $showingReindexConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reindex") {
                Task {
                    await reindexItems()
                }
            }
        } message: {
            Text("This will rebuild the entire search index. It may take a few moments.")
        }
        .alert("Clear Search Index?", isPresented: $showingClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                Task {
                    await clearIndex()
                }
            }
        } message: {
            Text("This will remove all items from Spotlight search. You can re-enable indexing later.")
        }
    }
    
    // MARK: - Sections
    
    private var statusSection: some View {
        Section {
            // Indexing status
            HStack {
                Label("Status", systemImage: "magnifyingglass")
                Spacer()
                if spotlightManager.isIndexing {
                    HStack(spacing: AppSpacing.xs) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Indexing...")
                            .textStyle(.labelMedium)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                } else if spotlightManager.isIndexingEnabled {
                    Text("Active")
                        .textStyle(.labelMedium)
                        .foregroundStyle(AppColors.success)
                } else {
                    Text("Disabled")
                        .textStyle(.labelMedium)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            
            // Indexed items count
            if spotlightManager.isIndexingEnabled {
                HStack {
                    Label("Indexed Items", systemImage: "doc.text.magnifyingglass")
                    Spacer()
                    Text("\(spotlightManager.indexedItemCount)")
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                // Last index date
                if let lastDate = spotlightManager.lastIndexDate {
                    HStack {
                        Label("Last Updated", systemImage: "clock")
                        Spacer()
                        Text(lastDate, style: .relative)
                            .textStyle(.labelMedium)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }
        } header: {
            Text("Status")
        }
    }
    
    private var settingsSection: some View {
        Section {
            // Enable/Disable indexing
            Toggle(isOn: $spotlightManager.isIndexingEnabled) {
                Label("Enable Spotlight Search", systemImage: "magnifyingglass")
            }
            .disabled(spotlightManager.isIndexing)
        } header: {
            Text("Settings")
        } footer: {
            Text("When enabled, your items will appear in iOS Spotlight search results")
                .textStyle(.labelSmall)
        }
    }
    
    private var actionsSection: some View {
        Section {
            // Reindex button
            Button(action: {
                showingReindexConfirmation = true
            }) {
                HStack {
                    Label("Reindex All Items", systemImage: "arrow.clockwise")
                        .foregroundColor(AppColors.primary)
                    Spacer()
                    if isReindexing {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .disabled(!spotlightManager.isIndexingEnabled || spotlightManager.isIndexing || isReindexing)
            
            // Clear index button
            Button(role: .destructive, action: {
                showingClearConfirmation = true
            }) {
                Label("Clear Search Index", systemImage: "trash")
            }
            .disabled(!spotlightManager.isIndexingEnabled || spotlightManager.isIndexing)
        } header: {
            Text("Actions")
        }
    }
    
    private var infoSection: some View {
        Section {
            // How it works
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Label("How It Works", systemImage: "questionmark.circle")
                    .textStyle(.labelMedium)
                    .foregroundStyle(AppColors.textPrimary)
                
                Text("• Search for items directly from the iOS home screen")
                    .textStyle(.bodySmall)
                    .foregroundStyle(AppColors.textSecondary)
                
                Text("• Find items by name, brand, model, location, or tags")
                    .textStyle(.bodySmall)
                    .foregroundStyle(AppColors.textSecondary)
                
                Text("• Tap search results to open items in the app")
                    .textStyle(.bodySmall)
                    .foregroundStyle(AppColors.textSecondary)
                
                Text("• Updates automatically when items change")
                    .textStyle(.bodySmall)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(.vertical, AppSpacing.xs)
            
            // Privacy note
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Label("Privacy", systemImage: "lock.shield")
                    .textStyle(.labelMedium)
                    .foregroundStyle(AppColors.textPrimary)
                
                Text("Your item data remains private and is only searchable on this device")
                    .textStyle(.bodySmall)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(.vertical, AppSpacing.xs)
        } header: {
            Text("Information")
        }
    }
    
    // MARK: - Actions
    
    private func reindexItems() async {
        isReindexing = true
        await spotlightManager.reindexAll()
        isReindexing = false
    }
    
    private func clearIndex() async {
        await spotlightManager.clearIndex()
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        SpotlightSettingsView()
    }
}