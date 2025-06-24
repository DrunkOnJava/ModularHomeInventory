import Foundation

/// A comprehensive mock data factory that generates all entities with proper relationships
/// This ensures all mock data is interconnected and behaves like real app data
@MainActor
public final class ComprehensiveMockDataFactory {
    
    // MARK: - Singleton
    public static let shared = ComprehensiveMockDataFactory()
    private init() {}
    
    // MARK: - Generated Data Storage
    private var generatedLocations: [Location] = []
    private var generatedItems: [Item] = []
    private var generatedReceipts: [Receipt] = []
    private var generatedWarranties: [Warranty] = []
    private var generatedInsurancePolicies: [InsurancePolicy] = []
    private var generatedServiceRecords: [ServiceRecord] = []
    private var generatedBudgets: [Budget] = []
    private var generatedTags: [Tag] = []
    private var generatedCollections: [Collection] = []
    private var generatedStorageUnits: [StorageUnit] = []
    
    // MARK: - Main Generation Method
    public func generateComprehensiveMockData() -> MockDataSet {
        // Reset all data
        resetData()
        
        // Generate in order of dependencies
        generateTags()
        generateLocations()
        generateStorageUnits()
        generateCollections()
        generateItems()
        generateWarranties()
        generateReceipts()
        generateInsurancePolicies()
        generateServiceRecords()
        generateBudgets()
        
        return MockDataSet(
            locations: generatedLocations,
            items: generatedItems,
            receipts: generatedReceipts,
            warranties: generatedWarranties,
            insurancePolicies: generatedInsurancePolicies,
            serviceRecords: generatedServiceRecords,
            budgets: generatedBudgets,
            tags: generatedTags,
            collections: generatedCollections,
            storageUnits: generatedStorageUnits
        )
    }
    
    // MARK: - Reset
    private func resetData() {
        generatedLocations = []
        generatedItems = []
        generatedReceipts = []
        generatedWarranties = []
        generatedInsurancePolicies = []
        generatedServiceRecords = []
        generatedBudgets = []
        generatedTags = []
        generatedCollections = []
        generatedStorageUnits = []
    }
    
    // MARK: - Tags Generation
    private func generateTags() {
        generatedTags = [
            Tag(name: "Electronics", color: "#007AFF", icon: "tv"),
            Tag(name: "Work Equipment", color: "#34C759", icon: "briefcase"),
            Tag(name: "Gaming", color: "#FF3B30", icon: "gamecontroller"),
            Tag(name: "Photography", color: "#FF9500", icon: "camera"),
            Tag(name: "Kitchen", color: "#AF52DE", icon: "fork.knife"),
            Tag(name: "Furniture", color: "#5856D6", icon: "sofa"),
            Tag(name: "High Value", color: "#FFD700", icon: "star.fill"),
            Tag(name: "Under Warranty", color: "#00C7BE", icon: "shield"),
            Tag(name: "Insured", color: "#FF2D55", icon: "lock.shield")
        ]
    }
    
    // MARK: - Locations Generation
    private func generateLocations() {
        let home = Location(name: "Home", icon: "house.fill", color: "#007AFF")
        let office = Location(name: "Office", icon: "building.2.fill", color: "#34C759")
        let storage = Location(name: "Storage Unit", icon: "archivebox.fill", color: "#FF9500")
        
        // Home sub-locations
        let livingRoom = Location(name: "Living Room", icon: "sofa.fill", color: "#007AFF", parentId: home.id)
        let bedroom = Location(name: "Master Bedroom", icon: "bed.double.fill", color: "#007AFF", parentId: home.id)
        let kitchen = Location(name: "Kitchen", icon: "refrigerator.fill", color: "#007AFF", parentId: home.id)
        let garage = Location(name: "Garage", icon: "car.fill", color: "#007AFF", parentId: home.id)
        let homeOffice = Location(name: "Home Office", icon: "desktopcomputer", color: "#007AFF", parentId: home.id)
        
        // Office sub-locations
        let desk = Location(name: "Desk", icon: "desk.fill", color: "#34C759", parentId: office.id)
        let serverRoom = Location(name: "Server Room", icon: "server.rack", color: "#34C759", parentId: office.id)
        
        generatedLocations = [
            home, office, storage,
            livingRoom, bedroom, kitchen, garage, homeOffice,
            desk, serverRoom
        ]
    }
    
