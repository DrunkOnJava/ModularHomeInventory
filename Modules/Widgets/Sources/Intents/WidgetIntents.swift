import AppIntents
import Core

/// Intent to configure inventory stats widget
/// Swift 5.9 - No Swift 6 features
@available(iOS 17.0, *)
struct ConfigureInventoryStatsIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configure Inventory Stats"
    static var description = IntentDescription("Choose what stats to display")
    
    @Parameter(title: "Show Value", default: true)
    var showValue: Bool
    
    @Parameter(title: "Show Favorites", default: true)
    var showFavorites: Bool
    
    @Parameter(title: "Show Categories", default: true)
    var showCategories: Bool
}

/// Intent to configure spending widget
@available(iOS 17.0, *)
struct ConfigureSpendingIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configure Spending"
    static var description = IntentDescription("Choose spending period and categories")
    
    @Parameter(title: "Time Period", default: .month)
    var timePeriod: SpendingPeriod
    
    @Parameter(title: "Show Trend", default: true)
    var showTrend: Bool
    
    @Parameter(title: "Show Top Category", default: true)
    var showTopCategory: Bool
    
    enum SpendingPeriod: String, CaseIterable, AppEnum {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        
        static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Spending Period")
        static var caseDisplayRepresentations: [SpendingPeriod: DisplayRepresentation] = [
            .week: "This Week",
            .month: "This Month",
            .year: "This Year"
        ]
    }
}

/// Intent to open specific item
@available(iOS 17.0, *)
struct OpenItemIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Item"
    static var description = IntentDescription("Open a specific item in the app")
    
    @Parameter(title: "Item ID")
    var itemId: String
    
    init() {}
    
    init(itemId: String) {
        self.itemId = itemId
    }
    
    func perform() async throws -> some IntentResult {
        // This would deep link into the app to show the item
        return .result()
    }
}

/// Intent to add quick item
@available(iOS 17.0, *)
struct QuickAddItemIntent: AppIntent {
    static var title: LocalizedStringResource = "Quick Add Item"
    static var description = IntentDescription("Quickly add an item to inventory")
    
    @Parameter(title: "Name")
    var name: String
    
    @Parameter(title: "Category")
    var category: ItemCategoryOption
    
    @Parameter(title: "Location")
    var location: String?
    
    init() {}
    
    func perform() async throws -> some IntentResult {
        // This would add the item via the repository
        return .result()
    }
    
    enum ItemCategoryOption: String, CaseIterable, AppEnum {
        case electronics = "Electronics"
        case furniture = "Furniture"
        case clothing = "Clothing"
        case books = "Books"
        case appliances = "Appliances"
        case tools = "Tools"
        case sports = "Sports"
        case toys = "Toys"
        case other = "Other"
        
        static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Category")
        static var caseDisplayRepresentations: [ItemCategoryOption: DisplayRepresentation] = [
            .electronics: "Electronics",
            .furniture: "Furniture",
            .clothing: "Clothing",
            .books: "Books",
            .appliances: "Appliances",
            .tools: "Tools",
            .sports: "Sports Equipment",
            .toys: "Toys & Games",
            .other: "Other"
        ]
    }
}