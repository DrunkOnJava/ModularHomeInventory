//
//  ScannerModuleAPI.swift
//  HomeInventoryModular
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
//  Module: BarcodeScanner
//  Dependencies: SwiftUI, Core, UIKit
//  Testing: Modules/BarcodeScanner/Tests/ScannerTests/ScannerModuleAPITests.swift
//
//  Description: Public API protocol for the Scanner module defining factory methods
//               for creating scanner views and managing scan results
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

//
//  ScannerModuleAPI.swift
//  HomeInventoryModular
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
//  Module: BarcodeScanner
//  Dependencies: Core, SharedUI, AppSettings
//  Testing: Modules/BarcodeScanner/Tests/ScannerTests/ScannerModuleTests.swift
//
//  Description: Public API protocol for the BarcodeScanner module defining the interface for
//  creating scanner views, managing scan results, and handling module dependencies. This file
//  establishes the contract between the BarcodeScanner module and consuming modules.
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core
#if canImport(UIKit)
import UIKit
#endif

/// Public API for the Scanner module
/// Swift 5.9 - No Swift 6 features
@MainActor
public protocol ScannerModuleAPI: AnyObject {
    /// Creates the main scanner view
    func makeScannerView() -> AnyView
    
    /// Creates a barcode scanner view with completion handler
    func makeBarcodeScannerView(completion: @escaping (String) -> Void) -> AnyView
    
    /// Creates a batch scanner view for scanning multiple items
    func makeBatchScannerView(completion: @escaping ([Item]) -> Void) -> AnyView
    
    /// Creates a document scanner view
    func makeDocumentScannerView(completion: @escaping (UIImage) -> Void) -> AnyView
    
    /// Creates the scan history view
    func makeScanHistoryView() -> AnyView
    
    /// Creates the offline scan queue view
    func makeOfflineScanQueueView() -> AnyView
    
    /// Get the offline scan service for monitoring queue status
    var offlineScanService: OfflineScanService { get }
}

/// Scanner result types
public enum ScanResult {
    case barcode(String)
    case document(UIImage)
    case error(Error)
}

/// Dependencies required by the Scanner module
public struct ScannerModuleDependencies {
    public let itemRepository: any ItemRepository
    public let itemTemplateRepository: any ItemTemplateRepository
    public let settingsStorage: SettingsStorageProtocol
    public let scanHistoryRepository: any ScanHistoryRepository
    public let offlineScanQueueRepository: any OfflineScanQueueRepository
    public let barcodeLookupService: BarcodeLookupService
    public let networkMonitor: NetworkMonitor
    
    public init(
        itemRepository: any ItemRepository,
        itemTemplateRepository: any ItemTemplateRepository,
        settingsStorage: SettingsStorageProtocol,
        scanHistoryRepository: any ScanHistoryRepository,
        offlineScanQueueRepository: any OfflineScanQueueRepository,
        barcodeLookupService: BarcodeLookupService,
        networkMonitor: NetworkMonitor
    ) {
        self.itemRepository = itemRepository
        self.itemTemplateRepository = itemTemplateRepository
        self.settingsStorage = settingsStorage
        self.scanHistoryRepository = scanHistoryRepository
        self.offlineScanQueueRepository = offlineScanQueueRepository
        self.barcodeLookupService = barcodeLookupService
        self.networkMonitor = networkMonitor
    }
}