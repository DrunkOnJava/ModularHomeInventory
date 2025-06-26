//
//  WidgetUpdateService.swift
//  Widgets Module
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
//  Module: Widgets
//  Dependencies: Foundation, Core, WidgetKit
//  Testing: Modules/Widgets/Tests/WidgetsTests.swift
//
//  Description: Widget update service for managing home screen widget data.
//               Coordinates with repositories to fetch fresh data, handles periodic
//               updates, and manages app lifecycle integration for widget refreshes.
//
//  Created by Griffin Long on June 26, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation
import Core
import WidgetKit

/// Service to update widget data from the main app
/// Swift 5.9 - No Swift 6 features
@MainActor
public final class WidgetUpdateService: ObservableObject {
    public static let shared = WidgetUpdateService()
    
    private let dataProvider: WidgetDataProvider?
    private var updateTimer: Timer?
    
    private init() {
        // In a real app, these would be injected
        self.dataProvider = nil
    }
    
    public func configure(
        itemRepository: any ItemRepository,
        receiptRepository: any ReceiptRepository,
        warrantyRepository: any WarrantyRepository,
        budgetRepository: (any BudgetRepository)?
    ) {
        // Create data provider with repositories
        let provider = WidgetDataProvider(
            itemRepository: itemRepository,
            receiptRepository: receiptRepository,
            warrantyRepository: warrantyRepository,
            budgetRepository: budgetRepository
        )
        
        // Would store this for later use
        // self.dataProvider = provider
        
        // Start periodic updates
        startPeriodicUpdates()
    }
    
    /// Update all widget data
    public func updateAllWidgets() async {
        guard let dataProvider = dataProvider else { return }
        
        await withTaskGroup(of: Void.self) { group in
            // Update inventory stats
            group.addTask {
                if let stats = try? await dataProvider.getInventoryStats() {
                    await MainActor.run {
                        WidgetSharedContainer.saveInventoryStats(stats)
                    }
                }
            }
            
            // Update spending summary
            group.addTask {
                if let summary = try? await dataProvider.getSpendingSummary() {
                    await MainActor.run {
                        WidgetSharedContainer.saveSpendingSummary(summary)
                    }
                }
            }
            
            // Update warranty expirations
            group.addTask {
                if let expirations = try? await dataProvider.getWarrantyExpirations() {
                    await MainActor.run {
                        WidgetSharedContainer.saveWarrantyExpirations(expirations)
                    }
                }
            }
            
            // Update recent items
            group.addTask {
                if let items = try? await dataProvider.getRecentItems() {
                    await MainActor.run {
                        WidgetSharedContainer.saveRecentItems(items)
                    }
                }
            }
        }
    }
    
    /// Update a specific widget type
    public func updateWidget(kind: WidgetKind) async {
        guard let dataProvider = dataProvider else { return }
        
        switch kind {
        case .inventoryStats:
            if let stats = try? await dataProvider.getInventoryStats() {
                WidgetSharedContainer.saveInventoryStats(stats)
            }
        case .spendingSummary:
            if let summary = try? await dataProvider.getSpendingSummary() {
                WidgetSharedContainer.saveSpendingSummary(summary)
            }
        case .warrantyExpiration:
            if let expirations = try? await dataProvider.getWarrantyExpirations() {
                WidgetSharedContainer.saveWarrantyExpirations(expirations)
            }
        case .recentItems:
            if let items = try? await dataProvider.getRecentItems() {
                WidgetSharedContainer.saveRecentItems(items)
            }
        }
    }
    
    /// Start periodic widget updates
    private func startPeriodicUpdates() {
        // Update every 30 minutes
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { _ in
            Task { @MainActor in
                await self.updateAllWidgets()
            }
        }
        
        // Initial update
        Task {
            await updateAllWidgets()
        }
    }
    
    /// Stop periodic updates
    public func stopPeriodicUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    /// Widget types
    public enum WidgetKind {
        case inventoryStats
        case spendingSummary
        case warrantyExpiration
        case recentItems
    }
}

// MARK: - App Lifecycle Integration

public extension WidgetUpdateService {
    /// Call when app becomes active
    func appDidBecomeActive() {
        Task {
            await updateAllWidgets()
        }
    }
    
    /// Call when app enters background
    func appDidEnterBackground() {
        Task {
            await updateAllWidgets()
        }
    }
    
    /// Call when significant data changes occur
    func significantDataChanged(type: DataChangeType) {
        Task {
            switch type {
            case .itemAdded, .itemUpdated, .itemDeleted:
                await updateWidget(kind: .inventoryStats)
                await updateWidget(kind: .recentItems)
            case .receiptAdded, .receiptUpdated:
                await updateWidget(kind: .spendingSummary)
            case .warrantyAdded, .warrantyUpdated:
                await updateWidget(kind: .warrantyExpiration)
            }
        }
    }
    
    enum DataChangeType {
        case itemAdded
        case itemUpdated
        case itemDeleted
        case receiptAdded
        case receiptUpdated
        case warrantyAdded
        case warrantyUpdated
    }
}