//
//  WarrantyListView.swift
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
//  Testing: ItemsTests/WarrantyListViewTests.swift
//
//  Description: List view for displaying and managing warranty records
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core
import SharedUI

public struct WarrantyListView: View {
    @StateObject private var viewModel: WarrantyListViewModel
    @State private var selectedFilter: WarrantyFilter = .all
    @State private var selectedWarranty: Warranty?
    @State private var showingAddWarranty = false
    
    public init(itemRepository: any ItemRepository, warrantyRepository: any WarrantyRepository) {
        _viewModel = StateObject(wrappedValue: WarrantyListViewModel(
            itemRepository: itemRepository,
            warrantyRepository: warrantyRepository
        ))
    }
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter chips
                filterChips
                
                // List
                if viewModel.warranties.isEmpty {
                    emptyState
                } else {
                    warrantyList
                }
            }
            .background(AppColors.secondaryBackground)
            .navigationTitle("Warranties")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddWarranty = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddWarranty) {
                // This would show warranty search/add view
                Text("Add Warranty - Coming Soon")
                    .presentationDetents([.medium])
            }
            .sheet(item: $selectedWarranty) { warranty in
                NavigationView {
                    WarrantyDetailView(
                        warranty: warranty,
                        itemRepository: viewModel.itemRepository,
                        warrantyRepository: viewModel.warrantyRepository
                    )
                }
            }
        }
        .onAppear {
            viewModel.loadWarranties()
        }
    }
    
    // MARK: - Components
    
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(WarrantyFilter.allCases, id: \.self) { filter in
                    WarrantyFilterChip(
                        filter: filter,
                        isSelected: selectedFilter == filter,
                        count: viewModel.getCount(for: filter),
                        action: {
                            selectedFilter = filter
                            viewModel.applyFilter(filter)
                        }
                    )
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
        }
    }
    
    private var warrantyList: some View {
        List {
            ForEach(viewModel.groupedWarranties, id: \.0) { section, warranties in
                Section(header: Text(section)) {
                    ForEach(warranties) { warranty in
                        Button(action: { selectedWarranty = warranty }) {
                            WarrantyRowView(
                                warranty: warranty,
                                item: viewModel.items[warranty.itemId]
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private var emptyState: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "shield.slash")
                .font(.system(size: 60))
                .foregroundStyle(AppColors.textTertiary)
            
            Text("No Warranties")
                .textStyle(.headlineMedium)
                .foregroundStyle(AppColors.textPrimary)
            
            Text("Add warranties to track expiration dates")
                .textStyle(.bodyMedium)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button(action: { showingAddWarranty = true }) {
                Label("Add First Warranty", systemImage: "plus.circle")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.secondaryBackground)
    }
}

// MARK: - Warranty Row View

private struct WarrantyRowView: View {
    let warranty: Warranty
    let item: Item?
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Status icon
            Image(systemName: warranty.status.icon)
                .font(.title3)
                .foregroundStyle(statusColor)
                .frame(width: 40, height: 40)
                .background(statusColor.opacity(0.1))
                .clipShape(Circle())
            
            // Info
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(item?.name ?? "Unknown Item")
                    .textStyle(.bodyLarge)
                    .foregroundStyle(AppColors.textPrimary)
                
                HStack(spacing: AppSpacing.md) {
                    Label(warranty.provider, systemImage: warranty.type.icon)
                        .textStyle(.labelMedium)
                        .foregroundStyle(AppColors.textSecondary)
                    
                    if case .expiringSoon = warranty.status {
                        Text("\(warranty.daysRemaining) days left")
                            .textStyle(.labelSmall)
                            .foregroundStyle(AppColors.warning)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, AppSpacing.xxs)
                            .background(AppColors.warning.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                
                Text("Expires: \(warranty.endDate.formatted(date: .abbreviated, time: .omitted))")
                    .textStyle(.labelSmall)
                    .foregroundStyle(AppColors.textTertiary)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppColors.textTertiary)
        }
        .padding(.vertical, AppSpacing.xs)
    }
    
    private var statusColor: Color {
        switch warranty.status {
        case .active: return AppColors.success
        case .expiringSoon(_): return AppColors.warning
        case .expired: return AppColors.error
        }
    }
}

// MARK: - View Model

@MainActor
final class WarrantyListViewModel: ObservableObject {
    @Published var warranties: [Warranty] = []
    @Published var items: [UUID: Item] = [:]
    
    let itemRepository: any ItemRepository
    let warrantyRepository: any WarrantyRepository
    
    private var currentFilter: WarrantyFilter = .all
    private var allWarranties: [Warranty] = []
    
    init(itemRepository: any ItemRepository, warrantyRepository: any WarrantyRepository) {
        self.itemRepository = itemRepository
        self.warrantyRepository = warrantyRepository
    }
    
    func loadWarranties() {
        Task {
            do {
                allWarranties = try await warrantyRepository.fetchAll()
                applyFilter(currentFilter)
                await loadItems()
            } catch {
                print("Error loading warranties: \(error)")
            }
        }
    }
    
    private func loadItems() async {
        let itemIds = Set(warranties.map { $0.itemId })
        
        for id in itemIds {
            do {
                if let item = try await itemRepository.fetch(id: id) {
                    items[id] = item
                }
            } catch {
                print("Error loading item \(id): \(error)")
            }
        }
    }
    
    func applyFilter(_ filter: WarrantyFilter) {
        currentFilter = filter
        warranties = allWarranties.filter { warranty in
            switch filter {
            case .all:
                return true
            case .active:
                if case .active = warranty.status { return true }
                return false
            case .expiringSoon:
                if case .expiringSoon = warranty.status { return true }
                return false
            case .expired:
                if case .expired = warranty.status { return true }
                return false
            case .electronics:
                return items[warranty.itemId]?.category == .electronics
            case .appliances:
                return items[warranty.itemId]?.category == .appliances
            }
        }
    }
    
    func getCount(for filter: WarrantyFilter) -> Int {
        allWarranties.filter { warranty in
            switch filter {
            case .all:
                return true
            case .active:
                if case .active = warranty.status { return true }
                return false
            case .expiringSoon:
                if case .expiringSoon = warranty.status { return true }
                return false
            case .expired:
                if case .expired = warranty.status { return true }
                return false
            case .electronics:
                return items[warranty.itemId]?.category == .electronics
            case .appliances:
                return items[warranty.itemId]?.category == .appliances
            }
        }.count
    }
    
    var groupedWarranties: [(String, [Warranty])] {
        let grouped = Dictionary(grouping: warranties) { warranty -> String in
            switch warranty.status {
            case .expired:
                return "Expired"
            case .expiringSoon:
                return "Expiring Soon"
            case .active:
                let days = warranty.daysRemaining
                if days <= 90 {
                    return "Less than 3 months"
                } else if days <= 180 {
                    return "3-6 months"
                } else if days <= 365 {
                    return "6-12 months"
                } else {
                    return "More than 1 year"
                }
            }
        }
        
        // Sort sections
        let sectionOrder = ["Expiring Soon", "Less than 3 months", "3-6 months", "6-12 months", "More than 1 year", "Expired"]
        return sectionOrder.compactMap { section in
            if let warranties = grouped[section] {
                return (section, warranties.sorted { $0.endDate < $1.endDate })
            }
            return nil
        }
    }
}

// MARK: - Warranty Filter Chip

private struct WarrantyFilterChip: View {
    let filter: WarrantyFilter
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: filter.icon)
                    .font(.caption)
                
                Text(filter.rawValue)
                    .textStyle(.labelMedium)
                
                if count > 0 {
                    Text("\(count)")
                        .textStyle(.labelSmall)
                        .padding(.horizontal, AppSpacing.xs)
                        .background(isSelected ? AppColors.primary.opacity(0.2) : AppColors.surface)
                        .clipShape(Capsule())
                }
            }
            .foregroundStyle(isSelected ? AppColors.primary : AppColors.textSecondary)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(isSelected ? AppColors.primary.opacity(0.1) : AppColors.surface)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? AppColors.primary : AppColors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Warranty Filter

enum WarrantyFilter: String, CaseIterable {
    case all = "All"
    case active = "Active"
    case expiringSoon = "Expiring Soon"
    case expired = "Expired"
    case electronics = "Electronics"
    case appliances = "Appliances"
    
    var icon: String {
        switch self {
        case .all: return "shield"
        case .active: return "checkmark.shield"
        case .expiringSoon: return "exclamationmark.shield"
        case .expired: return "xmark.shield"
        case .electronics: return "tv"
        case .appliances: return "refrigerator"
        }
    }
}