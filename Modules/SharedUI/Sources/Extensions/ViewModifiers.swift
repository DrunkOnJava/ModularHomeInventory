import SwiftUI

// MARK: - Corner Radius Modifier

public struct CornerRadiusModifier: ViewModifier {
    let size: CornerRadiusSize
    
    public func body(content: Content) -> some View {
        content.cornerRadius(size.value)
    }
}

/// View modifiers for consistent styling
public extension View {
    /// Apply a corner radius from the design system
    func appCornerRadius(_ radius: CGFloat) -> some View {
        self.cornerRadius(radius)
    }
    
    /// Apply a corner radius using semantic size names
    func appCornerRadius(_ size: CornerRadiusSize) -> some View {
        self.modifier(CornerRadiusModifier(size: size))
    }
}

/// Semantic corner radius sizes
public enum CornerRadiusSize {
    case xs
    case small
    case medium
    case large
    case xl
    case full
    
    var value: CGFloat {
        switch self {
        case .xs: return AppCornerRadius.xs
        case .small: return AppCornerRadius.small
        case .medium: return AppCornerRadius.medium
        case .large: return AppCornerRadius.large
        case .xl: return AppCornerRadius.xl
        case .full: return AppCornerRadius.full
        }
    }
}