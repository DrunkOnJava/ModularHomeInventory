//
//  ConflictDetailView.swift
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
//  Testing: Modules/Sync/Tests/SyncTests/ConflictDetailViewTests.swift
//
//  Description: Detailed view for resolving a single conflict with field-by-field comparison and merge options
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core
import SharedUI

/// Detailed view for resolving a single conflict with field-by-field comparison
/// Swift 5.9 - No Swift 6 features
struct ConflictDetailView: View {
    let conflict: SyncConflict
    @ObservedObject var viewModel: ConflictResolutionViewModel
    let onResolved: () -> Void
    
    @State private var selectedResolution: ConflictResolution = .keepLocal
    @State private var showingFieldComparison = false
    @State private var fieldResolutions: [FieldResolution] = []
    @State private var isResolving = false
    @State private var conflictDetails: ConflictDetails?
    @State private var loadingDetails = true
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                if loadingDetails {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                } else {
                    VStack(spacing: AppSpacing.lg) {
                        // Conflict header
                        conflictHeaderCard
                        
                        // Version comparison
                        versionComparisonCard
                        
                        // Field changes
                        if let details = conflictDetails {
                            fieldChangesCard(details: details)
                        }
                        
                        // Resolution options
                        resolutionOptionsCard
                        
                        // Action buttons
                        actionButtons
                    }
                    .padding()
                }
            }
            .background(AppColors.background)
            .navigationTitle("Resolve Conflict")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingFieldComparison) {
                if let details = conflictDetails {
                    FieldByFieldComparisonView(
                        conflict: conflict,
                        details: details,
                        fieldResolutions: $fieldResolutions
                    )
                }
            }
        }
        .task {
            await loadConflictDetails()
        }
    }
    
    // MARK: - Components
    
    private var conflictHeaderCard: some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                Image(systemName: conflict.entityType.icon)
                    .font(.system(size: 32))
                    .foregroundStyle(AppColors.error)
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(conflict.conflictType.displayName)
                        .textStyle(.headlineMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Text(conflict.entityType.rawValue)
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                Spacer()
            }
            
            Text(conflict.conflictType.description)
                .textStyle(.bodyMedium)
                .foregroundStyle(AppColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.medium)
    }
    
    private var versionComparisonCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Version Comparison")
                .textStyle(.headlineMedium)
                .foregroundStyle(AppColors.textPrimary)
            
            HStack(spacing: AppSpacing.sm) {
                // Local version
                VersionCard(
                    title: "Local Version",
                    version: conflict.localVersion,
                    icon: "iphone",
                    isSelected: selectedResolution == .keepLocal
                ) {
                    selectedResolution = .keepLocal
                }
                
                // Remote version
                VersionCard(
                    title: "Remote Version",
                    version: conflict.remoteVersion,
                    icon: "icloud",
                    isSelected: selectedResolution == .keepRemote
                ) {
                    selectedResolution = .keepRemote
                }
            }
        }
        .padding()
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.medium)
    }
    
    private func fieldChangesCard(details: ConflictDetails) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Field Changes")
                    .textStyle(.headlineMedium)
                    .foregroundStyle(AppColors.textPrimary)
                
                Spacer()
                
                if !details.changes.isEmpty {
                    Text("\(details.changes.count) changes")
                        .textStyle(.labelMedium)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            
            if details.changes.isEmpty {
                Text("No field changes detected")
                    .textStyle(.bodyMedium)
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.vertical)
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(details.changes.prefix(3)) { change in
                        FieldChangeRow(change: change)
                    }
                    
                    if details.changes.count > 3 {
                        Button(action: { showingFieldComparison = true }) {
                            HStack {
                                Text("View all \(details.changes.count) changes")
                                    .textStyle(.bodyMedium)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.footnote)
                            }
                            .foregroundStyle(AppColors.primary)
                        }
                        .padding(.top, AppSpacing.xs)
                    }
                }
            }
        }
        .padding()
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.medium)
    }
    
    private var resolutionOptionsCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Resolution Strategy")
                .textStyle(.headlineMedium)
                .foregroundStyle(AppColors.textPrimary)
            
            VStack(spacing: AppSpacing.sm) {
                ResolutionOptionRow(
                    title: "Keep Local",
                    description: "Use your device's version",
                    icon: "iphone",
                    isSelected: selectedResolution == .keepLocal
                ) {
                    selectedResolution = .keepLocal
                }
                
                ResolutionOptionRow(
                    title: "Keep Remote",
                    description: "Use the cloud version",
                    icon: "icloud",
                    isSelected: selectedResolution == .keepRemote
                ) {
                    selectedResolution = .keepRemote
                }
                
                ResolutionOptionRow(
                    title: "Merge Changes",
                    description: "Combine both versions intelligently",
                    icon: "arrow.triangle.merge",
                    isSelected: selectedResolution == .merge(.latestWins)
                ) {
                    selectedResolution = .merge(.latestWins)
                }
                
                if conflictDetails != nil && !conflictDetails!.changes.isEmpty {
                    ResolutionOptionRow(
                        title: "Custom Merge",
                        description: "Choose field by field",
                        icon: "slider.horizontal.3",
                        isSelected: false
                    ) {
                        showingFieldComparison = true
                    }
                }
            }
        }
        .padding()
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.medium)
    }
    
    private var actionButtons: some View {
        VStack(spacing: AppSpacing.md) {
            Button(action: { Task { await resolveConflict() } }) {
                if isResolving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Apply Resolution")
                }
            }
            .frame(maxWidth: .infinity)
            .disabled(isResolving)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Button("Cancel") {
                dismiss()
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }
    
    // MARK: - Methods
    
    private func loadConflictDetails() async {
        do {
            conflictDetails = try await viewModel.getConflictDetails(conflict)
            loadingDetails = false
        } catch {
            // Handle error
            loadingDetails = false
        }
    }
    
    private func resolveConflict() async {
        isResolving = true
        defer { isResolving = false }
        
        let resolution: ConflictResolution
        if !fieldResolutions.isEmpty {
            resolution = .merge(.fieldLevel(fieldResolutions))
        } else {
            resolution = selectedResolution
        }
        
        await viewModel.resolveConflict(conflict, resolution: resolution)
        onResolved()
        dismiss()
    }
}

