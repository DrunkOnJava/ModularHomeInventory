import SwiftUI

/// Dynamic Typography system that supports iOS Dynamic Type
/// Uses relative font sizes that scale with user preferences
public struct DynamicTextStyle: ViewModifier {
    public enum Style {
        case displayLarge, displayMedium, displaySmall
        case headlineLarge, headlineMedium, headlineSmall
        case bodyLarge, bodyMedium, bodySmall
        case labelLarge, labelMedium, labelSmall
        
        /// Maps our custom styles to SwiftUI's built-in text styles for Dynamic Type support
        var textStyle: Font.TextStyle {
            switch self {
            case .displayLarge: return .largeTitle
            case .displayMedium: return .title
            case .displaySmall: return .title2
            case .headlineLarge: return .title3
            case .headlineMedium: return .headline
            case .headlineSmall: return .subheadline
            case .bodyLarge: return .body
            case .bodyMedium: return .callout
            case .bodySmall: return .footnote
            case .labelLarge: return .caption
            case .labelMedium: return .caption2
            case .labelSmall: return .caption2
            }
        }
        
        /// Custom weight for each style
        var weight: Font.Weight {
            switch self {
            case .displayLarge: return .bold
            case .displayMedium: return .semibold
            case .displaySmall: return .semibold
            case .headlineLarge: return .semibold
            case .headlineMedium: return .semibold
            case .headlineSmall: return .semibold
            case .bodyLarge: return .regular
            case .bodyMedium: return .regular
            case .bodySmall: return .regular
            case .labelLarge: return .medium
            case .labelMedium: return .medium
            case .labelSmall: return .medium
            }
        }
        
        /// Design system for the font
        var design: Font.Design {
            return .default
        }
    }
    
    let style: Style
    @Environment(\.sizeCategory) private var sizeCategory
    
    public func body(content: Content) -> some View {
        content
            .font(.system(style.textStyle, design: style.design, weight: style.weight))
            .dynamicTypeSize(...DynamicTypeSize.accessibility5) // Cap at largest accessibility size
    }
}

// MARK: - View Extension for Dynamic Type

public extension View {
    /// Apply dynamic text style that responds to user's text size preferences
    func dynamicTextStyle(_ style: DynamicTextStyle.Style) -> some View {
        modifier(DynamicTextStyle(style: style))
    }
}

// MARK: - Text Size Preference

/// User preference for text size scaling
public enum TextSizePreference: String, CaseIterable, Codable {
    case extraSmall = "extra_small"
    case small = "small"
    case medium = "medium"
    case large = "large"
    case extraLarge = "extra_large"
    case extraExtraLarge = "extra_extra_large"
    case extraExtraExtraLarge = "extra_extra_extra_large"
    
    public var displayName: String {
        switch self {
        case .extraSmall: return "Extra Small"
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .extraLarge: return "Extra Large"
        case .extraExtraLarge: return "XXL"
        case .extraExtraExtraLarge: return "XXXL"
        }
    }
    
    /// Maps to iOS content size category
    public var contentSizeCategory: ContentSizeCategory {
        switch self {
        case .extraSmall: return .extraSmall
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        case .extraLarge: return .extraLarge
        case .extraExtraLarge: return .extraExtraLarge
        case .extraExtraExtraLarge: return .extraExtraExtraLarge
        }
    }
}

// MARK: - Dynamic Type Environment

/// Environment key for overriding text size preference
private struct TextSizePreferenceKey: EnvironmentKey {
    static let defaultValue: TextSizePreference? = nil
}

public extension EnvironmentValues {
    var textSizePreference: TextSizePreference? {
        get { self[TextSizePreferenceKey.self] }
        set { self[TextSizePreferenceKey.self] = newValue }
    }
}

public extension View {
    /// Override the text size preference for this view hierarchy
    func textSizePreference(_ preference: TextSizePreference?) -> some View {
        environment(\.textSizePreference, preference)
            .environment(\.sizeCategory, preference?.contentSizeCategory ?? ContentSizeCategory.medium)
    }
}

// MARK: - Accessibility Helpers

public extension View {
    /// Make text more readable by increasing line spacing for larger text sizes
    func accessibleLineSpacing() -> some View {
        self.modifier(AccessibleLineSpacingModifier())
    }
}

private struct AccessibleLineSpacingModifier: ViewModifier {
    @Environment(\.sizeCategory) private var sizeCategory
    
    func body(content: Content) -> some View {
        content.lineSpacing(lineSpacing)
    }
    
    private var lineSpacing: CGFloat {
        switch sizeCategory {
        case .extraSmall, .small, .medium:
            return 2
        case .large:
            return 4
        case .extraLarge:
            return 6
        case .extraExtraLarge:
            return 8
        case .extraExtraExtraLarge:
            return 10
        case .accessibilityMedium:
            return 12
        case .accessibilityLarge:
            return 14
        case .accessibilityExtraLarge:
            return 16
        case .accessibilityExtraExtraLarge:
            return 18
        case .accessibilityExtraExtraExtraLarge:
            return 20
        @unknown default:
            return 2
        }
    }
}

// MARK: - Layout Helpers

/// Helper to determine if we should use a more spacious layout
public struct DynamicTypeLayoutHelper {
    @Environment(\.sizeCategory) private var sizeCategory
    
    public var shouldUseAccessibilityLayout: Bool {
        sizeCategory.isAccessibilityCategory
    }
    
    public var shouldUseCompactLayout: Bool {
        sizeCategory <= .medium
    }
    
    public var recommendedSpacing: CGFloat {
        switch sizeCategory {
        case .extraSmall, .small:
            return 8
        case .medium:
            return 12
        case .large, .extraLarge:
            return 16
        case .extraExtraLarge, .extraExtraExtraLarge:
            return 20
        default: // Accessibility sizes
            return 24
        }
    }
}