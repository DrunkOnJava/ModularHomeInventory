//
//  SavedSearchesView.swift
//  Items Module
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
//  Module: Items
//  Dependencies: SwiftUI, Core, SharedUI
//  Testing: ItemsTests/SavedSearchesViewTests.swift
//
//  Description: View for managing and executing saved search queries
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core
import SharedUI

/// View for managing saved searches
/// Swift 5.9 - No Swift 6 features
struct SavedSearchesView: View {
    @StateObject private var viewModel: SavedSearchesViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddSearch = false
    @State private var editingSearch: SavedSearch?
    @State private var showingDeleteConfirmation = false
    @State private var searchToDelete: SavedSearch?
    
    init(
        savedSearchRepository: any SavedSearchRepository,
        onSelectSearch: @escaping (SavedSearch) -> Void
    ) {
        self._viewModel = StateObject(wrappedValue: SavedSearchesViewModel(
            savedSearchRepository: savedSearchRepository,
            onSelectSearch: onSelectSearch
        ))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if viewModel.searches.isEmpty {
                    emptyStateView
                } else {
                    searchesList
                }
            }
            .navigationTitle("Saved Searches")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddSearch = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSearch) {
                AddSavedSearchView(
                    savedSearchRepository: viewModel.savedSearchRepository,
                    onSave: { savedSearch in
                        Task {
                            await viewModel.loadSearches()
                        }
                    }
                )
            }
            .sheet(item: $editingSearch) { search in
                EditSavedSearchView(
                    search: search,
                    savedSearchRepository: viewModel.savedSearchRepository,
                    onSave: { updatedSearch in
                        Task {
                            await viewModel.loadSearches()
                        }
                    }
                )
            }
            .alert("Delete Saved Search", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let search = searchToDelete {
                        Task {
                            await viewModel.deleteSearch(search)
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to delete this saved search?")
            }
        }
        .task {
            await viewModel.loadSearches()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "bookmark")
                .font(.system(size: 60))
                .foregroundStyle(AppColors.textTertiary)
            
            VStack(spacing: AppSpacing.sm) {
                Text("No Saved Searches")
                    .textStyle(.headlineMedium)
                    .foregroundStyle(AppColors.textSecondary)
                
                Text("Save your frequently used searches for quick access")
                    .textStyle(.bodyMedium)
                    .foregroundStyle(AppColors.textTertiary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                showingAddSearch = true
            }) {
                Label("Create Saved Search", systemImage: "plus")
                    .textStyle(.bodyMedium)
                    .foregroundStyle(AppColors.primary)
            }
        }
        .padding(AppSpacing.xl)
    }
    
    private var searchesList: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                // Pinned searches
                if let pinnedSearches = viewModel.pinnedSearches, !pinnedSearches.isEmpty {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Pinned")
                            .textStyle(.labelMedium)
                            .foregroundStyle(AppColors.textSecondary)
                            .padding(.horizontal)
                        
                        ForEach(pinnedSearches) { search in
                            SavedSearchRow(
                                search: search,
                                onTap: {
                                    viewModel.selectSearch(search)
                                    dismiss()
                                },
                                onEdit: {
                                    editingSearch = search
                                },
                                onDelete: {
                                    searchToDelete = search
                                    showingDeleteConfirmation = true
                                },
                                onTogglePin: {
                                    Task {
                                        await viewModel.togglePin(search)
                                    }
                                }
                            )
                        }
                    }
                }
                
                // Other searches
                if let otherSearches = viewModel.otherSearches, !otherSearches.isEmpty {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        if viewModel.pinnedSearches?.isEmpty == false {
                            Text("Other Searches")
                                .textStyle(.labelMedium)
                                .foregroundStyle(AppColors.textSecondary)
                                .padding(.horizontal)
                                .padding(.top)
                        }
                        
                        ForEach(otherSearches) { search in
                            SavedSearchRow(
                                search: search,
                                onTap: {
                                    viewModel.selectSearch(search)
                                    dismiss()
                                },
                                onEdit: {
                                    editingSearch = search
                                },
                                onDelete: {
                                    searchToDelete = search
                                    showingDeleteConfirmation = true
                                },
                                onTogglePin: {
                                    Task {
                                        await viewModel.togglePin(search)
                                    }
                                }
                            )
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .background(AppColors.background)
    }
}

// MARK: - Saved Search Row
struct SavedSearchRow: View {
    let search: SavedSearch
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onTogglePin: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.md) {
                // Icon with color
                ZStack {
                    Circle()
                        .fill(Color(hex: search.color).opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: search.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(Color(hex: search.color))
                }
                
                // Search details
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(search.name)
                        .textStyle(.bodyLarge)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)
                    
                    Text(search.query)
                        .textStyle(.bodySmall)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)
                    
                    HStack(spacing: AppSpacing.sm) {
                        Label(search.searchType.displayName, systemImage: search.searchType.icon)
                            .textStyle(.labelSmall)
                            .foregroundStyle(AppColors.textTertiary)
                        
                        if search.useCount > 0 {
                            Text("•")
                                .foregroundStyle(AppColors.textTertiary)
                            
                            Text("Used \(search.useCount) times")
                                .textStyle(.labelSmall)
                                .foregroundStyle(AppColors.textTertiary)
                        }
                    }
                }
                
                Spacer()
                
                // Pin indicator
                if search.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundStyle(AppColors.primary)
                }
            }
            .padding()
            .background(AppColors.surface)
            .cornerRadius(AppCornerRadius.medium)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .contextMenu {
            Button(action: onTogglePin) {
                Label(search.isPinned ? "Unpin" : "Pin", 
                      systemImage: search.isPinned ? "pin.slash" : "pin")
            }
            
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - View Model
@MainActor
final class SavedSearchesViewModel: ObservableObject {
    @Published var searches: [SavedSearch] = []
    @Published var isLoading = false
    
    var pinnedSearches: [SavedSearch]? {
        searches.isEmpty ? nil : searches.filter { $0.isPinned }
    }
    
    var otherSearches: [SavedSearch]? {
        searches.isEmpty ? nil : searches.filter { !$0.isPinned }
    }
    
    let savedSearchRepository: any SavedSearchRepository
    private let onSelectSearch: (SavedSearch) -> Void
    
    init(
        savedSearchRepository: any SavedSearchRepository,
        onSelectSearch: @escaping (SavedSearch) -> Void
    ) {
        self.savedSearchRepository = savedSearchRepository
        self.onSelectSearch = onSelectSearch
    }
    
    func loadSearches() async {
        isLoading = true
        do {
            searches = try await savedSearchRepository.fetchAll()
        } catch {
            print("Failed to load saved searches: \(error)")
        }
        isLoading = false
    }
    
    func deleteSearch(_ search: SavedSearch) async {
        do {
            try await savedSearchRepository.delete(search)
            await loadSearches()
        } catch {
            print("Failed to delete saved search: \(error)")
        }
    }
    
    func togglePin(_ search: SavedSearch) async {
        do {
            let updated = search.togglePinned()
            try await savedSearchRepository.update(updated)
            await loadSearches()
        } catch {
            print("Failed to toggle pin: \(error)")
        }
    }
    
    func selectSearch(_ search: SavedSearch) {
        Task {
            try? await savedSearchRepository.recordUsage(of: search)
        }
        onSelectSearch(search)
    }
}