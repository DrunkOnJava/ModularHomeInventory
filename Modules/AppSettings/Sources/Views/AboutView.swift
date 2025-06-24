import SwiftUI
import SharedUI

// MARK: - About View

public struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.xl) {
                // App Icon
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(AppColors.primary)
                    .appPadding()
                
                // App Name and Version
                VStack(spacing: AppSpacing.sm) {
                    Text("Home Inventory")
                        .textStyle(.displayMedium)
                    
                    Text("Version 1.0.0")
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                // Description
                Text("Keep track of your belongings with ease")
                    .textStyle(.bodyLarge)
                    .multilineTextAlignment(.center)
                    .appPadding(.horizontal)
                
                Spacer()
                
                // Credits
                VStack(spacing: AppSpacing.xs) {
                    Text("Made with ❤️ using Swift")
                        .textStyle(.bodySmall)
                        .foregroundStyle(AppColors.textSecondary)
                    
                    Text("© 2024 Home Inventory")
                        .textStyle(.labelSmall)
                        .foregroundStyle(AppColors.textTertiary)
                }
                .appPadding()
            }
            .frame(maxWidth: .infinity)
            .background(AppColors.background)
            .navigationTitle("About")
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