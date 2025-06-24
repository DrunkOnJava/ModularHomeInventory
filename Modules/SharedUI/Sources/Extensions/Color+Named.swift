import SwiftUI

/// Extension to convert color names to SwiftUI colors
/// Swift 5.9 - No Swift 6 features
public extension Color {
    /// Convert a color name string to a SwiftUI Color
    static func named(_ name: String) -> Color {
        switch name.lowercased() {
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "mint": return Color.mint
        case "teal": return .teal
        case "cyan": return .cyan
        case "indigo": return .indigo
        case "brown": return .brown
        case "gray": return .gray
        case "black": return Color(.systemGray6) // Use dark gray instead of pure black for visibility
        default: return .blue
        }
    }
}