    // MARK: - Storage Units Generation
    private func generateStorageUnits() {
        let homeLocation = generatedLocations.first { $0.name == "Home" }!
        let officeLocation = generatedLocations.first { $0.name == "Office" }!
        
        generatedStorageUnits = [
            StorageUnit(
                name: "Electronics Cabinet",
                locationId: homeLocation.id,
                capacity: 20,
                currentOccupancy: 12,
                description: "Temperature-controlled cabinet for sensitive electronics"
            ),
            StorageUnit(
                name: "Tool Chest",
                locationId: generatedLocations.first { $0.name == "Garage" }!.id,
                capacity: 50,
                currentOccupancy: 35,
                description: "Large rolling tool chest with multiple drawers"
            ),
            StorageUnit(
                name: "Server Rack",
                locationId: generatedLocations.first { $0.name == "Server Room" }!.id,
                capacity: 42, // 42U rack
                currentOccupancy: 28,
                description: "Standard 42U server rack"
            )
        ]
    }
    
    // MARK: - Collections Generation
    private func generateCollections() {
        generatedCollections = [
            Collection(
                name: "Work Setup",
                description: "All equipment used for work",
                icon: "briefcase.fill",
                color: "#34C759"
            ),
            Collection(
                name: "Gaming Gear",
                description: "Gaming consoles, accessories, and games",
                icon: "gamecontroller.fill",
                color: "#FF3B30"
            ),
            Collection(
                name: "Home Theater",
                description: "TV, sound system, and media devices",
                icon: "tv.fill",
                color: "#007AFF"
            ),
            Collection(
                name: "Kitchen Appliances",
                description: "All kitchen electronics and appliances",
                icon: "refrigerator.fill",
                color: "#AF52DE"
            )
        ]
    }
    
