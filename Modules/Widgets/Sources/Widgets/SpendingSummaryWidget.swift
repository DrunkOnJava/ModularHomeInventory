import WidgetKit
import SwiftUI
import Core

/// Widget showing spending summary
/// Swift 5.9 - No Swift 6 features
public struct SpendingSummaryWidget: Widget {
    public let kind: String = "SpendingSummaryWidget"
    
    public init() {}
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: SpendingSummaryProvider()
        ) { entry in
            SpendingSummaryWidgetView(entry: entry)
        }
        .configurationDisplayName("Spending Summary")
        .description("Track your spending at a glance")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

/// Timeline entry for spending summary
public struct SpendingSummaryEntry: TimelineEntry {
    public let date: Date
    public let monthlySpending: Decimal
    public let weeklySpending: Decimal
    public let topCategory: (name: String, amount: Decimal)?
    public let recentPurchases: [(name: String, price: Decimal, date: Date)]
    public let spendingTrend: SpendingTrend
    
    public enum SpendingTrend {
        case up(percentage: Double)
        case down(percentage: Double)
        case stable
    }
    
    public init(
        date: Date,
        monthlySpending: Decimal,
        weeklySpending: Decimal,
        topCategory: (name: String, amount: Decimal)?,
        recentPurchases: [(name: String, price: Decimal, date: Date)],
        spendingTrend: SpendingTrend
    ) {
        self.date = date
        self.monthlySpending = monthlySpending
        self.weeklySpending = weeklySpending
        self.topCategory = topCategory
        self.recentPurchases = recentPurchases
        self.spendingTrend = spendingTrend
    }
}

/// Timeline provider for spending summary
public struct SpendingSummaryProvider: TimelineProvider {
    public typealias Entry = SpendingSummaryEntry
    
    public init() {}
    
    public func placeholder(in context: Context) -> SpendingSummaryEntry {
        SpendingSummaryEntry(
            date: Date(),
            monthlySpending: 1500,
            weeklySpending: 350,
            topCategory: ("Electronics", 500),
            recentPurchases: [
                ("iPhone Case", 29.99, Date()),
                ("Coffee Maker", 89.99, Date().addingTimeInterval(-86400))
            ],
            spendingTrend: .up(percentage: 12.5)
        )
    }
    
    public func getSnapshot(in context: Context, completion: @escaping (SpendingSummaryEntry) -> Void) {
        let entry = placeholder(in: context)
        completion(entry)
    }
    
    public func getTimeline(in context: Context, completion: @escaping (Timeline<SpendingSummaryEntry>) -> Void) {
        Task {
            // In a real app, fetch data from repository
            let entry = placeholder(in: context)
            
            // Update every 4 hours
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 4, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            
            completion(timeline)
        }
    }
}