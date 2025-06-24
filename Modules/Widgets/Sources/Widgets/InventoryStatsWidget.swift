import WidgetKit
import SwiftUI
import Core

/// Widget showing inventory statistics
/// Swift 5.9 - No Swift 6 features
public struct InventoryStatsWidget: Widget {
    public let kind: String = "InventoryStatsWidget"
    
    public init() {}
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: InventoryStatsProvider()
        ) { entry in
            InventoryStatsWidgetView(entry: entry)
        }
        .configurationDisplayName("Inventory Stats")
        .description("View your inventory statistics at a glance")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

/// Timeline entry for inventory stats
public struct InventoryStatsEntry: TimelineEntry {
    public let date: Date
    public let totalItems: Int
    public let totalValue: Decimal
    public let favoriteItems: Int
    public let recentlyAdded: Int
    public let categories: [(name: String, count: Int)]
    
    public init(
        date: Date,
        totalItems: Int,
        totalValue: Decimal,
        favoriteItems: Int,
        recentlyAdded: Int,
        categories: [(name: String, count: Int)]
    ) {
        self.date = date
        self.totalItems = totalItems
        self.totalValue = totalValue
        self.favoriteItems = favoriteItems
        self.recentlyAdded = recentlyAdded
        self.categories = categories
    }
}

/// Timeline provider for inventory stats
public struct InventoryStatsProvider: TimelineProvider {
    public typealias Entry = InventoryStatsEntry
    
    public init() {}
    
    public func placeholder(in context: Context) -> InventoryStatsEntry {
        InventoryStatsEntry(
            date: Date(),
            totalItems: 100,
            totalValue: 5000,
            favoriteItems: 10,
            recentlyAdded: 5,
            categories: [
                ("Electronics", 30),
                ("Furniture", 25),
                ("Books", 20)
            ]
        )
    }
    
    public func getSnapshot(in context: Context, completion: @escaping (InventoryStatsEntry) -> Void) {
        let entry = placeholder(in: context)
        completion(entry)
    }
    
    public func getTimeline(in context: Context, completion: @escaping (Timeline<InventoryStatsEntry>) -> Void) {
        Task {
            // In a real app, fetch data from repository
            let entry = placeholder(in: context)
            
            // Update every hour
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            
            completion(timeline)
        }
    }
}