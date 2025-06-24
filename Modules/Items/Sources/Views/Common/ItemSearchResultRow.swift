import SwiftUI
import Core
import SharedUI

/// Row view for displaying item search results
/// Swift 5.9 - No Swift 6 features
struct ItemSearchResultRow: View {
    let item: Item
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Category icon
            ZStack {
                RoundedRectangle(cornerRadius: AppCornerRadius.small)
                    .fill(Color(hex: item.category.color).opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Image(systemName: item.category.icon)
                    .font(.title2)
                    .foregroundStyle(Color(hex: item.category.color))
            }
            
            // Item details
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(item.name)
                    .textStyle(.bodyLarge)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: AppSpacing.sm) {
                    if let brand = item.brand {
                        Text(brand)
                            .textStyle(.bodySmall)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    
                    if let model = item.model {
                        Text("•")
                            .foregroundStyle(AppColors.textTertiary)
                        
                        Text(model)
                            .textStyle(.bodySmall)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                
                // Location and value
                HStack(spacing: AppSpacing.sm) {
                    if item.locationId != nil {
                        Label("Location", systemImage: "location")
                            .textStyle(.labelSmall)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                    
                    if let value = item.value {
                        Spacer()
                        Text(value, format: .currency(code: "USD"))
                            .textStyle(.bodyMedium)
                            .foregroundStyle(AppColors.primary)
                    }
                }
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppColors.textTertiary)
        }
        .padding(.vertical, AppSpacing.sm)
    }
}