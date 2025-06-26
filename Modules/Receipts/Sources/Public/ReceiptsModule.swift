//
//  ReceiptsModule.swift
//  Receipts Module
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
//  Module: Receipts
//  Dependencies: SwiftUI, Core
//  Testing: ReceiptsTests/ReceiptsModuleTests.swift
//
//  Description: Main receipts module implementation with view factory methods
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core

/// Main implementation of the Receipts module
/// Swift 5.9 - No Swift 6 features
@MainActor
public final class ReceiptsModule: ReceiptsModuleAPI {
    private let dependencies: ReceiptsModuleDependencies
    
    public init(dependencies: ReceiptsModuleDependencies) {
        self.dependencies = dependencies
    }
    
    public func makeReceiptsListView() -> AnyView {
        let viewModel = ReceiptsListViewModel(
            receiptRepository: dependencies.receiptRepository,
            itemRepository: dependencies.itemRepository,
            ocrService: dependencies.ocrService
        )
        return AnyView(ReceiptsListView(viewModel: viewModel))
    }
    
    public func makeReceiptDetailView(receipt: Receipt) -> AnyView {
        let viewModel = ReceiptDetailViewModel(
            receipt: receipt,
            receiptRepository: dependencies.receiptRepository,
            itemRepository: dependencies.itemRepository
        )
        return AnyView(ReceiptDetailView(viewModel: viewModel))
    }
    
    public func makeReceiptImportView(completion: @escaping (Receipt) -> Void) -> AnyView {
        let viewModel = ReceiptImportViewModel(
            emailService: dependencies.emailService,
            ocrService: dependencies.ocrService,
            completion: completion
        )
        return AnyView(ReceiptImportView(viewModel: viewModel))
    }
    
    public func makeReceiptPreviewView(parsedData: ParsedReceiptData, completion: @escaping (Receipt) -> Void) -> AnyView {
        let viewModel = ReceiptPreviewViewModel(
            parsedData: parsedData,
            receiptRepository: dependencies.receiptRepository,
            itemRepository: dependencies.itemRepository,
            completion: completion
        )
        return AnyView(ReceiptPreviewView(viewModel: viewModel))
    }
}