import SwiftUI
import Core
import Combine

/// Main implementation of the Premium module
/// Swift 5.9 - No Swift 6 features
@MainActor
public final class PremiumModule: ObservableObject, PremiumModuleAPI {
    @Published public private(set) var isPremium: Bool = false
    public var isPremiumPublisher: Published<Bool>.Publisher { $isPremium }
    
    private let dependencies: PremiumModuleDependencies
    private var cancellables = Set<AnyCancellable>()
    
    // Free tier limits
    private let freeItemLimit = 50
    private let freeLocationLimit = 1
    
    public init(dependencies: PremiumModuleDependencies) {
        self.dependencies = dependencies
        loadPremiumStatus()
        checkSubscriptionStatus()
    }
    
    public func makePremiumUpgradeView() -> AnyView {
        AnyView(PremiumUpgradeView(module: self))
    }
    
    public func makeSubscriptionManagementView() -> AnyView {
        AnyView(SubscriptionManagementView(module: self))
    }
    
    public func purchasePremium() async throws {
        let products = try await dependencies.purchaseService.fetchProducts()
        guard let product = products.first else {
            throw PremiumError.noProductsAvailable
        }
        
        try await dependencies.purchaseService.purchase(product)
        await checkSubscriptionStatus()
    }
    
    public func restorePurchases() async throws {
        try await dependencies.purchaseService.restorePurchases()
        await checkSubscriptionStatus()
    }
    
    public func requiresPremium(_ feature: PremiumFeature) -> Bool {
        // In free tier, some features are limited or unavailable
        switch feature {
        case .unlimitedItems, .cloudSync, .advancedReports,
             .multipleLocations, .receiptOCR, .themes, .widgets:
            return !isPremium
        case .barcodeScanning, .exportData:
            // These features have limited free tier access
            return false
        }
    }
    
    // MARK: - Private Methods
    
    private func loadPremiumStatus() {
        isPremium = dependencies.userDefaults.bool(forKey: "isPremium")
    }
    
    private func savePremiumStatus(_ status: Bool) {
        dependencies.userDefaults.set(status, forKey: "isPremium")
        isPremium = status
    }
    
    private func checkSubscriptionStatus() {
        Task {
            let hasSubscription = await dependencies.purchaseService.hasActiveSubscription()
            await MainActor.run {
                savePremiumStatus(hasSubscription)
            }
        }
    }
}

// MARK: - Errors

enum PremiumError: LocalizedError {
    case noProductsAvailable
    case purchaseFailed
    
    var errorDescription: String? {
        switch self {
        case .noProductsAvailable:
            return "No subscription products available"
        case .purchaseFailed:
            return "Purchase failed. Please try again."
        }
    }
}