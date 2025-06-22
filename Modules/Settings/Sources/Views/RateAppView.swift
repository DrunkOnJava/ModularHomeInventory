import SwiftUI
import SharedUI

/// Rate App view - Coming Soon
/// Swift 5.9 - No Swift 6 features
struct RateAppView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.xl) {
                Spacer()
                
                // Icon
                Image(systemName: "star.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(AppColors.primary.opacity(0.6))
                    .appPadding()
                
                // Title
                Text("Rate Home Inventory")
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
                Text("App Store rating functionality will be available once the app is published. We appreciate your feedback!")
                    .textStyle(.bodyMedium)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .appPadding(.horizontal)
                
                Spacer()
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(AppColors.background)
            .navigationTitle("Rate App")
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