import SwiftUI

/// Typography system with predefined text styles
/// Updated to support Dynamic Type
public struct AppTypography {
    // MARK: - Display
    public static func displayLarge(_ text: String) -> some View {
        Text(text)
            .dynamicTextStyle(.displayLarge)
    }
    
    public static func displayMedium(_ text: String) -> some View {
        Text(text)
            .dynamicTextStyle(.displayMedium)
    }
    
    public static func displaySmall(_ text: String) -> some View {
        Text(text)
            .dynamicTextStyle(.displaySmall)
    }
    
    // MARK: - Headline
    public static func headlineLarge(_ text: String) -> some View {
        Text(text)
            .dynamicTextStyle(.headlineLarge)
    }
    
    public static func headlineMedium(_ text: String) -> some View {
        Text(text)
            .dynamicTextStyle(.headlineMedium)
    }
    
    public static func headlineSmall(_ text: String) -> some View {
        Text(text)
            .dynamicTextStyle(.headlineSmall)
    }
    
    // MARK: - Body
    public static func bodyLarge(_ text: String) -> some View {
        Text(text)
            .dynamicTextStyle(.bodyLarge)
    }
    
    public static func bodyMedium(_ text: String) -> some View {
        Text(text)
            .dynamicTextStyle(.bodyMedium)
    }
    
    public static func bodySmall(_ text: String) -> some View {
        Text(text)
            .dynamicTextStyle(.bodySmall)
    }
    
    // MARK: - Label
    public static func labelLarge(_ text: String) -> some View {
        Text(text)
            .dynamicTextStyle(.labelLarge)
    }
    
    public static func labelMedium(_ text: String) -> some View {
        Text(text)
            .dynamicTextStyle(.labelMedium)
    }
    
    public static func labelSmall(_ text: String) -> some View {
        Text(text)
            .dynamicTextStyle(.labelSmall)
    }
}

// MARK: - Text Style View Modifier (Deprecated - Use dynamicTextStyle instead)
@available(*, deprecated, message: "Use dynamicTextStyle for Dynamic Type support")
public struct TextStyle: ViewModifier {
    public enum Style {
        case displayLarge, displayMedium, displaySmall
        case headlineLarge, headlineMedium, headlineSmall
        case bodyLarge, bodyMedium, bodySmall
        case labelLarge, labelMedium, labelSmall
        
        var font: Font {
            switch self {
            case .displayLarge: return .system(size: 34, weight: .bold)
            case .displayMedium: return .system(size: 28, weight: .semibold)
            case .displaySmall: return .system(size: 22, weight: .semibold)
            case .headlineLarge: return .system(size: 20, weight: .semibold)
            case .headlineMedium: return .system(size: 17, weight: .semibold)
            case .headlineSmall: return .system(size: 15, weight: .semibold)
            case .bodyLarge: return .system(size: 17, weight: .regular)
            case .bodyMedium: return .system(size: 15, weight: .regular)
            case .bodySmall: return .system(size: 13, weight: .regular)
            case .labelLarge: return .system(size: 13, weight: .medium)
            case .labelMedium: return .system(size: 11, weight: .medium)
            case .labelSmall: return .system(size: 10, weight: .medium)
            }
        }
    }
    
    let style: Style
    
    public func body(content: Content) -> some View {
        content.font(style.font)
    }
}

public extension View {
    /// Legacy text style modifier - use dynamicTextStyle for Dynamic Type support
    @available(*, deprecated, message: "Use dynamicTextStyle for Dynamic Type support")
    func textStyle(_ style: TextStyle.Style) -> some View {
        modifier(TextStyle(style: style))
    }
    
    /// Apply text style with Dynamic Type support
    func textStyle(_ style: DynamicTextStyle.Style) -> some View {
        modifier(DynamicTextStyle(style: style))
    }
}