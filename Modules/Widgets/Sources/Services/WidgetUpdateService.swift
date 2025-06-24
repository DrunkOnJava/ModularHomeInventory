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