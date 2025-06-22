import Foundation

/// Condition states for items
public enum ItemCondition: String, Codable, CaseIterable {
    case new = "New"
    case likeNew = "Like New"
    case excellent = "Excellent"
    case veryGood = "Very Good"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
    case forParts = "For Parts"
    
    public var displayName: String {
        self.rawValue
    }
    
    public var icon: String {
        switch self {
        case .new: return "sparkles"
        case .likeNew: return "star.fill"
        case .excellent: return "star"
        case .veryGood: return "hand.thumbsup.fill"
        case .good: return "hand.thumbsup"
        case .fair: return "minus.circle"
        case .poor: return "exclamationmark.triangle"
        case .forParts: return "wrench.and.screwdriver"
        }
    }
    
    public var colorName: String {
        switch self {
        case .new, .likeNew: return "green"
        case .excellent, .veryGood: return "blue"
        case .good: return "teal"
        case .fair: return "orange"
        case .poor, .forParts: return "red"
        }
    }
}