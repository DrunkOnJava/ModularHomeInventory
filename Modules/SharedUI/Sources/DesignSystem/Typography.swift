import SwiftUI

/// Typography system with predefined text styles
public struct AppTypography {
    // MARK: - Display
    public static func displayLarge(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 34, weight: .bold, design: .default))
    }
    
    public static func displayMedium(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 28, weight: .semibold, design: .default))
    }
    
    public static func displaySmall(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 22, weight: .semibold, design: .default))
    }
    
    // MARK: - Headline
    public static func headlineLarge(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 20, weight: .semibold, design: .default))
    }
    
    public static func headlineMedium(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 17, weight: .semibold, design: .default))
    }
    
    public static func headlineSmall(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .semibold, design: .default))
    }
    
    // MARK: - Body
    public static func bodyLarge(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 17, weight: .regular, design: .default))
    }
    
    public static func bodyMedium(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .regular, design: .default))
    }
    
    public static func bodySmall(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .regular, design: .default))
    }
    
    // MARK: - Label
    public static func labelLarge(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .medium, design: .default))
    }
    
    public static func labelMedium(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium, design: .default))
    }
    
    public static func labelSmall(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .medium, design: .default))
    }
}

// MARK: - Text Style View Modifier
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
    func textStyle(_ style: TextStyle.Style) -> some View {
        modifier(TextStyle(style: style))
    }
}