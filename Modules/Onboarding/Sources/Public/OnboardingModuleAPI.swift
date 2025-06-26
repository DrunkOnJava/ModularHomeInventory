//
//  OnboardingModuleAPI.swift
//  Onboarding Module
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
//  Module: Onboarding
//  Dependencies: SwiftUI, Core
//  Testing: Modules/Onboarding/Tests/OnboardingTests.swift
//
//  Description: Public API protocol and data structures for the Onboarding module.
//               Defines the interface for onboarding status management, view creation,
//               and predefined onboarding steps for first-time user experience.
//
//  Created by Griffin Long on June 26, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core

/// Public API for the Onboarding module
/// Swift 5.9 - No Swift 6 features
@MainActor
public protocol OnboardingModuleAPI {
    /// Check if onboarding has been completed
    var isOnboardingCompleted: Bool { get }
    
    /// Creates the onboarding flow view
    func makeOnboardingView(completion: @escaping () -> Void) -> AnyView
    
    /// Mark onboarding as completed
    func completeOnboarding()
    
    /// Reset onboarding (useful for testing or user request)
    func resetOnboarding()
}

/// Dependencies required by the Onboarding module
public struct OnboardingModuleDependencies {
    public let userDefaults: UserDefaults
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
}

/// Onboarding step information
public struct OnboardingStep {
    public let title: String
    public let description: String
    public let imageName: String
    public let buttonTitle: String
    
    public init(
        title: String,
        description: String,
        imageName: String,
        buttonTitle: String = "Next"
    ) {
        self.title = title
        self.description = description
        self.imageName = imageName
        self.buttonTitle = buttonTitle
    }
}

// MARK: - Default Onboarding Steps

public extension OnboardingStep {
    static let welcome = OnboardingStep(
        title: "Welcome to Home Inventory",
        description: "Keep track of all your belongings in one place. Organize, manage, and protect what matters most.",
        imageName: "shippingbox.fill"
    )
    
    static let organize = OnboardingStep(
        title: "Organize Everything",
        description: "Create categories, add locations, and keep your items perfectly organized with custom tags and notes.",
        imageName: "square.grid.3x3.fill"
    )
    
    static let scan = OnboardingStep(
        title: "Quick Barcode Scanning",
        description: "Add items instantly by scanning barcodes. Get product details automatically filled in.",
        imageName: "barcode.viewfinder"
    )
    
    static let receipts = OnboardingStep(
        title: "Smart Receipt Management",
        description: "Import receipts from emails or scan them. Track warranties and purchase history effortlessly.",
        imageName: "doc.text.viewfinder"
    )
    
    static let protect = OnboardingStep(
        title: "Protect Your Data",
        description: "Secure cloud backup ensures your inventory is safe. Access from any device, anytime.",
        imageName: "lock.icloud.fill",
        buttonTitle: "Get Started"
    )
    
    static let allSteps: [OnboardingStep] = [
        .welcome,
        .organize,
        .scan,
        .receipts,
        .protect
    ]
}