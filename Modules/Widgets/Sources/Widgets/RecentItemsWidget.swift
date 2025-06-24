import WidgetKit
import SwiftUI
import Core

/// Widget showing recently added items
/// Swift 5.9 - No Swift 6 features
public struct RecentItemsWidget: Widget {
    public let kind: String = "RecentItemsWidget"
    
    public init() {}
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: RecentItemsProvider()
        ) { entry in
            RecentItemsWidgetView(entry: entry)
        }
        .configurationDisplayName("Recent Items")
        .description("View your recently added items")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

/// Timeline entry for recent items
public struct RecentItemsEntry: TimelineEntry {
    public let date: Date
    public let items: [RecentItem]
    public let totalAddedToday: Int
    public let totalAddedThisWeek: Int
    
    public struct RecentItem: Identifiable {
        public let id = UUID()
        public let name: String
        public let category: ItemCategory
        public let price: Decimal?
        public let imageData: Data?
        public let addedDate: Date
        public let location: String?
        
        public init(
            name: String,
            category: ItemCategory,
            price: Decimal?,
            imageData: Data?,
            addedDate: Date,
            location: String?
        ) {
            self.name = name
            self.category = category
            self.price = price
            self.imageData = imageData
            self.addedDate = addedDate
            self.location = location
        }
    }
    
    public init(
        date: Date,
        items: [RecentItem],
        totalAddedToday: Int,
        totalAddedThisWeek: Int
    ) {
        self.date = date
        self.items = items
        self.totalAddedToday = totalAddedToday
        self.totalAddedThisWeek = totalAddedThisWeek
    }
}

/// Timeline provider for recent items
public struct RecentItemsProvider: TimelineProvider {
    public typealias Entry = RecentItemsEntry
    
    public init() {}
    
    public func placeholder(in context: Context) -> RecentItemsEntry {
        RecentItemsEntry(
            date: Date(),
            items: [
                .init(
                    name: "AirPods Pro",
                    category: .electronics,
                    price: 249.99,
                    imageData: nil,
                    addedDate: Date(),
                    location: "Office"
                ),
                .init(
                    name: "Standing Desk",
                    category: .furniture,
                    price: 599.99,
                    imageData: nil,
                    addedDate: Date().addingTimeInterval(-3600),
                    location: "Home Office"
                ),
                .init(
                    name: "Coffee Machine",
                    category: .appliances,
                    price: 199.99,
                    imageData: nil,
                    addedDate: Date().addingTimeInterval(-7200),
                    location: "Kitchen"
                )
            ],
            totalAddedToday: 3,
            totalAddedThisWeek: 12
        )
    }
    
    public func getSnapshot(in context: Context, completion: @escaping (RecentItemsEntry) -> Void) {
        let entry = placeholder(in: context)
        completion(entry)
    }
    
    public func getTimeline(in context: Context, completion: @escaping (Timeline<RecentItemsEntry>) -> Void) {
        Task {
            // In a real app, fetch data from repository
            let entry = placeholder(in: context)
            
            // Update every 2 hours
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 2, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            
            completion(timeline)
        }
    }
}