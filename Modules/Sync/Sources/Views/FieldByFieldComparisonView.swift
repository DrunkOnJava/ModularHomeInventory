//
//  FieldByFieldComparisonView.swift
//  HomeInventoryModular
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
//  Module: Sync
//  Dependencies: SwiftUI, Core, SharedUI
//  Testing: Modules/Sync/Tests/SyncTests/FieldByFieldComparisonViewTests.swift
//
//  Description: Field-by-field comparison view for custom merge resolution with granular conflict handling
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core
import SharedUI

/// Field-by-field comparison view for custom merge resolution
/// Swift 5.9 - No Swift 6 features
struct FieldByFieldComparisonView: View {
    let conflict: SyncConflict
    let details: ConflictDetails
    @Binding var fieldResolutions: [FieldResolution]
    
    @State private var resolutions: [String: FieldResolution.FieldResolutionType] = [:]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Instructions
                    instructionsCard
                    
                    // Field comparisons
                    ForEach(details.changes) { change in
                        FieldComparisonCard(
                            change: change,
                            resolution: Binding(
                                get: { resolutions[change.fieldName] ?? .useLocal },
                                set: { resolutions[change.fieldName] = $0 }
                            )
                        )
                    }
                }
                .padding()
            }
            .background(AppColors.background)
            .navigationTitle("Custom Merge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applyResolutions()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            initializeResolutions()
        }
    }
    
    // MARK: - Components
    
    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.title2)
                    .foregroundStyle(AppColors.primary)
                
                Text("Choose values for each field")
                    .textStyle(.headlineMedium)
                    .foregroundStyle(AppColors.textPrimary)
            }
            
            Text("Select which version to keep for each conflicting field. You can also choose special merge strategies for certain fields.")
                .textStyle(.bodyMedium)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding()
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.medium)
    }
    
    // MARK: - Methods
    
    private func initializeResolutions() {
        for change in details.changes {
            resolutions[change.fieldName] = .useLocal
        }
    }
    
    private func applyResolutions() {
        fieldResolutions = resolutions.map { fieldName, resolutionType in
            FieldResolution(fieldName: fieldName, resolution: resolutionType)
        }
    }
}

// MARK: - Field Comparison Card

private struct FieldComparisonCard: View {
    let change: FieldChange
    @Binding var resolution: FieldResolution.FieldResolutionType
    @State private var showingOptions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Field name header
            HStack {
                Text(change.displayName)
                    .textStyle(.headlineSmall)
                    .foregroundStyle(AppColors.textPrimary)
                
                Spacer()
                
                if change.isConflicting {
                    Label("Conflict", systemImage: "exclamationmark.triangle.fill")
                        .textStyle(.labelSmall)
                        .foregroundStyle(AppColors.warning)
                }
            }
            
            // Value comparison
            VStack(spacing: AppSpacing.sm) {
                // Local value
                ValueOption(
                    label: "Local",
                    value: change.oldValue ?? "No value",
                    icon: "iphone",
                    isSelected: resolution == .useLocal
                ) {
                    resolution = .useLocal
                }
                
                // Remote value
                ValueOption(
                    label: "Remote",
                    value: change.newValue ?? "No value",
                    icon: "icloud",
                    isSelected: resolution == .useRemote
                ) {
                    resolution = .useRemote
                }
                
                // Special options for certain field types
                if canHaveSpecialOptions(for: change) {
                    Button(action: { showingOptions.toggle() }) {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                                .font(.body)
                            
                            Text("More Options")
                                .textStyle(.bodyMedium)
                            
                            Spacer()
                            
                            Image(systemName: showingOptions ? "chevron.up" : "chevron.down")
                                .font(.caption)
                        }
                        .foregroundStyle(AppColors.primary)
                        .padding(.vertical, AppSpacing.sm)
                    }
                    
                    if showingOptions {
                        specialOptionsView(for: change)
                    }
                }
            }
        }
        .padding()
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.medium)
    }
    
    private func canHaveSpecialOptions(for change: FieldChange) -> Bool {
        // Check if field can have special merge options
        let numericFields = ["quantity", "purchasePrice", "value"]
        let textFields = ["name", "description", "notes"]
        
        return numericFields.contains(change.fieldName) || textFields.contains(change.fieldName)
    }
    
    @ViewBuilder
    private func specialOptionsView(for change: FieldChange) -> some View {
        VStack(spacing: AppSpacing.sm) {
            let numericFields = ["quantity", "purchasePrice", "value"]
            let textFields = ["name", "description", "notes"]
            
            if numericFields.contains(change.fieldName) {
                ValueOption(
                    label: "Average",
                    value: "Use average of both values",
                    icon: "divide.circle",
                    isSelected: resolution == .average
                ) {
                    resolution = .average
                }
            }
            
            if textFields.contains(change.fieldName) {
                ValueOption(
                    label: "Concatenate",
                    value: "Combine both values",
                    icon: "text.append",
                    isSelected: resolution == .concatenate(separator: " ")
                ) {
                    resolution = .concatenate(separator: " ")
                }
            }
            
            ValueOption(
                label: "Latest",
                value: "Use most recently modified",
                icon: "clock.arrow.circlepath",
                isSelected: resolution == .latest
            ) {
                resolution = .latest
            }
        }
        .padding(.top, AppSpacing.xs)
    }
}

// MARK: - Value Option

private struct ValueOption: View {
    let label: String
    let value: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(isSelected ? AppColors.primary : AppColors.textSecondary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .textStyle(.labelMedium)
                        .foregroundStyle(AppColors.textSecondary)
                    
                    Text(value)
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppColors.primary)
                }
            }
            .padding()
            .background(isSelected ? AppColors.primary.opacity(0.1) : AppColors.background)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.small)
                    .stroke(isSelected ? AppColors.primary : AppColors.divider, lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(AppCornerRadius.small)
        }
        .buttonStyle(.plain)
    }
}