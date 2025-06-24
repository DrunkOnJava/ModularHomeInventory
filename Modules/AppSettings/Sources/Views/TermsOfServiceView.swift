import SwiftUI
import SharedUI

/// Terms of Service view - Coming Soon
/// Swift 5.9 - No Swift 6 features
struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.xl) {
                Spacer()
                
                // Icon
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(AppColors.primary.opacity(0.6))
                    .appPadding()
                
                // Title
                Text("Terms of Service")
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
                Text("Our terms of service will be available here soon. Please check back later for the complete terms.")
                    .textStyle(.bodyMedium)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .appPadding(.horizontal)
                
                Spacer()
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(AppColors.background)
            .navigationTitle("Terms of Service")
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