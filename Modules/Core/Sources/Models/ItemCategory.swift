import Foundation

/// Categories for organizing items
public enum ItemCategory: String, Codable, CaseIterable {
    case electronics = "Electronics"
    case furniture = "Furniture"
    case clothing = "Clothing"
    case books = "Books"
    case kitchen = "Kitchen"
    case tools = "Tools"
    case sports = "Sports"
    case toys = "Toys"
    case jewelry = "Jewelry"
    case art = "Art"
    case collectibles = "Collectibles"
    case appliances = "Appliances"
    case outdoor = "Outdoor"
    case office = "Office"
    case automotive = "Automotive"
    case health = "Health"
    case beauty = "Beauty"
    case home = "Home"
    case garden = "Garden"
    case other = "Other"
    
    public var icon: String {
        switch self {
        case .electronics: return "tv"
        case .furniture: return "chair"
        case .clothing: return "tshirt"
        case .books: return "book"
        case .kitchen: return "fork.knife"
        case .tools: return "wrench"
        case .sports: return "sportscourt"
        case .toys: return "teddybear"
        case .jewelry: return "sparkles"
        case .art: return "paintpalette"
        case .collectibles: return "star"
        case .appliances: return "washer"
        case .outdoor: return "tent"
        case .office: return "paperclip"
        case .automotive: return "car"
        case .health: return "heart"
        case .beauty: return "eyebrow"
        case .home: return "house"
        case .garden: return "leaf"
        case .other: return "square.grid.2x2"
        }
    }
    
    public var displayName: String {
        self.rawValue
    }
    
    public var color: String {
        switch self {
        case .electronics: return "#3B82F6"
        case .furniture: return "#92400E"
        case .clothing: return "#9333EA"
        case .books: return "#F97316"
        case .kitchen: return "#EF4444"
        case .tools: return "#6B7280"
        case .sports: return "#10B981"
        case .toys: return "#EC4899"
        case .jewelry: return "#F59E0B"
        case .art: return "#6366F1"
        case .collectibles: return "#14B8A6"
        case .appliances: return "#06B6D4"
        case .outdoor: return "#059669"
        case .office: return "#1E3A8A"
        case .automotive: return "#7F1D1D"
        case .health: return "#10B981"
        case .beauty: return "#F43F5E"
        case .home: return "#D97706"
        case .garden: return "#84CC16"
        case .other: return "#6B7280"
        }
    }
}