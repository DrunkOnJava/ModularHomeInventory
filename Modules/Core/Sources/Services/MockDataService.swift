import Foundation

/// Service to generate comprehensive mock data for showcasing app features
/// Swift 5.9 - No Swift 6 features
public final class MockDataService {
    public static let shared = MockDataService()
    
    private init() {}
    
    // MARK: - Locations
    public static let locations: [Location] = [
        Location(name: "Living Room", icon: "sofa", notes: "Main living area"),
        Location(name: "Master Bedroom", icon: "bed.double", notes: "Primary bedroom"),
        Location(name: "Kitchen", icon: "fork.knife", notes: "Kitchen and dining area"),
        Location(name: "Home Office", icon: "desktopcomputer", notes: "Work from home setup"),
        Location(name: "Garage", icon: "car", notes: "Storage and tools"),
        Location(name: "Storage Unit", icon: "shippingbox", notes: "Climate controlled storage"),
        Location(name: "Office", icon: "building.2", notes: "Work office")
    ]
    
    // MARK: - Storage Units
    public static let storageUnits: [StorageUnit] = [
        StorageUnit(name: "TV Stand Cabinet", type: .cabinet, locationId: locations[0].id, notes: "Entertainment center storage"),
        StorageUnit(name: "Closet Shelf A", type: .shelf, locationId: locations[1].id, notes: "Top shelf - seasonal items"),
        StorageUnit(name: "Kitchen Pantry", type: .closet, locationId: locations[2].id, notes: "Food and kitchen supplies"),
        StorageUnit(name: "Office Drawer Unit", type: .drawer, locationId: locations[3].id, notes: "Office supplies and documents"),
        StorageUnit(name: "Tool Chest", type: .cabinet, locationId: locations[4].id, notes: "Tools and hardware"),
        StorageUnit(name: "Storage Boxes", type: .box, locationId: locations[5].id, notes: "Archived items")
    ]
    