    // MARK: - Items Generation
    private func generateItems() {
        let baseDate = Date()
        
        // Work Setup Items
        let macBookPro = createItem(
            name: "MacBook Pro 16\" M3 Max",
            brand: "Apple",
            model: "MK1H3LL/A",
            category: .electronics,
            subcategory: "Laptop",
            purchaseDate: baseDate.addingTimeInterval(-180 * 24 * 60 * 60), // 6 months ago
            purchasePrice: 3999.00,
            currentValue: 3800.00,
            location: "Home Office",
            tags: ["Electronics", "Work Equipment", "High Value", "Under Warranty", "Insured"],
            serialNumber: "C02XG2JHQ05",
            barcode: "194253081470",
            notes: "Work laptop - 64GB RAM, 2TB SSD",
            quantity: 1,
            condition: .excellent,
            collections: ["Work Setup"]
        )
        
        let studioDisplay = createItem(
            name: "Apple Studio Display 27\"",
            brand: "Apple",
            model: "A2525",
            category: .electronics,
            subcategory: "Monitor",
            purchaseDate: baseDate.addingTimeInterval(-150 * 24 * 60 * 60), // 5 months ago
            purchasePrice: 1599.00,
            currentValue: 1500.00,
            location: "Home Office",
            tags: ["Electronics", "Work Equipment", "Under Warranty", "Insured"],
            serialNumber: "G5JK9VX4N2",
            barcode: "194253126935",
            notes: "5K Retina display with tilt-adjustable stand",
            quantity: 1,
            condition: .excellent,
            collections: ["Work Setup"]
        )
        
        let hermanMillerChair = createItem(
            name: "Herman Miller Aeron Chair",
            brand: "Herman Miller",
            model: "Aeron Remastered",
            category: .furniture,
            subcategory: "Office Chair",
            purchaseDate: baseDate.addingTimeInterval(-365 * 24 * 60 * 60), // 1 year ago
            purchasePrice: 1795.00,
            currentValue: 1500.00,
            location: "Home Office",
            tags: ["Furniture", "Work Equipment", "Under Warranty"],
            serialNumber: "AER-2023-0847563",
            notes: "Size C, Graphite, PostureFit SL",
            quantity: 1,
            condition: .excellent,
            collections: ["Work Setup"],
            warrantyMonths: 144 // 12 year warranty
        )
        
        // Gaming Items
        let ps5 = createItem(
            name: "PlayStation 5",
            brand: "Sony",
            model: "CFI-1215A",
            category: .electronics,
            subcategory: "Gaming Console",
            purchaseDate: baseDate.addingTimeInterval(-90 * 24 * 60 * 60), // 3 months ago
            purchasePrice: 499.99,
            currentValue: 450.00,
            location: "Living Room",
            tags: ["Electronics", "Gaming", "Under Warranty"],
            serialNumber: "SN123456789",
            barcode: "711719541028",
            notes: "Disc version with extra controller",
            quantity: 1,
            condition: .excellent,
            collections: ["Gaming Gear", "Home Theater"]
        )
        
        // Kitchen Items
        let espressoMachine = createItem(
            name: "Breville Barista Express",
            brand: "Breville",
            model: "BES870XL",
            category: .appliances,
            subcategory: "Coffee Machine",
            purchaseDate: baseDate.addingTimeInterval(-400 * 24 * 60 * 60), // 13 months ago
            purchasePrice: 699.95,
            currentValue: 500.00,
            location: "Kitchen",
            tags: ["Kitchen", "Under Warranty"],
            serialNumber: "BRV-2023-098765",
            barcode: "021614055064",
            notes: "Stainless steel, includes grinder",
            quantity: 1,
            condition: .good,
            collections: ["Kitchen Appliances"]
        )
        
        let vitamix = createItem(
            name: "Vitamix A3500",
            brand: "Vitamix",
            model: "A3500",
            category: .appliances,
            subcategory: "Blender",
            purchaseDate: baseDate.addingTimeInterval(-200 * 24 * 60 * 60), // 6.5 months ago
            purchasePrice: 599.95,
            currentValue: 550.00,
            location: "Kitchen",
            tags: ["Kitchen", "Under Warranty"],
            serialNumber: "VM2023456789",
            barcode: "703113640667",
            notes: "Ascent Series with smart detect",
            quantity: 1,
            condition: .excellent,
            collections: ["Kitchen Appliances"],
            warrantyMonths: 120 // 10 year warranty
        )
        
        // TV and Home Theater
        let lgTV = createItem(
            name: "LG C3 65\" OLED TV",
            brand: "LG",
            model: "OLED65C3PUA",
            category: .electronics,
            subcategory: "Television",
            purchaseDate: baseDate.addingTimeInterval(-120 * 24 * 60 * 60), // 4 months ago
            purchasePrice: 1996.99,
            currentValue: 1800.00,
            location: "Living Room",
            tags: ["Electronics", "High Value", "Under Warranty", "Insured"],
            serialNumber: "LG2023OLED65789",
            barcode: "195174037195",
            notes: "4K OLED with wall mount",
            quantity: 1,
            condition: .excellent,
            collections: ["Home Theater"]
        )
        
        let sonosSoundbar = createItem(
            name: "Sonos Arc",
            brand: "Sonos",
            model: "ARCG1US1BLK",
            category: .electronics,
            subcategory: "Sound System",
            purchaseDate: baseDate.addingTimeInterval(-120 * 24 * 60 * 60), // 4 months ago
            purchasePrice: 899.00,
            currentValue: 850.00,
            location: "Living Room",
            tags: ["Electronics", "Under Warranty"],
            serialNumber: "SN-ARC-2023-456",
            barcode: "878269013417",
            notes: "Premium smart soundbar with Dolby Atmos",
            quantity: 1,
            condition: .excellent,
            collections: ["Home Theater"]
        )
        
        // Tools
        let dewaltDrill = createItem(
            name: "DeWalt 20V MAX Drill",
            brand: "DeWalt",
            model: "DCD791D2",
            category: .tools,
            subcategory: "Power Tool",
            purchaseDate: baseDate.addingTimeInterval(-500 * 24 * 60 * 60), // 1.5 years ago
            purchasePrice: 169.00,
            currentValue: 120.00,
            location: "Garage",
            tags: ["Under Warranty"],
            serialNumber: "DW2022DRILL789",
            barcode: "885911473224",
            notes: "Includes 2 batteries and charger",
            quantity: 1,
            condition: .good,
            storageUnitId: generatedStorageUnits.first { $0.name == "Tool Chest" }?.id
        )
        
        // Photography
        let sonyCamera = createItem(
            name: "Sony α7 IV",
            brand: "Sony",
            model: "ILCE-7M4",
            category: .electronics,
            subcategory: "Camera",
            purchaseDate: baseDate.addingTimeInterval(-240 * 24 * 60 * 60), // 8 months ago
            purchasePrice: 2498.00,
            currentValue: 2300.00,
            location: "Home Office",
            tags: ["Electronics", "Photography", "High Value", "Under Warranty", "Insured"],
            serialNumber: "SONY-A7IV-2023-123",
            barcode: "027242923348",
            notes: "Full-frame mirrorless camera body only",
            quantity: 1,
            condition: .excellent,
            collections: ["Work Setup"] // Used for video calls too
        )
        
        generatedItems = [
            macBookPro, studioDisplay, hermanMillerChair,
            ps5, espressoMachine, vitamix,
            lgTV, sonosSoundbar, dewaltDrill, sonyCamera
        ]
        
        // Add more variety of items
        generatedItems.append(contentsOf: generateAdditionalItems())
    }
    
