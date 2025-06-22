import SwiftUI
import SharedUI

/// Privacy Policy view - Coming Soon
/// Swift 5.9 - No Swift 6 features
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.xl) {
                Spacer()
                
                // Icon
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(AppColors.primary.opacity(0.6))
                    .appPadding()
                
                // Title
                Text("Privacy Policy")
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
                Text("Our privacy policy will be available here soon. We take your privacy seriously and are committed to protecting your data.")
                    .textStyle(.bodyMedium)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .appPadding(.horizontal)
                
                Spacer()
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(AppColors.background)
            .navigationTitle("Privacy Policy")
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