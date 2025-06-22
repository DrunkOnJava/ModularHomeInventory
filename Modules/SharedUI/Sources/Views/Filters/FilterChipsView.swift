import SwiftUI
import Core

/// View to display active filter chips
/// Swift 5.9 - No Swift 6 features
public struct FilterChipsView: View {
    let filters: ItemFilters
    let onRemove: (FilterType) -> Void
    let onShowFilters: () -> Void
    
    public enum FilterType {
        case search
        case category(ItemCategory)
        case priceRange
        case dateRange
        case location(UUID)
        case tag(UUID)
        case hasPhotos
        case hasReceipt
        case hasWarranty
        case isFavorite
    }
    
    public init(
        filters: ItemFilters,
        onRemove: @escaping (FilterType) -> Void,
        onShowFilters: @escaping () -> Void
    ) {
        self.filters = filters
        self.onRemove = onRemove
        self.onShowFilters = onShowFilters
    }
    
    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                // Filter button
                Button(action: onShowFilters) {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text("Filters")
                        if filters.activeCount > 0 {
                            Text("(\(filters.activeCount))")
                                .fontWeight(.semibold)
                        }
                    }
                    .textStyle(.labelMedium)
                    .foregroundStyle(filters.isEmpty ? AppColors.textPrimary : AppColors.primary)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(filters.isEmpty ? AppColors.surface : AppColors.primary.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(filters.isEmpty ? AppColors.border : AppColors.primary, lineWidth: 1)
                            )
                    )
                }
                
                if !filters.isEmpty {
                    Divider()
                        .frame(height: 20)
                    
                    // Active filter chips
                    activeFilterChips
                }
            }
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private var activeFilterChips: some View {
        Group {
            // Search
            if let searchText = filters.searchText {
                FilterChip(
                    label: "Search: \(searchText)",
                    icon: "magnifyingglass",
                    onRemove: { onRemove(.search) }
                )
            }
            
            // Categories
            if let categories = filters.categories {
                ForEach(categories, id: \.self) { category in
                    FilterChip(
                        label: category.displayName,
                        icon: category.icon,
                        onRemove: { onRemove(.category(category)) }
                    )
                }
            }
            
            // Price Range
            if filters.minPrice != nil || filters.maxPrice != nil {
                let label = formatPriceRange(min: filters.minPrice, max: filters.maxPrice)
                FilterChip(
                    label: label,
                    icon: "dollarsign.circle",
                    onRemove: { onRemove(.priceRange) }
                )
            }
            
            // Date Range
            if filters.startDate != nil || filters.endDate != nil {
                let label = formatDateRange(start: filters.startDate, end: filters.endDate)
                FilterChip(
                    label: label,
                    icon: "calendar",
                    onRemove: { onRemove(.dateRange) }
                )
            }
            
            // Additional filters
            if filters.hasPhotos == true {
                FilterChip(
                    label: "Has Photos",
                    icon: "photo",
                    onRemove: { onRemove(.hasPhotos) }
                )
            }
            
            if filters.hasReceipt == true {
                FilterChip(
                    label: "Has Receipt",
                    icon: "doc.text",
                    onRemove: { onRemove(.hasReceipt) }
                )
            }
            
            if filters.hasWarranty == true {
                FilterChip(
                    label: "Has Warranty",
                    icon: "shield",
                    onRemove: { onRemove(.hasWarranty) }
                )
            }
            
            if filters.isFavorite == true {
                FilterChip(
                    label: "Favorites",
                    icon: "star.fill",
                    iconColor: .yellow,
                    onRemove: { onRemove(.isFavorite) }
                )
            }
        }
    }
    
    private func formatPriceRange(min: Decimal?, max: Decimal?) -> String {
        if let min = min, let max = max {
            return "$\(Int(truncating: min as NSNumber))-$\(Int(truncating: max as NSNumber))"
        } else if let min = min {
            return "Over $\(Int(truncating: min as NSNumber))"
        } else if let max = max {
            return "Under $\(Int(truncating: max as NSNumber))"
        } else {
            return "Price"
        }
    }
    
    private func formatDateRange(start: Date?, end: Date?) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        
        if let start = start, let end = end {
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        } else if let start = start {
            return "After \(formatter.string(from: start))"
        } else if let end = end {
            return "Before \(formatter.string(from: end))"
        } else {
            return "Date"
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    let icon: String
    var iconColor: Color = AppColors.textSecondary
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(iconColor)
            
            Text(label)
                .textStyle(.labelSmall)
                .foregroundStyle(AppColors.textPrimary)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.border, lineWidth: 1)
                )
        )
    }
}