    private func generateAdditionalItems() -> [Item] {
        let baseDate = Date()
        var additionalItems: [Item] = []
        
        // More electronics
        additionalItems.append(createItem(
            name: "iPad Pro 12.9\"",
            brand: "Apple",
            model: "MNXR3LL/A",
            category: .electronics,
            subcategory: "Tablet",
            purchaseDate: baseDate.addingTimeInterval(-60 * 24 * 60 * 60),
            purchasePrice: 1299.00,
            currentValue: 1200.00,
            location: "Living Room",
            tags: ["Electronics", "Under Warranty", "Insured"],
            serialNumber: "DMPXR2VWPK",
            barcode: "194253194378",
            notes: "256GB WiFi + Cellular, Space Gray",
            quantity: 1,
            condition: .excellent,
            collections: ["Work Setup"]
        ))
        
        // Furniture
        additionalItems.append(createItem(
            name: "West Elm Andes Sofa",
            brand: "West Elm",
            model: "Andes 3-Seater",
            category: .furniture,
            subcategory: "Sofa",
            purchaseDate: baseDate.addingTimeInterval(-730 * 24 * 60 * 60), // 2 years ago
            purchasePrice: 2099.00,
            currentValue: 1500.00,
            location: "Living Room",
            tags: ["Furniture", "High Value"],
            notes: "Ink Blue velvet, deep depth",
            quantity: 1,
            condition: .good
        ))
        
        // More appliances
        additionalItems.append(createItem(
            name: "Dyson V15 Detect",
            brand: "Dyson",
            model: "447922-01",
            category: .appliances,
            subcategory: "Vacuum",
            purchaseDate: baseDate.addingTimeInterval(-45 * 24 * 60 * 60),
            purchasePrice: 749.99,
            currentValue: 700.00,
            location: "Storage Unit",
            tags: ["Under Warranty"],
            serialNumber: "DY2023V15789",
            barcode: "885609019710",
            notes: "Cordless vacuum with laser detection",
            quantity: 1,
            condition: .excellent,
            warrantyMonths: 24
        ))
        
        // Jewelry
        additionalItems.append(createItem(
            name: "Omega Seamaster",
            brand: "Omega",
            model: "210.30.42.20.01.001",
            category: .collectibles,
            subcategory: "Watch",
            purchaseDate: baseDate.addingTimeInterval(-1095 * 24 * 60 * 60), // 3 years ago
            purchasePrice: 4550.00,
            currentValue: 5200.00, // Appreciated
            location: "Master Bedroom",
            tags: ["High Value", "Insured"],
            serialNumber: "OM87654321",
            notes: "Seamaster Diver 300M, black dial",
            quantity: 1,
            condition: .excellent,
            warrantyMonths: 60
        ))
        
        return additionalItems
    }
    
