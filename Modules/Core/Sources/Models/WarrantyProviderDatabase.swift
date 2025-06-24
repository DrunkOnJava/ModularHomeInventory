import Foundation

/// Database of common warranty providers with contact information
public struct WarrantyProviderDatabase {
    
    public static let providers: [WarrantyProviderInfo] = [
        // Electronics Manufacturers
        WarrantyProviderInfo(
            name: "Apple",
            category: .manufacturer,
            phoneNumbers: [
                ContactNumber(type: .support, number: "1-800-APL-CARE", region: "US"),
                ContactNumber(type: .support, number: "1-800-275-2273", region: "US")
            ],
            websites: [
                Website(type: .support, url: "https://support.apple.com"),
                Website(type: .warranty, url: "https://checkcoverage.apple.com")
            ],
            email: "support@apple.com",
            warrantyCheckUrl: "https://checkcoverage.apple.com",
            notes: "AppleCare+ available for extended coverage"
        ),
        
        WarrantyProviderInfo(
            name: "Samsung",
            category: .manufacturer,
            phoneNumbers: [
                ContactNumber(type: .support, number: "1-800-SAMSUNG", region: "US"),
                ContactNumber(type: .support, number: "1-800-726-7864", region: "US")
            ],
            websites: [
                Website(type: .support, url: "https://www.samsung.com/support"),
                Website(type: .warranty, url: "https://www.samsung.com/us/support/warranty")
            ],
            warrantyCheckUrl: "https://www.samsung.com/us/support/warranty",
            notes: "Samsung Care+ for extended protection"
        ),
        
        WarrantyProviderInfo(
            name: "Sony",
            category: .manufacturer,
            phoneNumbers: [
                ContactNumber(type: .support, number: "1-800-222-7669", region: "US")
            ],
            websites: [
                Website(type: .support, url: "https://www.sony.com/electronics/support")
            ],
            warrantyCheckUrl: "https://productregistration.sony.com",
            notes: "Extended warranty available through Sony Store"
        ),
        
        WarrantyProviderInfo(
            name: "LG",
            category: .manufacturer,
            phoneNumbers: [
                ContactNumber(type: .support, number: "1-800-243-0000", region: "US")
            ],
            websites: [
                Website(type: .support, url: "https://www.lg.com/us/support")
            ],
            warrantyCheckUrl: "https://www.lg.com/us/support/warranty-information"
        ),
        
        WarrantyProviderInfo(
            name: "Dell",
            category: .manufacturer,
            phoneNumbers: [
                ContactNumber(type: .support, number: "1-800-624-9897", region: "US")
            ],
            websites: [
                Website(type: .support, url: "https://www.dell.com/support"),
                Website(type: .warranty, url: "https://www.dell.com/support/assets-online/us/en/04/")
            ],
            warrantyCheckUrl: "https://www.dell.com/support/assets-online/us/en/04/"
        ),
        
        // Retailers
        WarrantyProviderInfo(
            name: "Best Buy - Geek Squad",
            category: .retailer,
            phoneNumbers: [
                ContactNumber(type: .support, number: "1-800-433-5778", region: "US")
            ],
            websites: [
                Website(type: .support, url: "https://www.bestbuy.com/site/geek-squad/protection-plans/pcmcat280100050012.c"),
                Website(type: .claims, url: "https://www.bestbuy.com/geeksquad/protectionplan/claim")
            ],
            email: "geeksquad@bestbuy.com",
            notes: "Geek Squad Protection Plans"
        ),
        
        WarrantyProviderInfo(
            name: "Home Depot",
            category: .retailer,
            phoneNumbers: [
                ContactNumber(type: .support, number: "1-800-430-3376", region: "US")
            ],
            websites: [
                Website(type: .support, url: "https://www.homedepot.com/c/protection_plans")
            ],
            notes: "Protection Plans for tools and appliances"
        ),
        
        WarrantyProviderInfo(
            name: "Costco",
            category: .retailer,
            phoneNumbers: [
                ContactNumber(type: .support, number: "1-800-774-2678", region: "US")
            ],
            websites: [
                Website(type: .support, url: "https://www.costco.com/concierge-services.html")
            ],
            notes: "Costco Concierge Services, automatic 2-year warranty on many items"
        ),
        
        // Extended Warranty Providers
        WarrantyProviderInfo(
            name: "SquareTrade (Allstate)",
            category: .extendedWarranty,
            phoneNumbers: [
                ContactNumber(type: .support, number: "1-877-927-7268", region: "US")
            ],
            websites: [
                Website(type: .support, url: "https://www.squaretrade.com"),
                Website(type: .claims, url: "https://claims.squaretrade.com")
            ],
            email: "help@squaretrade.com",
            notes: "Protection plans for electronics and appliances"
        ),
        
        WarrantyProviderInfo(
            name: "Asurion",
            category: .extendedWarranty,
            phoneNumbers: [
                ContactNumber(type: .support, number: "1-866-551-5924", region: "US")
            ],
            websites: [
                Website(type: .support, url: "https://www.asurion.com"),
                Website(type: .claims, url: "https://www.asurion.com/claims")
            ],
            notes: "Device protection and tech support"
        ),
        
        WarrantyProviderInfo(
            name: "American Home Shield",
            category: .homeWarranty,
            phoneNumbers: [
                ContactNumber(type: .support, number: "1-888-682-1043", region: "US")
            ],
            websites: [
                Website(type: .support, url: "https://www.ahs.com"),
                Website(type: .claims, url: "https://www.ahs.com/request-service")
            ],
            notes: "Home warranty plans"
        ),
        
        // Appliance Manufacturers
        WarrantyProviderInfo(
            name: "Whirlpool",
            category: .manufacturer,
            phoneNumbers: [
                ContactNumber(type: .support, number: "1-866-698-2538", region: "US")
            ],
            websites: [
                Website(type: .support, url: "https://www.whirlpool.com/support.html")
            ]
        ),
        
        WarrantyProviderInfo(
            name: "GE Appliances",
            category: .manufacturer,
            phoneNumbers: [
                ContactNumber(type: .support, number: "1-800-432-2737", region: "US")
            ],
            websites: [
                Website(type: .support, url: "https://www.geappliances.com/support/")
            ]
        ),
        
        // Vehicle Warranties
        WarrantyProviderInfo(
            name: "CarMax MaxCare",
            category: .vehicle,
            phoneNumbers: [
                ContactNumber(type: .support, number: "1-866-629-2273", region: "US")
            ],
            websites: [
                Website(type: .support, url: "https://www.carmaxautocare.com")
            ],
            notes: "Extended vehicle service plans"
        ),
        
        WarrantyProviderInfo(
            name: "Endurance",
            category: .vehicle,
            phoneNumbers: [
                ContactNumber(type: .support, number: "1-866-918-1438", region: "US")
            ],
            websites: [
                Website(type: .support, url: "https://www.endurancewarranty.com")
            ],
            notes: "Vehicle protection plans"
        )
    ]
    
