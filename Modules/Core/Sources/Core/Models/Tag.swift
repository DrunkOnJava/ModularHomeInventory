import Foundation
import SwiftUI

/// Represents a tag that can be applied to items
public struct Tag: Identifiable, Codable, Equatable, Hashable {
    public let id: UUID
    public let name: String
    public let colorHex: String
    public let icon: String?
    public let createdAt: Date
    public let updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        colorHex: String = "#3B82F6", // Default blue color
        icon: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.icon = icon
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Computed Properties
public extension Tag {
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
}

// MARK: - Previews
public extension Tag {
    static var previews: [Tag] {
        [
            Tag(name: "Important", colorHex: "#EF4444", icon: "star.fill"),
            Tag(name: "Work", colorHex: "#3B82F6", icon: "briefcase.fill"),
            Tag(name: "Personal", colorHex: "#10B981", icon: "person.fill"),
            Tag(name: "Gift", colorHex: "#F59E0B", icon: "gift.fill"),
            Tag(name: "Warranty", colorHex: "#8B5CF6", icon: "shield.fill"),
            Tag(name: "Insurance", colorHex: "#EC4899", icon: "umbrella.fill"),
            Tag(name: "Vintage", colorHex: "#F97316", icon: "clock.fill"),
            Tag(name: "Electronics", colorHex: "#06B6D4", icon: "bolt.fill")
        ]
    }
}

// MARK: - Color Extension
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
}