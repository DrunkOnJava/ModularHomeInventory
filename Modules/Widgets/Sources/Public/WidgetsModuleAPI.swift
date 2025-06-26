//
//  WidgetsModuleAPI.swift
//  Widgets Module
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
//  Module: Widgets
//  Dependencies: Foundation, Core, WidgetKit
//  Testing: Modules/Widgets/Tests/WidgetsTests.swift
//
//  Description: Public API protocol and data structures for the Widgets module.
//               Defines the interface for iOS home screen widgets including inventory
//               stats, warranty tracking, spending summaries, and recent items.
//
//  Created by Griffin Long on June 26, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation
import Core

/// Public API for the Widgets module
/// Swift 5.9 - No Swift 6 features
public protocol WidgetsModuleAPI {
    // Widget module functionality will be added here
}

/// Dependencies required by the Widgets module
public struct WidgetsModuleDependencies {
    public let itemRepository: any ItemRepository
    public let receiptRepository: any ReceiptRepository
    public let warrantyRepository: any WarrantyRepository
    public let budgetRepository: (any BudgetRepository)?
    
    public init(
        itemRepository: any ItemRepository,
        receiptRepository: any ReceiptRepository,
        warrantyRepository: any WarrantyRepository,
        budgetRepository: (any BudgetRepository)? = nil
    ) {
        self.itemRepository = itemRepository
        self.receiptRepository = receiptRepository
        self.warrantyRepository = warrantyRepository
        self.budgetRepository = budgetRepository
    }
}