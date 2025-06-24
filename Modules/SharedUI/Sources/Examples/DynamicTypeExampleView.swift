import SwiftUI

/// Example view demonstrating proper Dynamic Type implementation
public struct DynamicTypeExampleView: View {
    @Environment(\.sizeCategory) private var sizeCategory
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                // Title Section
                Text("Dynamic Type Example")
                    .dynamicTextStyle(.displayLarge)
                    .accessibleLineSpacing()
                
                // Description
                Text("This view demonstrates how to properly implement Dynamic Type in your views. All text scales according to the user's preferred text size.")
                    .dynamicTextStyle(.bodyMedium)
                    .accessibleLineSpacing()
                    .foregroundStyle(AppColors.textSecondary)
                
                // Adaptive Layout Example
                adaptiveLayoutExample
                
                // Text Styles Demo
                textStylesDemo
                
                // Best Practices
                bestPracticesSection
            }
            .appPadding()
        }
        .navigationTitle("Dynamic Type")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Sections
    
    private var adaptiveLayoutExample: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Adaptive Layout")
                .dynamicTextStyle(.headlineMedium)
            
            Text("This layout changes from horizontal to vertical when using accessibility text sizes:")
                .dynamicTextStyle(.bodySmall)
                .foregroundStyle(AppColors.textSecondary)
            
            // This will be horizontal for regular sizes, vertical for accessibility sizes
            Group {
                if sizeCategory.isAccessibilityCategory {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        itemRow(icon: "photo", title: "Photos", count: "142")
                        itemRow(icon: "doc", title: "Documents", count: "28")
                        itemRow(icon: "location", title: "Locations", count: "5")
                    }
                } else {
                    HStack(spacing: AppSpacing.md) {
                        itemRow(icon: "photo", title: "Photos", count: "142")
                        itemRow(icon: "doc", title: "Documents", count: "28")
                        itemRow(icon: "location", title: "Locations", count: "5")
                    }
                }
            }
            .appPadding()
            .background(AppColors.secondaryBackground)
            .appCornerRadius(.medium)
        }
    }
    
    private func itemRow(icon: String, title: String, count: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AppColors.primary)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .dynamicTextStyle(.bodyMedium)
                Text(count)
                    .dynamicTextStyle(.labelSmall)
                    .foregroundStyle(AppColors.textSecondary)
            }
            
            if !sizeCategory.isAccessibilityCategory {
                Spacer()
            }
        }
    }
    
    private var textStylesDemo: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Text Styles")
                .dynamicTextStyle(.headlineMedium)
            
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                styleExample("Display Large", style: .displayLarge)
                styleExample("Display Medium", style: .displayMedium)
                styleExample("Display Small", style: .displaySmall)
                styleExample("Headline Large", style: .headlineLarge)
                styleExample("Headline Medium", style: .headlineMedium)
                styleExample("Headline Small", style: .headlineSmall)
                styleExample("Body Large", style: .bodyLarge)
                styleExample("Body Medium", style: .bodyMedium)
                styleExample("Body Small", style: .bodySmall)
                styleExample("Label Large", style: .labelLarge)
                styleExample("Label Medium", style: .labelMedium)
                styleExample("Label Small", style: .labelSmall)
            }
            .appPadding()
            .background(AppColors.secondaryBackground)
            .appCornerRadius(.medium)
        }
    }
    
    private func styleExample(_ name: String, style: DynamicTextStyle.Style) -> some View {
        HStack {
            Text(name)
                .dynamicTextStyle(style)
            Spacer()
            Text("Aa")
                .dynamicTextStyle(style)
                .foregroundStyle(AppColors.textSecondary)
        }
    }
    
    private var bestPracticesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Best Practices")
                .dynamicTextStyle(.headlineMedium)
            
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                bestPracticeItem(
                    "Use Dynamic Type",
                    "Always use dynamicTextStyle() instead of fixed font sizes"
                )
                
                bestPracticeItem(
                    "Test All Sizes",
                    "Test your UI with all text sizes, especially accessibility sizes"
                )
                
                bestPracticeItem(
                    "Adaptive Layouts",
                    "Use different layouts for accessibility text sizes when needed"
                )
                
                bestPracticeItem(
                    "Line Spacing",
                    "Use accessibleLineSpacing() for better readability with large text"
                )
                
                bestPracticeItem(
                    "Truncation",
                    "Avoid text truncation, especially with accessibility sizes"
                )
            }
            .appPadding()
            .background(AppColors.secondaryBackground)
            .appCornerRadius(.medium)
        }
    }
    
    private func bestPracticeItem(_ title: String, _ description: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Label(title, systemImage: "checkmark.circle.fill")
                .dynamicTextStyle(.bodyMedium)
                .foregroundStyle(AppColors.success)
            
            Text(description)
                .dynamicTextStyle(.bodySmall)
                .foregroundStyle(AppColors.textSecondary)
                .padding(.leading, 28)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct DynamicTypeExampleView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                DynamicTypeExampleView()
            }
            .environment(\.sizeCategory, .medium)
            .previewDisplayName("Medium")
            
            NavigationView {
                DynamicTypeExampleView()
            }
            .environment(\.sizeCategory, .extraExtraExtraLarge)
            .previewDisplayName("XXXL")
            
            NavigationView {
                DynamicTypeExampleView()
            }
            .environment(\.sizeCategory, .accessibilityExtraLarge)
            .previewDisplayName("Accessibility XL")
        }
    }
}
#endif