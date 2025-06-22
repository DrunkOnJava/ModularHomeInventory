import SwiftUI
import Core

/// Public API for the Premium module
/// Swift 5.9 - No Swift 6 features
@MainActor
public protocol PremiumModuleAPI {
    /// Check if user has premium subscription
    var isPremium: Bool { get }
    
    /// Listen to premium status changes
    var isPremiumPublisher: Published<Bool>.Publisher { get }
    
    /// Creates the premium upgrade view
    func makePremiumUpgradeView() -> AnyView
    
    /// Creates the subscription management view
    func makeSubscriptionManagementView() -> AnyView
    
    /// Purchase premium subscription
    func purchasePremium() async throws
    
    /// Restore previous purchases
    func restorePurchases() async throws
    
    /// Check if a feature requires premium
    func requiresPremium(_ feature: PremiumFeature) -> Bool
}

/// Premium features that can be checked
public enum PremiumFeature: String, CaseIterable {
    case unlimitedItems = "unlimited_items"
    case cloudSync = "cloud_sync"
    case advancedReports = "advanced_reports"
    case multipleLocations = "multiple_locations"
    case barcodeScanning = "barcode_scanning"
    case receiptOCR = "receipt_ocr"
    case exportData = "export_data"
    case themes = "themes"
    case widgets = "widgets"
    
    public var displayName: String {
        switch self {
        case .unlimitedItems: return "Unlimited Items"
        case .cloudSync: return "Cloud Sync"
        case .advancedReports: return "Advanced Reports"
        case .multipleLocations: return "Multiple Locations"
        case .barcodeScanning: return "Barcode Scanning"
        case .receiptOCR: return "Receipt OCR"
        case .exportData: return "Export Data"
        case .themes: return "Themes"
        case .widgets: return "Widgets"
        }
    }
    
    public var description: String {
        switch self {
        case .unlimitedItems: return "Add unlimited items to your inventory"
        case .cloudSync: return "Sync your data across all devices"
        case .advancedReports: return "Generate detailed inventory reports"
        case .multipleLocations: return "Organize items across multiple locations"
        case .barcodeScanning: return "Scan barcodes for quick item entry"
        case .receiptOCR: return "Extract item details from receipt photos"
        case .exportData: return "Export your data in various formats"
        case .themes: return "Customize the app appearance"
        case .widgets: return "Quick access from your home screen"
        }
    }
    
    public var iconName: String {
        switch self {
        case .unlimitedItems: return "infinity"
        case .cloudSync: return "icloud"
        case .advancedReports: return "chart.bar"
        case .multipleLocations: return "map"
        case .barcodeScanning: return "barcode"
        case .receiptOCR: return "doc.text.viewfinder"
        case .exportData: return "square.and.arrow.up"
        case .themes: return "paintbrush"
        case .widgets: return "apps.iphone"
        }
    }
}

/// Dependencies required by the Premium module
public struct PremiumModuleDependencies {
    public let purchaseService: PurchaseServiceProtocol
    public let userDefaults: UserDefaults
    
    public init(
        purchaseService: PurchaseServiceProtocol,
        userDefaults: UserDefaults = .standard
    ) {
        self.purchaseService = purchaseService
        self.userDefaults = userDefaults
    }
}

/// Protocol for in-app purchase service
public protocol PurchaseServiceProtocol {
    /// Available products
    func fetchProducts() async throws -> [PremiumProduct]
    
    /// Purchase a product
    func purchase(_ product: PremiumProduct) async throws
    
    /// Restore purchases
    func restorePurchases() async throws
    
    /// Check if user has active subscription
    func hasActiveSubscription() async -> Bool
}

/// Premium product information
public struct PremiumProduct: Identifiable {
    public let id: String
    public let name: String
    public let description: String
    public let price: String
    public let period: SubscriptionPeriod?
    
    public init(
        id: String,
        name: String,
        description: String,
        price: String,
        period: SubscriptionPeriod? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.period = period
    }
}

/// Subscription period
public enum SubscriptionPeriod {
    case monthly
    case yearly
    
    public var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }
}