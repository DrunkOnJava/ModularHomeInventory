//
//  ConflictResolutionView.swift
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
//  Testing: Modules/Sync/Tests/SyncTests/ConflictResolutionViewTests.swift
//
//  Description: Main conflict resolution view that displays all sync conflicts with resolution options
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core
import SharedUI

/// Main conflict resolution view that displays all sync conflicts
/// Swift 5.9 - No Swift 6 features
public struct ConflictResolutionView: View {
    @StateObject private var viewModel: ConflictResolutionViewModel
    @State private var selectedConflict: SyncConflict?
    @State private var showingDetailView = false
    @State private var showingBatchResolution = false
    @State private var selectedStrategy: ConflictResolution = .keepLocal
    
    public init(
        conflictService: ConflictResolutionService,
        itemRepository: any ItemRepository,
        receiptRepository: any ReceiptRepository,
        locationRepository: any LocationRepository
    ) {
        self._viewModel = StateObject(wrappedValue: ConflictResolutionViewModel(
            conflictService: conflictService,
            itemRepository: itemRepository,
            receiptRepository: receiptRepository,
            locationRepository: locationRepository
        ))
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                if viewModel.conflicts.isEmpty {
                    emptyStateView
                } else {
                    conflictListView
                }
                
                if viewModel.isLoading {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        
                        VStack(spacing: AppSpacing.md) {
                            ProgressView()
                                .scaleEffect(1.5)
                            
                            Text("Detecting conflicts...")
                                .textStyle(.bodyMedium)
                                .foregroundStyle(.white)
                        }
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(AppCornerRadius.medium)
                    }
                }
            }
            .navigationTitle("Sync Conflicts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $showingDetailView) {
                if let conflict = selectedConflict {
                    ConflictDetailView(
                        conflict: conflict,
                        viewModel: viewModel,
                        onResolved: {
                            selectedConflict = nil
                            showingDetailView = false
                        }
                    )
                }
            }
            .sheet(isPresented: $showingBatchResolution) {
                BatchResolutionView(
                    conflicts: viewModel.conflicts,
                    viewModel: viewModel,
                    onComplete: {
                        showingBatchResolution = false
                    }
                )
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
        }
    }
    
    // MARK: - Views
    
    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "checkmark.icloud.fill")
                .font(.system(size: 64))
                .foregroundStyle(AppColors.success)
            
            Text("No Conflicts")
                .textStyle(.headlineLarge)
                .foregroundStyle(AppColors.textPrimary)
            
            Text("All your data is synchronized")
                .textStyle(.bodyMedium)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var conflictListView: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                // Summary card
                summaryCard
                
                // Conflict groups
                ForEach(SyncConflict.EntityType.allCases, id: \.self) { entityType in
                    let conflicts = viewModel.conflicts.filter { $0.entityType == entityType }
                    if !conflicts.isEmpty {
                        ConflictGroupView(
                            entityType: entityType,
                            conflicts: conflicts,
                            onSelectConflict: { conflict in
                                selectedConflict = conflict
                                showingDetailView = true
                            }
                        )
                    }
                }
            }
            .padding()
        }
        .background(AppColors.background)
    }
    
    private var summaryCard: some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Conflicts Found")
                        .textStyle(.labelMedium)
                        .foregroundStyle(AppColors.textSecondary)
                    
                    Text("\(viewModel.conflicts.count)")
                        .textStyle(.headlineLarge)
                        .foregroundStyle(AppColors.error)
                }
                
                Spacer()
                
                Image(systemName: "exclamationmark.icloud.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(AppColors.error)
            }
            
            // Quick stats
            HStack(spacing: AppSpacing.xl) {
                StatItem(
                    label: "Items",
                    value: "\(viewModel.itemConflictCount)",
                    icon: "shippingbox"
                )
                
                StatItem(
                    label: "Receipts",
                    value: "\(viewModel.receiptConflictCount)",
                    icon: "doc.text"
                )
                
                StatItem(
                    label: "Locations",
                    value: "\(viewModel.locationConflictCount)",
                    icon: "location"
                )
            }
            
            if viewModel.conflicts.count > 1 {
                Button(action: { showingBatchResolution = true }) {
                    Label("Resolve All", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding()
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.large)
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: { Task { await viewModel.refreshConflicts() } }) {
                Image(systemName: "arrow.clockwise")
            }
        }
    }
}

