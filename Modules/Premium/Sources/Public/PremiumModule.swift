//
//  PremiumModule.swift
//  Premium Module
//
//  Apple Configuration:
//  Bundle Identifier: com.homeinventory.app
//  Display Name: Home Inventory
//  Version: 1.0.5
//  Build: 5
//  Deployment Target: iOS 17.0
//  Supported Devices: iPhone & iPad
//  Team ID: 2VXBQV4XC9
//
//  Makefile Configuration:
//  Default Simulator: iPhone 16 Pro Max (DD192264-DFAA-4582-B2FE-D6FC444C9DDF)
//  iPad Simulator: iPad Pro 13-inch (M4) (CE6D038C-840B-4BDB-AA63-D61FA0755C4A)
//  App Bundle ID: com.homeinventory.app
//  Build Path: build/Build/Products/Debug-iphonesimulator/
//
//  Google Sign-In Configuration:
//  Client ID: 316432172622-6huvbn752v0ep68jkfdftrh8fgpesikg.apps.googleusercontent.com
//  URL Scheme: com.googleusercontent.apps.316432172622-6huvbn752v0ep68jkfdftrh8fgpesikg
//  OAuth Scope: https://www.googleapis.com/auth/gmail.readonly
//  Config Files: GoogleSignIn-Info.plist (project root), GoogleServices.plist (Gmail module)
//
//  Key Commands:
//  Build and run: make build run
//  Fast build (skip module prebuild): make build-fast run
//  iPad build and run: make build-ipad run-ipad
//  Clean build: make clean build run
//  Run tests: make test
//
//  Project Structure:
//  Main Target: HomeInventoryModular
//  Test Targets: HomeInventoryModularTests, HomeInventoryModularUITests
//  Swift Version: 5.9 (DO NOT upgrade to Swift 6)
//  Minimum iOS Version: 17.0
//
//  Architecture: Modular SPM packages with local package dependencies
//  Repository: https://github.com/DrunkOnJava/ModularHomeInventory.git
//  Module: Premium
//  Dependencies: SwiftUI, Core, Combine
//  Testing: Modules/Premium/Tests/PremiumTests.swift
//
//  Description: Main implementation of the Premium module protocol.
//               Manages subscription state, feature gating, and integrates with
//               in-app purchase services for premium functionality.
//
//  Created by Griffin Long on June 26, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

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