import Foundation

/// Standard corner radius values for consistent UI
/// Swift 5.9 - No Swift 6 features
public enum AppCornerRadius {
    /// Extra small corner radius (4pt)
    public static let xs: CGFloat = 4
    
    /// Small corner radius (8pt)
    public static let small: CGFloat = 8
    
    /// Medium corner radius (12pt)
    public static let medium: CGFloat = 12
    
    /// Large corner radius (16pt)
    public static let large: CGFloat = 16
    
    /// Extra large corner radius (20pt)
    public static let xl: CGFloat = 20
    
    /// Full corner radius for circular elements
    public static let full: CGFloat = .infinity
}