    private func createItem(
        name: String,
        brand: String? = nil,
        model: String? = nil,
        category: ItemCategory,
        subcategory: String? = nil,
        purchaseDate: Date,
        purchasePrice: Decimal,
        currentValue: Decimal? = nil,
        location: String,
        tags: [String] = [],
        serialNumber: String? = nil,
        barcode: String? = nil,
        notes: String? = nil,
        quantity: Int = 1,
        condition: ItemCondition = .good,
        collections: [String] = [],
        storageUnitId: UUID? = nil,
        warrantyMonths: Int = 12
    ) -> Item {
        let locationId = generatedLocations.first { $0.name == location }?.id ?? generatedLocations[0].id
        let tagIds = tags.compactMap { tagName in generatedTags.first { $0.name == tagName }?.id }
        let collectionIds = collections.compactMap { collName in generatedCollections.first { $0.name == collName }?.id }
        
        return Item(
            name: name,
            brand: brand,
            model: model,
            serialNumber: serialNumber,
            purchaseDate: purchaseDate,
            purchasePrice: purchasePrice,
            currentValue: currentValue ?? purchasePrice * 0.9,
            category: category,
            categoryId: UUID(), // Would be actual category ID
            subcategory: subcategory,
            quantity: quantity,
            locationId: locationId,
            storageUnitId: storageUnitId,
            notes: notes,
            tags: Set(tagIds),
            customFields: [:],
            attachments: [],
            barcode: barcode,
            qrCode: nil,
            condition: condition,
            collectionIds: Set(collectionIds),
            warrantyId: nil, // Will be set after warranty generation
            mainImageId: nil
        )
    }
    
    // MARK: - Warranties Generation
    private func generateWarranties() {
        for (index, item) in generatedItems.enumerated() {
            // Most electronics and appliances have warranties
            if [.electronics, .appliances, .furniture, .tools].contains(item.category) {
                let warranty = createWarranty(for: item, index: index)
                generatedWarranties.append(warranty)
                
                // Update item with warranty ID
                generatedItems[index].warrantyId = warranty.id
                
                // Some items might have extended warranties
                if item.purchasePrice > 1000 && Bool.random() {
                    let extendedWarranty = createExtendedWarranty(for: item, baseWarranty: warranty)
                    generatedWarranties.append(extendedWarranty)
                }
            }
        }
    }
    
    private func createWarranty(for item: Item, index: Int) -> Warranty {
        let warrantyLengths: [ItemCategory: Int] = [
            .electronics: 12,
            .appliances: 24,
            .furniture: 60,
            .tools: 36
        ]
        
        let months = warrantyLengths[item.category] ?? 12
        let startDate = item.purchaseDate
        let endDate = Calendar.current.date(byAdding: .month, value: months, to: startDate)!
        
        return Warranty(
            itemId: item.id,
            warrantyType: .manufacturer,
            provider: item.brand ?? "Manufacturer",
            startDate: startDate,
            endDate: endDate,
            coverageDetails: "Standard manufacturer warranty covering defects in materials and workmanship",
            registrationNumber: "WR-\(item.serialNumber ?? UUID().uuidString.prefix(8))",
            registrationDate: startDate,
            extendedWarrantyAvailable: item.purchasePrice > 500,
            documents: [],
            notes: nil,
            notificationSettings: WarrantyNotificationSettings(
                enableNotifications: true,
                daysBefore: [30, 7, 1]
            ),
            transferable: true,
            remainingTransfers: item.category == .electronics ? 1 : nil
        )
    }
    
    private func createExtendedWarranty(for item: Item, baseWarranty: Warranty) -> Warranty {
        let extendedMonths = item.category == .electronics ? 24 : 36
        let startDate = baseWarranty.endDate
        let endDate = Calendar.current.date(byAdding: .month, value: extendedMonths, to: startDate)!
        let cost = item.purchasePrice * 0.15 // 15% of item price
        
        return Warranty(
            itemId: item.id,
            warrantyType: .extended,
            provider: "SquareTrade",
            startDate: startDate,
            endDate: endDate,
            coverageDetails: "Extended protection plan covering accidental damage and mechanical failures",
            cost: cost,
            registrationNumber: "SQ-\(UUID().uuidString.prefix(10))",
            registrationDate: item.purchaseDate,
            extendedWarrantyAvailable: false,
            documents: [],
            claimHistory: [],
            maxClaimAmount: item.purchasePrice,
            deductible: 99.00,
            transferable: false
        )
    }
    
    // MARK: - Receipts Generation
    private func generateReceipts() {
        // Group items by purchase date and create receipts
        let calendar = Calendar.current
        let itemsByPurchaseDate = Dictionary(grouping: generatedItems) { item in
            calendar.startOfDay(for: item.purchaseDate)
        }
        
        for (date, items) in itemsByPurchaseDate {
            // Group by likely store based on category and brand
            let itemsByStore = groupItemsByStore(items)
            
            for (storeName, storeItems) in itemsByStore {
                let receipt = createReceipt(
                    storeName: storeName,
                    date: date,
                    items: storeItems
                )
                generatedReceipts.append(receipt)
            }
        }
    }
    
