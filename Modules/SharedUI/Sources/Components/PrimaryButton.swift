import SwiftUI

/// Primary button component with consistent styling
public struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    let isLoading: Bool
    let isEnabled: Bool
    
    public init(
        title: String,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.8)
                }
                Text(title)
                    .textStyle(.bodyLarge)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .foregroundColor(.white)
            .background(isEnabled ? AppColors.primary : Color.gray)
            .cornerRadius(AppCornerRadius.medium)
        }
        .disabled(!isEnabled || isLoading)
    }
}