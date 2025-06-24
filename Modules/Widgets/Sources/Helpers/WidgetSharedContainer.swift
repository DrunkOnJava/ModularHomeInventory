import Foundation
import WidgetKit

/// Helper for sharing data between app and widgets
/// Swift 5.9 - No Swift 6 features
public final class WidgetSharedContainer {
    /// App group identifier for sharing data
    public static let appGroupIdentifier = "group.com.homeinventory.widgets"
    
    /// Shared user defaults
    public static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
    
    /// Shared container URL
    public static var sharedContainerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
    }
    
    // MARK: - Data Keys
    
    private enum DataKey: String {
        case inventoryStats = "widget.inventoryStats"
        case spendingSummary = "widget.spendingSummary"
        case warrantyExpirations = "widget.warrantyExpirations"
        case recentItems = "widget.recentItems"
        case lastUpdate = "widget.lastUpdate"
    }
    
    // MARK: - Save Data
    
    public static func saveInventoryStats(_ stats: InventoryStatsEntry) {
        guard let defaults = sharedDefaults else { return }
        
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(stats) {
            defaults.set(data, forKey: DataKey.inventoryStats.rawValue)
            defaults.set(Date(), forKey: DataKey.lastUpdate.rawValue)
            
            // Reload widgets
            WidgetCenter.shared.reloadTimelines(ofKind: "InventoryStatsWidget")
        }
    }
    
    public static func saveSpendingSummary(_ summary: SpendingSummaryEntry) {
        guard let defaults = sharedDefaults else { return }
        
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(summary) {
            defaults.set(data, forKey: DataKey.spendingSummary.rawValue)
            defaults.set(Date(), forKey: DataKey.lastUpdate.rawValue)
            
            // Reload widgets
            WidgetCenter.shared.reloadTimelines(ofKind: "SpendingSummaryWidget")
        }
    }
    
    public static func saveWarrantyExpirations(_ expirations: WarrantyExpirationEntry) {
        guard let defaults = sharedDefaults else { return }
        
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(expirations) {
            defaults.set(data, forKey: DataKey.warrantyExpirations.rawValue)
            defaults.set(Date(), forKey: DataKey.lastUpdate.rawValue)
            
            // Reload widgets
            WidgetCenter.shared.reloadTimelines(ofKind: "WarrantyExpirationWidget")
        }
    }
    
    public static func saveRecentItems(_ items: RecentItemsEntry) {
        guard let defaults = sharedDefaults else { return }
        
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(items) {
            defaults.set(data, forKey: DataKey.recentItems.rawValue)
            defaults.set(Date(), forKey: DataKey.lastUpdate.rawValue)
            
            // Reload widgets
            WidgetCenter.shared.reloadTimelines(ofKind: "RecentItemsWidget")
        }
    }
    
    // MARK: - Load Data
    
    public static func loadInventoryStats() -> InventoryStatsEntry? {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: DataKey.inventoryStats.rawValue) else { return nil }
        
        let decoder = JSONDecoder()
        return try? decoder.decode(InventoryStatsEntry.self, from: data)
    }
    
    public static func loadSpendingSummary() -> SpendingSummaryEntry? {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: DataKey.spendingSummary.rawValue) else { return nil }
        
        let decoder = JSONDecoder()
        return try? decoder.decode(SpendingSummaryEntry.self, from: data)
    }
    
    public static func loadWarrantyExpirations() -> WarrantyExpirationEntry? {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: DataKey.warrantyExpirations.rawValue) else { return nil }
        
        let decoder = JSONDecoder()
        return try? decoder.decode(WarrantyExpirationEntry.self, from: data)
    }
    
    public static func loadRecentItems() -> RecentItemsEntry? {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: DataKey.recentItems.rawValue) else { return nil }
        
        let decoder = JSONDecoder()
        return try? decoder.decode(RecentItemsEntry.self, from: data)
    }
    
    public static func lastUpdateTime() -> Date? {
        sharedDefaults?.object(forKey: DataKey.lastUpdate.rawValue) as? Date
    }
    
    // MARK: - Update All Widgets
    
    public static func updateAllWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - Codable Conformance

extension InventoryStatsEntry: Codable {
    enum CodingKeys: String, CodingKey {
        case date, totalItems, totalValue, favoriteItems, recentlyAdded, categories
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decode(Date.self, forKey: .date)
        totalItems = try container.decode(Int.self, forKey: .totalItems)
        totalValue = try container.decode(Decimal.self, forKey: .totalValue)
        favoriteItems = try container.decode(Int.self, forKey: .favoriteItems)
        recentlyAdded = try container.decode(Int.self, forKey: .recentlyAdded)
        
        let categoryData = try container.decode([[String: String]].self, forKey: .categories)
        categories = categoryData.compactMap { dict in
            guard let name = dict["name"],
                  let countStr = dict["count"],
                  let count = Int(countStr) else { return nil }
            return (name: name, count: count)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(date, forKey: .date)
        try container.encode(totalItems, forKey: .totalItems)
        try container.encode(totalValue, forKey: .totalValue)
        try container.encode(favoriteItems, forKey: .favoriteItems)
        try container.encode(recentlyAdded, forKey: .recentlyAdded)
        
        let categoryData = categories.map { ["name": $0.name, "count": String($0.count)] }
        try container.encode(categoryData, forKey: .categories)
    }
}

extension SpendingSummaryEntry: Codable {}
extension SpendingSummaryEntry.SpendingTrend: Codable {}
extension WarrantyExpirationEntry: Codable {}
extension WarrantyExpirationEntry.ExpiringWarranty: Codable {}
extension RecentItemsEntry: Codable {}
extension RecentItemsEntry.RecentItem: Codable {}