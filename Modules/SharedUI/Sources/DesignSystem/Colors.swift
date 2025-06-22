import SwiftUI

/// Core color palette for the app
public struct AppColors {
    // MARK: - Primary Colors
    public static let primary = Color.accentColor
    public static let primaryLight = Color(hex: "#4A90E2")
    public static let primaryDark = Color(hex: "#2E5C8A")
    
    // MARK: - Semantic Colors
    public static let success = Color.green
    public static let warning = Color.orange
    public static let error = Color.red
    public static let info = Color.blue
    
    // MARK: - Background Colors
    public static let background = Color(.systemBackground)
    public static let secondaryBackground = Color(.secondarySystemBackground)
    public static let tertiaryBackground = Color(.tertiarySystemBackground)
    
    // MARK: - Text Colors
    public static let textPrimary = Color(.label)
    public static let textSecondary = Color(.secondaryLabel)
    public static let textTertiary = Color(.tertiaryLabel)
    public static let textQuaternary = Color(.quaternaryLabel)
    
    // MARK: - Surface Colors
    public static let surface = Color(.systemGray6)
    public static let surfaceSecondary = Color(.systemGray5)
    
    // MARK: - Border Colors
    public static let border = Color(.separator)
    public static let borderLight = Color(.opaqueSeparator)
}

// MARK: - Color Extensions
public extension Color {
    /// Initialize color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}