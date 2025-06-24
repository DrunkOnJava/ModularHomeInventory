import SwiftUI
import WidgetKit
import Core
import SharedUI

/// View for spending summary widget
/// Swift 5.9 - No Swift 6 features
public struct SpendingSummaryWidgetView: View {
    public let entry: SpendingSummaryEntry
    @Environment(\.widgetFamily) var family
    
    public init(entry: SpendingSummaryEntry) {
        self.entry = entry
    }
    
    public var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        case .systemLarge:
            largeView
        default:
            smallView
        }
    }
    
    // MARK: - Small Widget
    
    private var smallView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title3)
                    .foregroundStyle(.green)
                Spacer()
                trendIndicator
            }
            
            Spacer()
            
            // Monthly spending
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.monthlySpending.formatted(.currency(code: "USD")))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                
                Text("This Month")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Top category
            if let topCategory = entry.topCategory {
                HStack(spacing: 4) {
                    Image(systemName: "tag.fill")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                    Text(topCategory.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
    
    // MARK: - Medium Widget
    
    private var mediumView: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title2)
                        .foregroundStyle(.green)
                    Text("Spending")
                        .font(.headline)
                }
                Spacer()
                trendIndicator
            }
            
            // Spending stats
            HStack(spacing: 20) {
                // Monthly
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.monthlySpending.formatted(.currency(code: "USD")))
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                    Text("This Month")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Weekly
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.weeklySpending.formatted(.currency(code: "USD")))
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.semibold)
                    Text("This Week")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            // Recent purchases
            if !entry.recentPurchases.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recent")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    ForEach(entry.recentPurchases.prefix(2), id: \.name) { purchase in
                        HStack {
                            Text(purchase.name)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                            Text(purchase.price.formatted(.currency(code: "USD")))
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
    
    // MARK: - Large Widget
    
    private var largeView: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.largeTitle)
                        .foregroundStyle(.green)
                    VStack(alignment: .leading) {
                        Text("Spending Summary")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Updated \(entry.date, style: .time)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            
            // Main stats
            HStack(alignment: .top, spacing: 24) {
                // Monthly spending
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.monthlySpending.formatted(.currency(code: "USD")))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                        Text("This Month")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Trend
                    HStack(spacing: 4) {
                        trendIndicator
                        switch entry.spendingTrend {
                        case .up(let percentage):
                            Text("+\(Int(percentage))%")
                                .font(.caption)
                                .foregroundStyle(.red)
                        case .down(let percentage):
                            Text("-\(Int(percentage))%")
                                .font(.caption)
                                .foregroundStyle(.green)
                        case .stable:
                            Text("No change")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Weekly spending
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.weeklySpending.formatted(.currency(code: "USD")))
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.semibold)
                    Text("This Week")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Top category
            if let topCategory = entry.topCategory {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Top Category")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 8) {
                            Text(topCategory.name)
                                .font(.headline)
                            Text(topCategory.amount.formatted(.currency(code: "USD")))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            
            // Recent purchases
            if !entry.recentPurchases.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Purchases")
                        .font(.headline)
                    
                    VStack(spacing: 6) {
                        ForEach(entry.recentPurchases.prefix(4), id: \.name) { purchase in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(purchase.name)
                                        .font(.subheadline)
                                        .lineLimit(1)
                                    Text(purchase.date, style: .relative)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(purchase.price.formatted(.currency(code: "USD")))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
    
    // MARK: - Helpers
    
    private var trendIndicator: some View {
        Group {
            switch entry.spendingTrend {
            case .up:
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.red)
            case .down:
                Image(systemName: "arrow.down.right")
                    .font(.caption)
                    .foregroundStyle(.green)
            case .stable:
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}