    // MARK: - Comprehensive Items
    public static func generateComprehensiveItems() -> [Item] {
        var items: [Item] = []
        
        // Electronics Category
        items.append(contentsOf: [
            Item(
                name: "MacBook Pro 16-inch",
                brand: "Apple",
                model: "M3 Max",
                category: .electronics,
                condition: .excellent,
                value: 3499.00,
                purchasePrice: 3499.00,
                purchaseDate: Date().addingTimeInterval(-90 * 24 * 60 * 60), // 90 days ago
                notes: "1TB SSD, 36GB RAM, Space Gray",
                barcode: "194253082194",
                serialNumber: "C02XG2JMQ05Q",
                tags: ["laptop", "work", "apple", "computer"],
                locationId: locations[3].id,
                storageUnitId: storageUnits[3].id,
                warrantyId: UUID(),
                storeName: "Apple Store"
            ),
            Item(
                name: "Sony A7R V",
                brand: "Sony",
                model: "ILCE-7RM5",
                category: .electronics,
                condition: .excellent,
                value: 3899.00,
                purchasePrice: 3899.00,
                purchaseDate: Date().addingTimeInterval(-45 * 24 * 60 * 60),
                notes: "61MP Full-frame mirrorless camera",
                barcode: "027242923942",
                serialNumber: "5012345",
                tags: ["camera", "photography", "professional"],
                locationId: locations[3].id,
                warrantyId: UUID(),
                storeName: "B&H Photo"
            ),
            Item(
                name: "iPad Pro 12.9",
                brand: "Apple",
                model: "A2764",
                category: .electronics,
                condition: .good,
                value: 1099.00,
                purchasePrice: 1299.00,
                purchaseDate: Date().addingTimeInterval(-365 * 24 * 60 * 60), // 1 year ago
                notes: "512GB WiFi + Cellular, with Magic Keyboard",
                barcode: "194253378457",
                serialNumber: "DLXVG9FKQ1GC",
                tags: ["tablet", "apple", "mobile"],
                locationId: locations[0].id,
                warrantyId: UUID(),
                storeName: "Best Buy"
            ),
            Item(
                name: "LG OLED TV 65\"",
                brand: "LG",
                model: "OLED65C3PUA",
                category: .electronics,
                condition: .excellent,
                value: 1799.00,
                purchasePrice: 2199.00,
                purchaseDate: Date().addingTimeInterval(-180 * 24 * 60 * 60),
                notes: "4K OLED Smart TV",
                barcode: "719192642669",
                tags: ["tv", "entertainment", "smart-home"],
                locationId: locations[0].id,
                warrantyId: UUID(),
                storeName: "Costco"
            ),
            Item(
                name: "PlayStation 5",
                brand: "Sony",
                model: "CFI-1215A",
                category: .electronics,
                condition: .good,
                value: 499.00,
                purchasePrice: 499.00,
                purchaseDate: Date().addingTimeInterval(-300 * 24 * 60 * 60),
                notes: "Disc version with extra controller",
                barcode: "711719541486",
                tags: ["gaming", "console", "entertainment"],
                locationId: locations[0].id,
                storageUnitId: storageUnits[0].id,
                storeName: "GameStop"
            )
        ])
        
        // Furniture Category
        items.append(contentsOf: [
            Item(
                name: "Steelcase Leap V2",
                brand: "Steelcase",
                model: "Leap V2",
                category: .furniture,
                condition: .excellent,
                value: 1200.00,
                purchasePrice: 1200.00,
                purchaseDate: Date().addingTimeInterval(-400 * 24 * 60 * 60),
                notes: "Ergonomic office chair, black fabric",
                tags: ["office", "chair", "ergonomic"],
                locationId: locations[3].id,
                storeName: "Steelcase Store"
            ),
            Item(
                name: "Standing Desk",
                brand: "Uplift Desk",
                model: "V2 Commercial",
                category: .furniture,
                condition: .good,
                value: 899.00,
                purchasePrice: 899.00,
                purchaseDate: Date().addingTimeInterval(-380 * 24 * 60 * 60),
                notes: "72x30 bamboo top, memory settings",
                tags: ["desk", "office", "adjustable"],
                locationId: locations[3].id,
                storeName: "Uplift Desk"
            ),
            Item(
                name: "Leather Sofa",
                brand: "West Elm",
                model: "Hamilton",
                category: .furniture,
                condition: .good,
                value: 2499.00,
                purchasePrice: 2999.00,
                purchaseDate: Date().addingTimeInterval(-730 * 24 * 60 * 60), // 2 years ago
                notes: "3-seat sofa, cognac leather",
                tags: ["sofa", "living-room", "leather"],
                locationId: locations[0].id,
                storeName: "West Elm"
            )
        ])
        
        // Appliances Category
        items.append(contentsOf: [
            Item(
                name: "Espresso Machine",
                brand: "Breville",
                model: "Barista Express",
                category: .appliances,
                condition: .excellent,
                value: 699.00,
                purchasePrice: 699.00,
                purchaseDate: Date().addingTimeInterval(-120 * 24 * 60 * 60),
                notes: "Stainless steel, built-in grinder",
                barcode: "021614062130",
                serialNumber: "BE870XL/A",
                tags: ["coffee", "kitchen", "appliance"],
                locationId: locations[2].id,
                warrantyId: UUID(),
                storeName: "Williams Sonoma"
            ),
            Item(
                name: "Robot Vacuum",
                brand: "iRobot",
                model: "Roomba j7+",
                category: .appliances,
                condition: .good,
                value: 599.00,
                purchasePrice: 799.00,
                purchaseDate: Date().addingTimeInterval(-200 * 24 * 60 * 60),
                notes: "Self-emptying, obstacle avoidance",
                barcode: "885155025517",
                tags: ["cleaning", "smart-home", "robot"],
                locationId: locations[0].id,
                warrantyId: UUID(),
                storeName: "Amazon"
            ),
            Item(
                name: "KitchenAid Mixer",
                brand: "KitchenAid",
                model: "Professional 600",
                category: .appliances,
                condition: .excellent,
                value: 449.00,
                purchasePrice: 449.00,
                purchaseDate: Date().addingTimeInterval(-500 * 24 * 60 * 60),
                notes: "6-quart, Empire Red",
                barcode: "883049118949",
                tags: ["kitchen", "baking", "mixer"],
                locationId: locations[2].id,
                storeName: "Sur La Table"
            )
        ])
        
        // Tools Category
        items.append(contentsOf: [
            Item(
                name: "Cordless Drill",
                brand: "DeWalt",
                model: "DCD791D2",
                category: .tools,
                condition: .good,
                value: 179.00,
                purchasePrice: 179.00,
                purchaseDate: Date().addingTimeInterval(-600 * 24 * 60 * 60),
                notes: "20V MAX, 2 batteries included",
                barcode: "885911475129",
                tags: ["power-tools", "drill", "construction"],
                locationId: locations[4].id,
                storageUnitId: storageUnits[4].id,
                storeName: "Home Depot"
            ),
            Item(
                name: "Socket Set",
                brand: "Craftsman",
                model: "CMMT99206",
                category: .tools,
                condition: .excellent,
                value: 99.00,
                purchasePrice: 99.00,
                purchaseDate: Date().addingTimeInterval(-450 * 24 * 60 * 60),
                notes: "230-piece mechanics tool set",
                barcode: "885911613309",
                tags: ["hand-tools", "mechanics", "repair"],
                locationId: locations[4].id,
                storageUnitId: storageUnits[4].id,
                storeName: "Lowe's"
            )
        ])
        
        // Clothing Category
        items.append(contentsOf: [
            Item(
                name: "Winter Jacket",
                brand: "Patagonia",
                model: "Down Sweater",
                category: .clothing,
                condition: .excellent,
                value: 279.00,
                purchasePrice: 279.00,
                purchaseDate: Date().addingTimeInterval(-60 * 24 * 60 * 60),
                notes: "Men's Large, Navy Blue",
                tags: ["jacket", "winter", "outdoor"],
                locationId: locations[1].id,
                storageUnitId: storageUnits[1].id,
                storeName: "Patagonia"
            ),
            Item(
                name: "Running Shoes",
                brand: "Nike",
                model: "Pegasus 40",
                category: .clothing,
                condition: .good,
                quantity: 2,
                value: 130.00,
                purchasePrice: 130.00,
                purchaseDate: Date().addingTimeInterval(-30 * 24 * 60 * 60),
                notes: "Size 10.5, Black/White",
                tags: ["shoes", "running", "athletic"],
                locationId: locations[1].id,
                storeName: "Nike Store"
            ),
            Item(
                name: "Dress Shirt Collection",
                brand: "Various",
                model: "Mixed",
                category: .clothing,
                condition: .good,
                quantity: 5,
                value: 400.00,
                purchasePrice: 400.00,
                notes: "Professional dress shirts",
                tags: ["clothing", "professional", "shirts"],
                locationId: locations[1].id,
                storageUnitId: storageUnits[1].id
            )
        ])
        
        // Books Category
        items.append(contentsOf: [
            Item(
                name: "Technical Book Collection",
                brand: "O'Reilly",
                category: .books,
                condition: .good,
                quantity: 25,
                value: 1250.00,
                purchasePrice: 1500.00,
                notes: "Programming and tech books",
                tags: ["books", "technical", "programming"],
                locationId: locations[3].id,
                storeName: "Amazon"
            ),
            Item(
                name: "Fiction Collection",
                category: .books,
                condition: .good,
                quantity: 50,
                value: 750.00,
                notes: "Various fiction novels",
                tags: ["books", "fiction", "novels"],
                locationId: locations[0].id
            )
        ])
        
        // Sports Equipment
        items.append(contentsOf: [
            Item(
                name: "Mountain Bike",
                brand: "Trek",
                model: "Marlin 8",
                category: .sports,
                condition: .good,
                value: 949.00,
                purchasePrice: 1199.00,
                purchaseDate: Date().addingTimeInterval(-400 * 24 * 60 * 60),
                notes: "29er, Medium frame",
                tags: ["bike", "outdoor", "exercise"],
                locationId: locations[4].id,
                storeName: "Trek Store"
            ),
            Item(
                name: "Yoga Mat Set",
                brand: "Manduka",
                model: "PRO",
                category: .sports,
                condition: .excellent,
                value: 120.00,
                purchasePrice: 120.00,
                notes: "With blocks and strap",
                tags: ["yoga", "fitness", "exercise"],
                locationId: locations[1].id
            )
        ])
        
        // Collectibles
        items.append(contentsOf: [
            Item(
                name: "Vintage Watch",
                brand: "Omega",
                model: "Speedmaster",
                category: .collectibles,
                condition: .excellent,
                value: 4500.00,
                purchasePrice: 3500.00,
                purchaseDate: Date().addingTimeInterval(-1095 * 24 * 60 * 60), // 3 years ago
                notes: "1969 Professional, with box and papers",
                serialNumber: "145.022",
                tags: ["watch", "vintage", "luxury", "investment"],
                locationId: locations[1].id,
                storeName: "Chrono24"
            ),
            Item(
                name: "Art Collection",
                category: .collectibles,
                condition: .excellent,
                quantity: 10,
                value: 5000.00,
                notes: "Various paintings and prints",
                tags: ["art", "collectible", "investment"],
                locationId: locations[0].id
            )
        ])
        
        // Add items with various warranty statuses
        let warranties = generateWarranties()
        for (index, warranty) in warranties.enumerated() where index < items.count {
            items[index].warrantyId = warranty.id
        }
        
        return items
    }
    
