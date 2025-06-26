//
//  SubscriptionManagementView.swift
//  Premium Module
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
//  Module: Premium
//  Dependencies: SwiftUI, SharedUI
//  Testing: Modules/Premium/Tests/PremiumTests.swift
//
//  Description: Subscription management interface for existing premium users.
//               Displays current subscription status, available features, and
//               provides options to upgrade, restore, or cancel subscriptions.
//
//  Created by Griffin Long on June 26, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import SharedUI

/// Subscription management view
/// Swift 5.9 - No Swift 6 features
struct SubscriptionManagementView: View {
    @ObservedObject var module: PremiumModule
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // Current status
                statusSection
                
                // Features
                featuresSection
                
                // Actions
                actionsSection
            }
            .navigationTitle("Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var statusSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Status")
                        .textStyle(.labelMedium)
                        .foregroundColor(AppColors.textSecondary)
                    
                    HStack {
                        Image(systemName: module.isPremium ? "crown.fill" : "crown")
                            .foregroundColor(module.isPremium ? Color.yellow : AppColors.textTertiary)
                        
                        Text(module.isPremium ? "Premium" : "Free")
                            .textStyle(.bodyLarge)
                            .fontWeight(.semibold)
                    }
                }
                
                Spacer()
                
                if module.isPremium {
                    VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                        Text("Active")
                            .textStyle(.labelMedium)
                            .foregroundColor(AppColors.success)
                        
                        Text("Renews monthly")
                            .textStyle(.labelSmall)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .appPadding(.vertical, AppSpacing.sm)
        }
    }
    
    private var featuresSection: some View {
        Section("Your Features") {
            ForEach(PremiumFeature.allCases, id: \.self) { feature in
                HStack {
                    Image(systemName: feature.iconName)
                        .foregroundColor(AppColors.primary)
                        .frame(width: 24)
                    
                    Text(feature.displayName)
                        .textStyle(.bodyMedium)
                    
                    Spacer()
                    
                    if !module.requiresPremium(feature) || module.isPremium {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppColors.success)
                    } else {
                        Text("Premium")
                            .textStyle(.labelSmall)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
        }
    }
    
    private var actionsSection: some View {
        Section {
            if !module.isPremium {
                Button(action: {
                    // Show upgrade view
                }) {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundColor(Color.yellow)
                        Text("Upgrade to Premium")
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
            }
            
            Button(action: {
                // Restore purchases
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Restore Purchases")
                }
            }
            
            if module.isPremium {
                Button(role: .destructive, action: {
                    // Cancel subscription
                }) {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text("Cancel Subscription")
                    }
                }
            }
        }
    }
}