// MARK: - Conflict Group View

private struct ConflictGroupView: View {
    let entityType: SyncConflict.EntityType
    let conflicts: [SyncConflict]
    let onSelectConflict: (SyncConflict) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Label(entityType.rawValue, systemImage: entityType.icon)
                    .textStyle(.headlineMedium)
                    .foregroundStyle(AppColors.textPrimary)
                
                Spacer()
                
                Text("\(conflicts.count)")
                    .textStyle(.bodyMedium)
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, 4)
                    .background(AppColors.error.opacity(0.1))
                    .cornerRadius(AppCornerRadius.small)
            }
            
            VStack(spacing: AppSpacing.xs) {
                ForEach(conflicts) { conflict in
                    ConflictRowView(
                        conflict: conflict,
                        onTap: { onSelectConflict(conflict) }
                    )
                }
            }
        }
        .padding()
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.medium)
    }
}

// MARK: - Conflict Row View

private struct ConflictRowView: View {
    let conflict: SyncConflict
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(conflict.conflictType.displayName)
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    HStack(spacing: AppSpacing.sm) {
                        Label(
                            conflict.localVersion.modifiedAt.formatted(date: .abbreviated, time: .shortened),
                            systemImage: "iphone"
                        )
                        .textStyle(.labelSmall)
                        .foregroundStyle(AppColors.textSecondary)
                        
                        if let deviceName = conflict.localVersion.deviceName {
                            Text("• \(deviceName)")
                                .textStyle(.labelSmall)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding(.vertical, AppSpacing.sm)
            .padding(.horizontal, AppSpacing.md)
            .background(AppColors.background)
            .cornerRadius(AppCornerRadius.small)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Supporting Views

private struct StatItem: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AppColors.primary)
            
            Text(value)
                .textStyle(.bodyLarge)
                .foregroundStyle(AppColors.textPrimary)
            
            Text(label)
                .textStyle(.labelSmall)
                .foregroundStyle(AppColors.textSecondary)
        }
    }
}

// MARK: - View Model

@MainActor
public final class ConflictResolutionViewModel: ObservableObject {
    @Published var conflicts: [SyncConflict] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    
    private let conflictService: ConflictResolutionService
    private let itemRepository: any ItemRepository
    private let receiptRepository: any ReceiptRepository
    private let locationRepository: any LocationRepository
    
    var itemConflictCount: Int {
        conflicts.filter { $0.entityType == .item }.count
    }
    
    var receiptConflictCount: Int {
        conflicts.filter { $0.entityType == .receipt }.count
    }
    
    var locationConflictCount: Int {
        conflicts.filter { $0.entityType == .location }.count
    }
    
    init(
        conflictService: ConflictResolutionService,
        itemRepository: any ItemRepository,
        receiptRepository: any ReceiptRepository,
        locationRepository: any LocationRepository
    ) {
        self.conflictService = conflictService
        self.itemRepository = itemRepository
        self.receiptRepository = receiptRepository
        self.locationRepository = locationRepository
        
        self.conflicts = conflictService.activeConflicts
    }
    
    func refreshConflicts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // In a real app, this would fetch from remote
            // For now, just refresh from the service
            conflicts = conflictService.activeConflicts
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func resolveConflict(_ conflict: SyncConflict, resolution: ConflictResolution) async {
        do {
            _ = try await conflictService.resolveConflict(conflict, resolution: resolution)
            conflicts = conflictService.activeConflicts
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func resolveAllConflicts(strategy: ConflictResolution) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            _ = try await conflictService.resolveAllConflicts(strategy: strategy)
            conflicts = conflictService.activeConflicts
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func getConflictDetails(_ conflict: SyncConflict) async throws -> ConflictDetails {
        try await conflictService.getConflictDetails(conflict)
    }
}