    // MARK: - Warranties
    public static func generateWarranties() -> [Warranty] {
        let now = Date()
        return [
            // Active warranties
            Warranty(
                itemId: UUID(),
                type: .manufacturer,
                provider: "Apple",
                startDate: now.addingTimeInterval(-90 * 24 * 60 * 60),
                endDate: now.addingTimeInterval(275 * 24 * 60 * 60), // Expires in 9 months
                coverageDetails: "AppleCare+ for Mac",
                cost: 399.00
            ),
            Warranty(
                itemId: UUID(),
                type: .manufacturer,
                provider: "Sony",
                startDate: now.addingTimeInterval(-45 * 24 * 60 * 60),
                endDate: now.addingTimeInterval(320 * 24 * 60 * 60), // Expires in 10.5 months
                coverageDetails: "Standard manufacturer warranty"
            ),
            // Expiring soon
            Warranty(
                itemId: UUID(),
                type: .extended,
                provider: "Best Buy",
                startDate: now.addingTimeInterval(-340 * 24 * 60 * 60),
                endDate: now.addingTimeInterval(25 * 24 * 60 * 60), // Expires in 25 days
                coverageDetails: "Geek Squad Protection",
                cost: 199.00
            ),
            // Expired
            Warranty(
                itemId: UUID(),
                type: .manufacturer,
                provider: "LG",
                startDate: now.addingTimeInterval(-730 * 24 * 60 * 60),
                endDate: now.addingTimeInterval(-5 * 24 * 60 * 60), // Expired 5 days ago
                coverageDetails: "Standard 1-year warranty"
            )
        ]
    }
    
