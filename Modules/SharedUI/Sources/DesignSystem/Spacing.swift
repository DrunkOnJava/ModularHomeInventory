import Foundation
import SwiftUI

/// Spacing system based on 8pt grid
public struct AppSpacing {
    /// 4pt
    public static let xxs: CGFloat = 4
    
    /// 8pt
    public static let xs: CGFloat = 8
    
    /// 12pt
    public static let sm: CGFloat = 12
    
    /// 16pt
    public static let md: CGFloat = 16
    
    /// 24pt
    public static let lg: CGFloat = 24
    
    /// 32pt
    public static let xl: CGFloat = 32
    
    /// 48pt
    public static let xxl: CGFloat = 48
    
    /// 64pt
    public static let xxxl: CGFloat = 64
}

/// Padding view modifier for consistent spacing
public struct AppPadding: ViewModifier {
    let edges: Edge.Set
    let spacing: CGFloat
    
    public func body(content: Content) -> some View {
        content.padding(edges, spacing)
    }
}

public extension View {
    /// Apply padding with app spacing values
    func appPadding(_ edges: Edge.Set = .all, _ spacing: CGFloat = AppSpacing.md) -> some View {
        modifier(AppPadding(edges: edges, spacing: spacing))
    }
}