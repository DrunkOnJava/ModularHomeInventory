import SwiftUI
import WidgetKit
import Core
import SharedUI

/// View for warranty expiration widget
/// Swift 5.9 - No Swift 6 features
public struct WarrantyExpirationWidgetView: View {
    public let entry: WarrantyExpirationEntry
    @Environment(\.widgetFamily) var family
    
    public init(entry: WarrantyExpirationEntry) {
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
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.title2)
                    .foregroundStyle(.orange)
                Spacer()
                if entry.expiringWarranties.count > 0 {
                    Text("\(entry.expiringWarranties.count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(10)
                }
            }
            
            Spacer()
            
            // Content
            if let firstWarranty = entry.expiringWarranties.first {
                VStack(alignment: .leading, spacing: 4) {
                    Text(firstWarranty.itemName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                            .foregroundStyle(warrantyColor(firstWarranty.status))
                        Text("\(firstWarranty.daysRemaining) days")
                            .font(.caption)
                            .foregroundStyle(warrantyColor(firstWarranty.status))
                    }
                    
                    Text(firstWarranty.provider)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.green)
                    Text("All warranties active")
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
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.title2)
                        .foregroundStyle(.orange)
                    Text("Warranties")
                        .font(.headline)
                }
                Spacer()
                
                // Stats
                HStack(spacing: 12) {
                    StatBadge(
                        value: entry.activeCount,
                        label: "Active",
                        color: .green
                    )
                    if entry.expiringWarranties.count > 0 {
                        StatBadge(
                            value: entry.expiringWarranties.count,
                            label: "Expiring",
                            color: .orange
                        )
                    }
                    if entry.expiredCount > 0 {
                        StatBadge(
                            value: entry.expiredCount,
                            label: "Expired",
                            color: .red
                        )
                    }
                }
            }
            
            // Warranty list
            if !entry.expiringWarranties.isEmpty {
                VStack(spacing: 6) {
                    ForEach(entry.expiringWarranties.prefix(3)) { warranty in
                        WarrantyRow(warranty: warranty)
                    }
                }
            } else {
                Spacer()
                HStack {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.title)
                        .foregroundStyle(.green)
                    VStack(alignment: .leading) {
                        Text("All warranties active")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("No warranties expiring soon")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
    
    // MARK: - Helpers
    
    private func warrantyColor(_ status: Warranty.Status) -> Color {
        switch status {
        case .active:
            return .green
        case .expiringSoon:
            return .orange
        case .expired:
            return .red
        }
    }
}

// MARK: - Supporting Views

private struct StatBadge: View {
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

private struct WarrantyRow: View {
    let warranty: WarrantyExpirationEntry.ExpiringWarranty
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(warranty.itemName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(warranty.provider)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 2) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10))
                    Text("\(warranty.daysRemaining)d")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundStyle(warrantyColor(warranty.status))
                
                Text(warranty.expirationDate, style: .date)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color(.systemGray6))
        .cornerRadius(6)
    }
    
    private func warrantyColor(_ status: Warranty.Status) -> Color {
        switch status {
        case .active:
            return .green
        case .expiringSoon:
            return .orange
        case .expired:
            return .red
        }
    }
}