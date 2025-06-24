import SwiftUI
import WidgetKit
import Core
import SharedUI

/// View for recent items widget
/// Swift 5.9 - No Swift 6 features
public struct RecentItemsWidgetView: View {
    public let entry: RecentItemsEntry
    @Environment(\.widgetFamily) var family
    
    public init(entry: RecentItemsEntry) {
        self.entry = entry
    }
    
    public var body: some View {
        switch family {
        case .systemMedium:
            mediumView
        case .systemLarge:
            largeView
        default:
            mediumView
        }
    }
    
    // MARK: - Medium Widget
    
    private var mediumView: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundStyle(.purple)
                    Text("Recent Items")
                        .font(.headline)
                }
                Spacer()
                
                // Stats
                HStack(spacing: 8) {
                    if entry.totalAddedToday > 0 {
                        Text("\(entry.totalAddedToday) today")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text("\(entry.totalAddedThisWeek) this week")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Items
            if !entry.items.isEmpty {
                HStack(spacing: 12) {
                    ForEach(entry.items.prefix(3)) { item in
                        RecentItemCard(item: item)
                    }
                }
            } else {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.title)
                        .foregroundStyle(.secondary)
                    Text("No recent items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
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
                    Image(systemName: "sparkles")
                        .font(.largeTitle)
                        .foregroundStyle(.purple)
                    VStack(alignment: .leading) {
                        Text("Recent Items")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Added to your inventory")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                
                // Stats
                VStack(alignment: .trailing, spacing: 2) {
                    if entry.totalAddedToday > 0 {
                        HStack(spacing: 4) {
                            Text("\(entry.totalAddedToday)")
                                .fontWeight(.semibold)
                            Text("today")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 4) {
                        Text("\(entry.totalAddedThisWeek)")
                            .fontWeight(.semibold)
                        Text("this week")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            
            // Items grid
            if !entry.items.isEmpty {
                VStack(spacing: 12) {
                    ForEach(entry.items.prefix(6)) { item in
                        RecentItemRow(item: item)
                    }
                }
            } else {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No recent items")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Items you add will appear here")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            }
            
            Spacer()
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

// MARK: - Supporting Views

private struct RecentItemCard: View {
    let item: RecentItemsEntry.RecentItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Category icon
            HStack {
                Image(systemName: item.category.icon)
                    .font(.caption)
                    .foregroundStyle(Color(hex: item.category.color))
                Spacer()
            }
            
            Spacer()
            
            // Item details
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if let price = item.price {
                    Text(price.formatted(.currency(code: "USD")))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Text(item.addedDate, style: .relative)
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

private struct RecentItemRow: View {
    let item: RecentItemsEntry.RecentItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: item.category.color).opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: item.category.icon)
                    .font(.body)
                    .foregroundStyle(Color(hex: item.category.color))
            }
            
            // Item details
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    if let location = item.location {
                        HStack(spacing: 2) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 10))
                            Text(location)
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)
                    }
                    
                    Text(item.addedDate, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
            
            // Price
            if let price = item.price {
                Text(price.formatted(.currency(code: "USD")))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// Helper extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}