import SwiftUI
import SharedUI

/// Clear Cache confirmation view - Coming Soon
/// Swift 5.9 - No Swift 6 features
struct ClearCacheView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.xl) {
                Spacer()
                
                // Icon
                Image(systemName: "trash.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.red.opacity(0.6))
                    .appPadding()
                
                // Title
                Text("Clear Cache")
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
                Text("Clear cache functionality will remove temporary files and free up storage space on your device.")
                    .textStyle(.bodyMedium)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .appPadding(.horizontal)
                
                Spacer()
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(AppColors.background)
            .navigationTitle("Clear Cache")
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