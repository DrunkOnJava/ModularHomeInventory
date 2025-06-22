import SwiftUI

/// View shown when a feature is not available or fails to load
public struct FeatureUnavailableView: View {
    public let feature: String
    public let reason: String?
    public let icon: String
    
    public init(
        feature: String,
        reason: String? = nil,
        icon: String = "exclamationmark.triangle"
    ) {
        self.feature = feature
        self.reason = reason
        self.icon = icon
    }
    
    public var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(AppColors.textSecondary)
            
            VStack(spacing: AppSpacing.sm) {
                Text("Coming Soon")
                    .textStyle(.headlineLarge)
                    .foregroundStyle(AppColors.textPrimary)
                
                Text("\(feature) is currently unavailable")
                    .textStyle(.bodyMedium)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                
                if let reason = reason {
                    Text(reason)
                        .textStyle(.bodySmall)
                        .foregroundStyle(AppColors.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.top, AppSpacing.xs)
                }
            }
        }
        .appPadding(.all, AppSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}