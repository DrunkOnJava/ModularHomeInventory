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
}