    /// Search providers by name
    public static func search(query: String) -> [WarrantyProviderInfo] {
        let lowercasedQuery = query.lowercased()
        return providers.filter { provider in
            provider.name.lowercased().contains(lowercasedQuery) ||
            provider.category.rawValue.lowercased().contains(lowercasedQuery)
        }
    }
    
    /// Get providers by category
    public static func providers(for category: ProviderCategory) -> [WarrantyProviderInfo] {
        providers.filter { $0.category == category }
    }
}

// MARK: - Supporting Types

public struct WarrantyProviderInfo: Codable, Identifiable, Hashable {
    public let id: UUID
    public let name: String
    public let category: ProviderCategory
    public let phoneNumbers: [ContactNumber]
    public let websites: [Website]
    public let email: String?
    public let warrantyCheckUrl: String?
    public let notes: String?
    
    public init(
        id: UUID = UUID(),
        name: String,
        category: ProviderCategory,
        phoneNumbers: [ContactNumber] = [],
        websites: [Website] = [],
        email: String? = nil,
        warrantyCheckUrl: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.phoneNumbers = phoneNumbers
        self.websites = websites
        self.email = email
        self.warrantyCheckUrl = warrantyCheckUrl
        self.notes = notes
    }
}

public struct ContactNumber: Codable, Hashable {
    public let type: ContactType
    public let number: String
    public let region: String?
    public let hours: String?
    
    public init(
        type: ContactType,
        number: String,
        region: String? = nil,
        hours: String? = nil
    ) {
        self.type = type
        self.number = number
        self.region = region
        self.hours = hours
    }
}

public struct Website: Codable, Hashable {
    public let type: WebsiteType
    public let url: String
    public let description: String?
    
    public init(
        type: WebsiteType,
        url: String,
        description: String? = nil
    ) {
        self.type = type
        self.url = url
        self.description = description
    }
}

public enum ProviderCategory: String, Codable, CaseIterable, Hashable {
    case manufacturer = "manufacturer"
    case retailer = "retailer"
    case extendedWarranty = "extended_warranty"
    case homeWarranty = "home_warranty"
    case vehicle = "vehicle"
    case insurance = "insurance"
    case other = "other"
    
    public var displayName: String {
        switch self {
        case .manufacturer: return "Manufacturer"
        case .retailer: return "Retailer"
        case .extendedWarranty: return "Extended Warranty"
        case .homeWarranty: return "Home Warranty"
        case .vehicle: return "Vehicle"
        case .insurance: return "Insurance"
        case .other: return "Other"
        }
    }
}

public enum ContactType: String, Codable, Hashable {
    case support = "support"
    case claims = "claims"
    case sales = "sales"
    case emergency = "emergency"
}

public enum WebsiteType: String, Codable, Hashable {
    case support = "support"
    case warranty = "warranty"
    case claims = "claims"
    case registration = "registration"
    case portal = "portal"
}