    private func groupItemsByStore(_ items: [Item]) -> [String: [Item]] {
        var itemsByStore: [String: [Item]] = [:]
        
        for item in items {
            let storeName: String
            
            // Determine store based on brand and category
            if item.brand == "Apple" {
                storeName = "Apple Store"
            } else if item.brand == "Sony" && item.category == .electronics {
                storeName = "Best Buy"
            } else if ["Breville", "Vitamix", "Dyson"].contains(item.brand) {
                storeName = "Williams Sonoma"
            } else if item.category == .furniture {
                storeName = item.brand == "Herman Miller" ? "Herman Miller Store" : "West Elm"
            } else if item.category == .tools {
                storeName = "Home Depot"
            } else if item.brand == "LG" || item.brand == "Sonos" {
                storeName = "Best Buy"
            } else {
                storeName = "Amazon"
            }
            
            itemsByStore[storeName, default: []].append(item)
        }
        
        return itemsByStore
    }
    
    private func createReceipt(storeName: String, date: Date, items: [Item]) -> Receipt {
        let subtotal = items.reduce(Decimal(0)) { $0 + $1.purchasePrice * Decimal($1.quantity) }
        let taxRate: Decimal = 0.0875 // 8.75% tax
        let tax = subtotal * taxRate
        let total = subtotal + tax
        
        let receiptItems = items.map { item in
            ReceiptItem(
                name: item.name,
                quantity: item.quantity,
                unitPrice: item.purchasePrice,
                totalPrice: item.purchasePrice * Decimal(item.quantity),
                category: item.category.rawValue,
                itemId: item.id
            )
        }
        
        return Receipt(
            storeName: storeName,
            date: date,
            totalAmount: total,
            taxAmount: tax,
            subtotal: subtotal,
            items: receiptItems,
            paymentMethod: .creditCard,
            last4Digits: String(format: "%04d", Int.random(in: 1000...9999)),
            receiptNumber: generateReceiptNumber(),
            itemIds: items.map { $0.id },
            notes: nil,
            returnByDate: Calendar.current.date(byAdding: .day, value: storeName == "Apple Store" ? 14 : 30, to: date),
            warrantyInfo: items.contains { $0.purchasePrice > 500 } ? "Extended warranty available" : nil,
            rawText: generateReceiptText(storeName: storeName, items: receiptItems, subtotal: subtotal, tax: tax, total: total)
        )
    }
    
    private func generateReceiptNumber() -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let numbers = "0123456789"
        
        let prefix = String((0..<3).map { _ in letters.randomElement()! })
        let suffix = String((0..<6).map { _ in numbers.randomElement()! })
        
