import SwiftUI
import SharedUI

/// Share App view - Coming Soon
/// Swift 5.9 - No Swift 6 features
struct ShareAppView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.xl) {
                Spacer()
                
                // Icon
                Image(systemName: "square.and.arrow.up.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(AppColors.primary.opacity(0.6))
                    .appPadding()
                
                // Title
                Text("Share App")
                    .textStyle(.displaySmall)
                    .foregroundStyle(AppColors.textPrimary)
                
                // Coming Soon Badge
                Text("COMING SOON")
                    .textStyle(.labelMedium)
                    .foregroundStyle(AppColors.primary)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: AppCornerRadius.small)
                            .fill(AppColors.primary.opacity(0.1))
                    )
                
                // Description
                Text("Share functionality will allow you to recommend Home Inventory to friends and family via messages, email, and social media.")
                    .textStyle(.bodyMedium)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .appPadding(.horizontal)
                
                Spacer()
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(AppColors.background)
            .navigationTitle("Share App")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}