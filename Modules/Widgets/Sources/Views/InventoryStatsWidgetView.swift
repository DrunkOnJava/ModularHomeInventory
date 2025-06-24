import SwiftUI
import WidgetKit
import Core
import SharedUI

/// View for inventory stats widget
/// Swift 5.9 - No Swift 6 features
public struct InventoryStatsWidgetView: View {
    public let entry: InventoryStatsEntry
    @Environment(\.widgetFamily) var family
    
    public init(entry: InventoryStatsEntry) {
        self.entry = entry
    }
    
    public var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }
    
    // MARK: - Small Widget
    
    private var smallView: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Image(systemName: "shippingbox.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Spacer()
            }
            
            Spacer()
            
            // Stats
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(entry.totalItems)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    Spacer()
                }
                
                Text("Total Items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                    Text("\(entry.favoriteItems)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
                    Image(systemName: "shippingbox.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    Text("Inventory")
                        .font(.headline)
                }
                Spacer()
                Text("Updated \(entry.date, style: .time)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            // Stats Grid
            HStack(spacing: 16) {
                // Total Items
                StatCard(
                    title: "Items",
                    value: "\(entry.totalItems)",
                    icon: "shippingbox",
                    color: .blue
                )
                
                // Total Value
                StatCard(
                    title: "Value",
                    value: entry.totalValue.formatted(.currency(code: "USD")),
                    icon: "dollarsign.circle",
                    color: .green
                )
                
                // Favorites
                StatCard(
                    title: "Favorites",
                    value: "\(entry.favoriteItems)",
                    icon: "star",
                    color: .yellow
                )
                
                // Recent
                StatCard(
                    title: "New",
                    value: "\(entry.recentlyAdded)",
                    icon: "sparkles",
                    color: .purple
                )
            }
            
            // Top Categories
            if !entry.categories.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Top Categories")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 8) {
                        ForEach(entry.categories.prefix(3), id: \.name) { category in
                            CategoryBadge(name: category.name, count: category.count)
                        }
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

// MARK: - Supporting Views

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Text(value)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CategoryBadge: View {
    let name: String
    let count: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Text(name)
                .font(.caption2)
            Text("\(count)")
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray5))
        .clipShape(Capsule())
    }
}