        return "\(prefix)-\(suffix)"
    }
    
    private func generateReceiptText(storeName: String, items: [ReceiptItem], subtotal: Decimal, tax: Decimal, total: Decimal) -> String {
        var text = "\(storeName)\n"
        text += "=" * 30 + "\n"
        
        for item in items {
            text += "\(item.name)\n"
            text += "  \(item.quantity) x $\(item.unitPrice) = $\(item.totalPrice)\n"
        }
        
        text += "-" * 30 + "\n"
        text += "Subtotal: $\(subtotal)\n"
        text += "Tax: $\(tax)\n"
        text += "Total: $\(total)\n"
        
        return text
    }
    
    // MARK: - Insurance Policies Generation
    private func generateInsurancePolicies() {
        // Homeowners/Renters Insurance covering multiple items
        let homeownersPolicyItems = generatedItems.filter { item in
            item.locationId == generatedLocations.first { $0.name == "Home" }?.id
        }
        
        if !homeownersPolicyItems.isEmpty {
            let homeownersPolicy = InsurancePolicy(
                policyNumber: "HO-2024-123456",
                provider: "State Farm",
                type: .homeowners,
                itemIds: Set(homeownersPolicyItems.map { $0.id }),
                coverageAmount: 500000,
                deductible: 1000,
                premium: PremiumDetails(
                    amount: 125,
                    frequency: .monthly,
                    nextDueDate: Date().addingTimeInterval(30 * 24 * 60 * 60)
                ),
                startDate: Date().addingTimeInterval(-365 * 24 * 60 * 60),
                endDate: Date().addingTimeInterval(365 * 24 * 60 * 60),
                coverageDetails: "Comprehensive coverage for personal property up to $250,000",
                contactInfo: InsuranceContact(
                    agentName: "Sarah Johnson",
                    agentPhone: "(555) 123-4567",
                    agentEmail: "sarah.johnson@statefarm.com",
                    claimsPhone: "1-800-STATE-FARM"
                )
            )
            generatedInsurancePolicies.append(homeownersPolicy)
        }
        
        // Valuable items policy for high-value items
        let highValueItems = generatedItems.filter { $0.purchasePrice > 2000 }
        if !highValueItems.isEmpty {
            let valuablesPolicy = InsurancePolicy(
                policyNumber: "VAL-2024-789012",
                provider: "Chubb",
                type: .valuable,
                itemIds: Set(highValueItems.map { $0.id }),
                coverageAmount: highValueItems.reduce(Decimal(0)) { $0 + $1.currentValue },
                deductible: 500,
                premium: PremiumDetails(
                    amount: 600,
                    frequency: .annual,
                    nextDueDate: Date().addingTimeInterval(180 * 24 * 60 * 60)
                ),
                startDate: Date().addingTimeInterval(-180 * 24 * 60 * 60),
                endDate: Date().addingTimeInterval(185 * 24 * 60 * 60),
                coverageDetails: "Scheduled personal property coverage with agreed value",
                contactInfo: InsuranceContact(
                    agentName: "Michael Chen",
                    agentPhone: "(555) 987-6543",
                    claimsPhone: "1-800-CHUBB"
                )
            )
            generatedInsurancePolicies.append(valuablesPolicy)
        }
        
        // Electronics protection for specific items
        let electronicsToInsure = generatedItems.filter { 
            $0.category == .electronics && $0.purchasePrice > 500 && $0.purchaseDate > Date().addingTimeInterval(-365 * 24 * 60 * 60)
        }
        
        if !electronicsToInsure.isEmpty {
            let electronicsPolicy = InsurancePolicy(
                policyNumber: "ELEC-2024-345678",
                provider: "Asurion",
                type: .electronics,
                itemIds: Set(electronicsToInsure.prefix(5).map { $0.id }), // Limit to 5 items
                coverageAmount: 10000,
                deductible: 149,
                premium: PremiumDetails(
                    amount: 29.99,
                    frequency: .monthly,
                    nextDueDate: Date().addingTimeInterval(15 * 24 * 60 * 60)
                ),
                startDate: Date().addingTimeInterval(-90 * 24 * 60 * 60),
                endDate: Date().addingTimeInterval(275 * 24 * 60 * 60),
                coverageDetails: "Covers accidental damage, theft, and mechanical breakdown",
                contactInfo: InsuranceContact(
                    claimsPhone: "1-866-551-5924",
                    claimsEmail: "claims@asurion.com"
                ),
                claims: [
                    InsuranceClaim(
                        claimNumber: "CLM-2023-001",
                        dateOfLoss: Date().addingTimeInterval(-45 * 24 * 60 * 60),
                        description: "Cracked screen on iPad Pro",
                        claimAmount: 399,
                        approvedAmount: 250,
                        paidAmount: 250,
                        status: .paid
                    )
                ]
            )
            generatedInsurancePolicies.append(electronicsPolicy)
        }
    }
    
    // MARK: - Service Records Generation
    private func generateServiceRecords() {
        // Generate service records for items that would need maintenance
        let itemsNeedingService = generatedItems.filter { item in
            [.appliances, .electronics, .tools].contains(item.category)
        }
        
        for item in itemsNeedingService {
            // Regular maintenance
            if item.category == .appliances {
                let serviceRecord = ServiceRecord(
                    itemId: item.id,
                    warrantyId: generatedWarranties.first { $0.itemId == item.id }?.id,
                    type: .maintenance,
                    date: Date().addingTimeInterval(-30 * 24 * 60 * 60),
                    provider: "\(item.brand ?? "Authorized") Service Center",
                    cost: 0, // Covered under warranty
                    description: "Annual maintenance and cleaning",
                    technicianName: "John Smith",
                    serviceOrderNumber: "SVC-\(Int.random(in: 100000...999999))",
                    partsReplaced: ["Filter", "Seals"],
                    nextServiceDate: Date().addingTimeInterval(335 * 24 * 60 * 60),
                    underWarranty: true
                )
                generatedServiceRecords.append(serviceRecord)
            }
            
            // Repairs for some items
            if item.purchaseDate < Date().addingTimeInterval(-180 * 24 * 60 * 60) && Bool.random() {
                let repairRecord = ServiceRecord(
                    itemId: item.id,
                    warrantyId: generatedWarranties.first { $0.itemId == item.id }?.id,
                    type: .repair,
                    date: Date().addingTimeInterval(-60 * 24 * 60 * 60),
                    provider: "TechFix Solutions",
                    cost: item.category == .electronics ? 149.99 : 89.99,
                    description: item.category == .electronics ? "Power supply replacement" : "Motor bearing replacement",
                    technicianName: "Maria Garcia",
                    serviceOrderNumber: "REP-\(Int.random(in: 100000...999999))",
                    partsReplaced: item.category == .electronics ? ["Power Supply Unit"] : ["Motor Bearing", "Belt"],
                    underWarranty: false,
                    invoiceNumber: "INV-\(Int.random(in: 10000...99999))"
                )
                generatedServiceRecords.append(repairRecord)
            }
        }
    }
    
    // MARK: - Budgets Generation
    private func generateBudgets() {
        let currentYear = Calendar.current.component(.year, from: Date())
        let currentMonth = Calendar.current.component(.month, from: Date())
        
        // Annual budget
        let annualBudget = Budget(
            name: "\(currentYear) Home Inventory Budget",
            period: .annual,
            amount: 15000,
            categories: [
                .electronics: 5000,
                .appliances: 3000,
                .furniture: 3000,
                .tools: 1000,
                .collectibles: 2000,
                .other: 1000
            ],
            startDate: Calendar.current.date(from: DateComponents(year: currentYear, month: 1, day: 1))!,
            endDate: Calendar.current.date(from: DateComponents(year: currentYear, month: 12, day: 31))!,
            alerts: BudgetAlerts(
                enableAlerts: true,
                thresholds: [50, 75, 90, 100]
            ),
            rolloverUnused: true,
            notes: "Annual budget for all home inventory purchases"
        )
        generatedBudgets.append(annualBudget)
        
        // Monthly budgets
        for month in 1...currentMonth {
            let monthlyBudget = Budget(
                name: "\(Calendar.current.monthSymbols[month-1]) \(currentYear) Budget",
                period: .monthly,
                amount: 1250,
                categories: [
                    .electronics: 500,
                    .appliances: 300,
                    .furniture: 200,
                    .other: 250
                ],
                startDate: Calendar.current.date(from: DateComponents(year: currentYear, month: month, day: 1))!,
                endDate: Calendar.current.date(from: DateComponents(year: currentYear, month: month, day: Calendar.current.range(of: .day, in: .month, for: Date())!.upperBound - 1))!,
                alerts: BudgetAlerts(
                    enableAlerts: true,
                    thresholds: [75, 90, 100]
                ),
                parentBudgetId: annualBudget.id
            )
            generatedBudgets.append(monthlyBudget)
        }
        
        // Category-specific budgets
        let electronicsBudget = Budget(
            name: "Electronics Budget \(currentYear)",
            period: .annual,
            amount: 5000,
            categories: [.electronics: 5000],
            startDate: Calendar.current.date(from: DateComponents(year: currentYear, month: 1, day: 1))!,
            endDate: Calendar.current.date(from: DateComponents(year: currentYear, month: 12, day: 31))!,
            alerts: BudgetAlerts(enableAlerts: true, thresholds: [80, 100]),
            notes: "Dedicated budget for electronics and gadgets"
        )
        generatedBudgets.append(electronicsBudget)
    }
}

// MARK: - Mock Data Set Structure
public struct MockDataSet {
    public let locations: [Location]
    public let items: [Item]
    public let receipts: [Receipt]
    public let warranties: [Warranty]
    public let insurancePolicies: [InsurancePolicy]
    public let serviceRecords: [ServiceRecord]
    public let budgets: [Budget]
    public let tags: [Tag]
    public let collections: [Collection]
    public let storageUnits: [StorageUnit]
}

// String multiplication helper
fileprivate extension String {
    static func * (lhs: String, rhs: Int) -> String {
        String(repeating: lhs, count: rhs)
    }
}