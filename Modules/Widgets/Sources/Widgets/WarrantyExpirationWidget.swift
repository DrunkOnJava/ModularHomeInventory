import WidgetKit
import SwiftUI
import Core

/// Widget showing warranty expirations
/// Swift 5.9 - No Swift 6 features
public struct WarrantyExpirationWidget: Widget {
    public let kind: String = "WarrantyExpirationWidget"
    
    public init() {}
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: WarrantyExpirationProvider()
        ) { entry in
            WarrantyExpirationWidgetView(entry: entry)
        }
        .configurationDisplayName("Warranty Tracker")
        .description("Keep track of expiring warranties")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

/// Timeline entry for warranty expiration
public struct WarrantyExpirationEntry: TimelineEntry {
    public let date: Date
    public let expiringWarranties: [ExpiringWarranty]
    public let expiredCount: Int
    public let activeCount: Int
    
    public struct ExpiringWarranty: Identifiable {
        public let id = UUID()
        public let itemName: String
        public let provider: String
        public let expirationDate: Date
        public let daysRemaining: Int
        public let status: Warranty.Status
        
        public init(
            itemName: String,
            provider: String,
            expirationDate: Date,
            daysRemaining: Int,
            status: Warranty.Status
        ) {
            self.itemName = itemName
            self.provider = provider
            self.expirationDate = expirationDate
            self.daysRemaining = daysRemaining
            self.status = status
        }
    }
    
    public init(
        date: Date,
        expiringWarranties: [ExpiringWarranty],
        expiredCount: Int,
        activeCount: Int
    ) {
        self.date = date
        self.expiringWarranties = expiringWarranties
        self.expiredCount = expiredCount
        self.activeCount = activeCount
    }
}

/// Timeline provider for warranty expiration
public struct WarrantyExpirationProvider: TimelineProvider {
    public typealias Entry = WarrantyExpirationEntry
    
    public init() {}
    
    public func placeholder(in context: Context) -> WarrantyExpirationEntry {
        WarrantyExpirationEntry(
            date: Date(),
            expiringWarranties: [
                .init(
                    itemName: "MacBook Pro",
                    provider: "Apple",
                    expirationDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
                    daysRemaining: 30,
                    status: .expiringSoon
                ),
                .init(
                    itemName: "Coffee Maker",
                    provider: "Breville",
                    expirationDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
                    daysRemaining: 7,
                    status: .expiringSoon
                )
            ],
            expiredCount: 2,
            activeCount: 15
        )
    }
    
    public func getSnapshot(in context: Context, completion: @escaping (WarrantyExpirationEntry) -> Void) {
        let entry = placeholder(in: context)
        completion(entry)
    }
    
    public func getTimeline(in context: Context, completion: @escaping (Timeline<WarrantyExpirationEntry>) -> Void) {
        Task {
            // In a real app, fetch data from repository
            let entry = placeholder(in: context)
            
            // Update daily at midnight
            let calendar = Calendar.current
            let tomorrow = calendar.startOfDay(for: Date()).addingTimeInterval(24 * 60 * 60)
            let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
            
            completion(timeline)
        }
    }
}