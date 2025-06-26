//
//  CollectionDetailView.swift
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
//  Module: Items
//  Dependencies: SwiftUI, Core, SharedUI
//  Testing: Modules/Items/Tests/ItemsTests/CollectionDetailViewTests.swift
//
//  Description: Detail view for displaying and managing items within a collection
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core
import SharedUI

/// View for displaying items in a collection
/// Swift 5.9 - No Swift 6 features
public struct CollectionDetailView: View {
    @StateObject private var viewModel: CollectionDetailViewModel
    @State private var showingAddItems = false
    @State private var showingEditCollection = false
    @State private var selectedItems: Set<UUID> = []
    @State private var isEditMode = false
    
    public init(
        collection: Collection,
        collectionRepository: any CollectionRepository,
        itemRepository: any ItemRepository,
        onSelectItem: @escaping (Item) -> Void
    ) {
        self._viewModel = StateObject(
            wrappedValue: CollectionDetailViewModel(
                collection: collection,
                collectionRepository: collectionRepository,
                itemRepository: itemRepository,
                onSelectItem: onSelectItem
            )
        )
    }
    
    public var body: some View {
        List {
            // Collection Info Header
            Section {
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: viewModel.collection.icon)
                        .font(.largeTitle)
                        .foregroundStyle(Color.named(viewModel.collection.color))
                        .frame(width: 60, height: 60)
                        .background(Color.named(viewModel.collection.color).opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        if let description = viewModel.collection.description {
                            Text(description)
                                .textStyle(.bodyMedium)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        
                        HStack(spacing: AppSpacing.sm) {
                            Label("\(viewModel.items.count) items", systemImage: "square.grid.2x2")
                                .textStyle(.labelMedium)
                                .foregroundStyle(AppColors.textTertiary)
                            
                            if viewModel.totalValue > 0 {
                                Text("•")
                                    .foregroundStyle(AppColors.textTertiary)
                                
                                Label(viewModel.totalValue.formatted(.currency(code: "USD")), systemImage: "dollarsign.circle")
                                    .textStyle(.labelMedium)
                                    .foregroundStyle(AppColors.textTertiary)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical, AppSpacing.sm)
            }
            
            // Items Section
            if !viewModel.items.isEmpty {
                Section {
                    ForEach(viewModel.items) { item in
                        ItemRow(
                            item: item,
                            isSelected: selectedItems.contains(item.id),
                            isEditMode: isEditMode,
                            onTap: {
                                if isEditMode {
                                    toggleSelection(for: item.id)
                                } else {
                                    viewModel.selectItem(item)
                                }
                            }
                        )
                    }
                } header: {
                    HStack {
                        Text("Items")
                        Spacer()
                        if isEditMode {
                            Button("Done") {
                                isEditMode = false
                                selectedItems.removeAll()
                            }
                        } else {
                            Button("Edit") {
                                isEditMode = true
                            }
                        }
                    }
                }
            } else if !viewModel.isLoading {
                Section {
                    ContentUnavailableView(
                        "No Items",
                        systemImage: "square.stack",
                        description: Text("Add items to this collection to see them here")
                    )
                }
            }
            
            if viewModel.isLoading {
                Section {
                    HStack {
                        ProgressView()
                        Text("Loading items...")
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }
        }
        .navigationTitle(viewModel.collection.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingAddItems = true }) {
                        Label("Add Items", systemImage: "plus.square")
                    }
                    
                    Button(action: { showingEditCollection = true }) {
                        Label("Edit Collection", systemImage: "pencil")
                    }
                    
                    if viewModel.collection.isArchived {
                        Button(action: { viewModel.unarchiveCollection() }) {
                            Label("Unarchive", systemImage: "tray.and.arrow.up")
                        }
                    } else {
                        Button(action: { viewModel.archiveCollection() }) {
                            Label("Archive", systemImage: "archivebox")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            
            if isEditMode && !selectedItems.isEmpty {
                ToolbarItem(placement: .bottomBar) {
                    Button(role: .destructive) {
                        viewModel.removeItems(Array(selectedItems))
                        selectedItems.removeAll()
                        isEditMode = false
                    } label: {
                        Label("Remove \(selectedItems.count) Items", systemImage: "minus.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddItems) {
            AddItemsToCollectionView(
                collection: viewModel.collection,
                collectionRepository: viewModel.collectionRepository,
                itemRepository: viewModel.itemRepository,
                onComplete: {
                    viewModel.loadItems()
                }
            )
        }
        .sheet(isPresented: $showingEditCollection) {
            AddEditCollectionView(
                collection: viewModel.collection,
                collectionRepository: viewModel.collectionRepository,
                onComplete: { updatedCollection in
                    viewModel.updateCollection(updatedCollection)
                }
            )
        }
        .onAppear {
            viewModel.loadItems()
        }
    }
    
    private func toggleSelection(for itemId: UUID) {
        if selectedItems.contains(itemId) {
            selectedItems.remove(itemId)
        } else {
            selectedItems.insert(itemId)
        }
    }
}

// MARK: - Item Row
private struct ItemRow: View {
    let item: Item
    let isSelected: Bool
    let isEditMode: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.md) {
                if isEditMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isSelected ? AppColors.primary : AppColors.textTertiary)
                }
                
                // Item icon
                Image(systemName: item.category.icon)
                    .font(.body)
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 36, height: 36)
                    .background(AppColors.primary.opacity(0.1))
                    .clipShape(Circle())
                
                // Item info
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .textStyle(.bodyLarge)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: AppSpacing.xs) {
                        if let brand = item.brand {
                            Text(brand)
                                .textStyle(.labelSmall)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        
                        if let value = item.value {
                            if item.brand != nil {
                                Text("•")
                                    .textStyle(.labelSmall)
                                    .foregroundStyle(AppColors.textTertiary)
                            }
                            Text(value.formatted(.currency(code: "USD")))
                                .textStyle(.labelSmall)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                }
                
                Spacer()
                
                if !isEditMode {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
            .padding(.vertical, AppSpacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - View Model
@MainActor
final class CollectionDetailViewModel: ObservableObject {
    @Published var collection: Collection
    @Published var items: [Item] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    let collectionRepository: any CollectionRepository
    let itemRepository: any ItemRepository
    let onSelectItem: (Item) -> Void
    
    var totalValue: Decimal {
        items.compactMap { $0.value }.reduce(0, +)
    }
    
    init(
        collection: Collection,
        collectionRepository: any CollectionRepository,
        itemRepository: any ItemRepository,
        onSelectItem: @escaping (Item) -> Void
    ) {
        self.collection = collection
        self.collectionRepository = collectionRepository
        self.itemRepository = itemRepository
        self.onSelectItem = onSelectItem
    }
    
    func loadItems() {
        Task {
            isLoading = true
            do {
                let allItems = try await itemRepository.fetchAll()
                items = allItems.filter { collection.itemIds.contains($0.id) }
                    .sorted { $0.name < $1.name }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    func selectItem(_ item: Item) {
        onSelectItem(item)
    }
    
    func updateCollection(_ updatedCollection: Collection) {
        collection = updatedCollection
    }
    
    func archiveCollection() {
        Task {
            do {
                try await collectionRepository.archive(collection.id)
                collection.isArchived = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func unarchiveCollection() {
        Task {
            do {
                try await collectionRepository.unarchive(collection.id)
                collection.isArchived = false
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func removeItems(_ itemIds: [UUID]) {
        Task {
            do {
                for itemId in itemIds {
                    try await collectionRepository.removeItem(itemId, from: collection.id)
                }
                await loadItems()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}