// MARK: - Supporting Views

private struct VersionCard: View {
    let title: String
    let version: ConflictVersion
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(isSelected ? AppColors.primary : AppColors.textSecondary)
                    
                    Text(title)
                        .textStyle(.labelMedium)
                        .foregroundStyle(AppColors.textPrimary)
                }
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Label(
                        version.modifiedAt.formatted(date: .abbreviated, time: .shortened),
                        systemImage: "clock"
                    )
                    .textStyle(.labelSmall)
                    .foregroundStyle(AppColors.textSecondary)
                    
                    if let deviceName = version.deviceName {
                        Label(deviceName, systemImage: "desktopcomputer")
                            .textStyle(.labelSmall)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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

private struct FieldChangeRow: View {
    let change: FieldChange
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(change.displayName)
                    .textStyle(.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
                
                HStack(spacing: AppSpacing.sm) {
                    if let oldValue = change.oldValue {
                        Text(oldValue)
                            .textStyle(.labelSmall)
                            .foregroundStyle(AppColors.error)
                            .strikethrough()
                    }
                    
                    if change.oldValue != nil && change.newValue != nil {
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                    
                    if let newValue = change.newValue {
                        Text(newValue)
                            .textStyle(.labelSmall)
                            .foregroundStyle(AppColors.success)
                    }
                }
            }
            
            Spacer()
            
            if change.isConflicting {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(AppColors.warning)
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }
}

private struct ResolutionOptionRow: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? AppColors.primary : AppColors.textSecondary)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Text(description)
                        .textStyle(.labelSmall)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppColors.primary)
                }
            }
            .padding(.vertical, AppSpacing.sm)
            .padding(.horizontal, AppSpacing.md)
            .background(isSelected ? AppColors.primary.opacity(0.1) : AppColors.background)
            .cornerRadius(AppCornerRadius.small)
        }
        .buttonStyle(.plain)
    }
}