    // MARK: - Receipts
    public static func generateReceipts() -> [Receipt] {
        let items = generateComprehensiveItems()
        var receipts: [Receipt] = []
        
        // Create receipts for various stores
        let appleItems = items.filter { $0.storeName == "Apple Store" }
        if !appleItems.isEmpty {
            receipts.append(Receipt(
                storeName: "Apple Store",
                date: appleItems[0].purchaseDate ?? Date(),
                totalAmount: appleItems.reduce(0) { $0 + ($1.purchasePrice ?? 0) },
                itemIds: appleItems.map { $0.id },
                rawText: "APPLE STORE\n#R123456789\n\nMacBook Pro 16\" - $3,499.00\niPad Pro 12.9\" - $1,299.00\n\nSubtotal: $4,798.00\nTax: $419.83\nTotal: $5,217.83"
            ))
        }
        
        return receipts
    }
    
    // MARK: - Collections
    public static func generateCollections() -> [Collection] {
        return [
            Collection(
                name: "Home Office Setup",
                description: "All equipment for the home office",
                icon: "desktopcomputer",
                color: "blue",
                itemIds: []
            ),
            Collection(
                name: "Emergency Kit",
                description: "Items for emergency preparedness",
                icon: "cross.case",
                color: "red",
                itemIds: []
            ),
            Collection(
                name: "Travel Gear",
                description: "Essential items for traveling",
                icon: "airplane",
                color: "green",
                itemIds: []
            ),
            Collection(
                name: "Investment Items",
                description: "Items that appreciate in value",
                icon: "chart.line.uptrend.xyaxis",
                color: "orange",
                itemIds: []
            )
        ]
    }
    
    // MARK: - Budgets
    public static func generateBudgets() -> [Budget] {
        let now = Date()
        let startOfMonth = Calendar.current.dateInterval(of: .month, for: now)?.start ?? now
        let startOfYear = Calendar.current.dateInterval(of: .year, for: now)?.start ?? now
        
        return [
            Budget(
                name: "Electronics Budget",
                amount: 500.00,
                period: .monthly,
                category: .electronics,
                startDate: startOfMonth,
                isActive: true,
                notificationThreshold: 0.80
            ),
            Budget(
                name: "Annual Furniture",
                amount: 3000.00,
                period: .yearly,
                category: .furniture,
                startDate: startOfYear,
                isActive: true,
                notificationThreshold: 0.75
            ),
            Budget(
                name: "Clothing Quarterly",
                amount: 600.00,
                period: .custom,
                category: .clothing,
                startDate: now.addingTimeInterval(-45 * 24 * 60 * 60),
                endDate: now.addingTimeInterval(45 * 24 * 60 * 60),
                isActive: true,
                notificationThreshold: 0.90
            )
        ]
    }
    
    // MARK: - Load All Mock Data
    public func loadAllMockData(
        itemRepository: any ItemRepository,
        locationRepository: any LocationRepository,
        receiptRepository: (any ReceiptRepository)? = nil,
        budgetRepository: (any BudgetRepository)? = nil
    ) async throws {
        // Load locations first
        for location in Self.locations {
            try await locationRepository.save(location)
        }
        
        // Load items
        let items = Self.generateComprehensiveItems()
        for item in items {
            try await itemRepository.save(item)
        }
        
        // Load receipts if repository available
        if let receiptRepo = receiptRepository {
            for receipt in Self.generateReceipts() {
                try await receiptRepo.save(receipt)
            }
        }
        
        // Load budgets if repository available
        if let budgetRepo = budgetRepository {
            for budget in Self.generateBudgets() {
                try await budgetRepo.create(budget)
            }
        }
    }
}