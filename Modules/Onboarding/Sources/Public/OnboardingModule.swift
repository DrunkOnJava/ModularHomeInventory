//
//  OnboardingModule.swift
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
//  Description: Main implementation of the Onboarding module protocol.
//               Manages onboarding completion state using UserDefaults and provides
//               view creation for the onboarding flow.
//
//  Created by Griffin Long on June 26, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core

/// Main implementation of the Onboarding module
/// Swift 5.9 - No Swift 6 features
@MainActor
public final class OnboardingModule: OnboardingModuleAPI {
    private let dependencies: OnboardingModuleDependencies
    private let onboardingKey = "hasCompletedOnboarding"
    
    public var isOnboardingCompleted: Bool {
        dependencies.userDefaults.bool(forKey: onboardingKey)
    }
    
    public init(dependencies: OnboardingModuleDependencies) {
        self.dependencies = dependencies
    }
    
    public func makeOnboardingView(completion: @escaping () -> Void) -> AnyView {
        AnyView(
            OnboardingView(
                steps: OnboardingStep.allSteps,
                completion: { [weak self] in
                    self?.completeOnboarding()
                    completion()
                }
            )
        )
    }
    
    public func completeOnboarding() {
        dependencies.userDefaults.set(true, forKey: onboardingKey)
    }
    
    public func resetOnboarding() {
        dependencies.userDefaults.set(false, forKey: onboardingKey)
    }
}