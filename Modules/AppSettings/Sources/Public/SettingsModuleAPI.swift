//
//  SettingsModuleAPI.swift
//  AppSettings Module
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
//  Module: AppSettings
//  Dependencies: SwiftUI, Core, CoreGraphics
//  Testing: Modules/AppSettings/Tests/SettingsModuleAPITests.swift
//
//  Description: Public API definitions for the settings module including protocols, data structures, and dependency injection types
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

//
//  SettingsModuleAPI.swift
//  AppSettings Module
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
//  Module: AppSettings
//  Dependencies: SwiftUI, Core, CoreGraphics
//  Testing: Modules/AppSettings/Tests/AppSettingsTests/SettingsModuleAPITests.swift
//
//  Description: Public API protocol definitions, scanner sensitivity configuration,
//  app settings data model, and module dependencies structure for the AppSettings module
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core
import CoreGraphics

/// Public API for the Settings module
/// Swift 5.9 - No Swift 6 features
@MainActor
public protocol SettingsModuleAPI {
    /// Creates the main settings view
    func makeSettingsView() -> AnyView
    
    /// Creates the about view
    func makeAboutView() -> AnyView
}

/// Scanner sensitivity levels
public enum ScannerSensitivity: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium" 
    case high = "High"
    
    /// The scanning interval in seconds between scans
    public var scanInterval: Double {
        switch self {
        case .low: return 2.0
        case .medium: return 1.0
        case .high: return 0.5
        }
    }
    
    /// The metadata output rect of interest (focus area)
    public var focusAreaScale: CGFloat {
        switch self {
        case .low: return 0.8
        case .medium: return 0.7
        case .high: return 0.6
        }
    }
}

/// Settings values that can be configured
public struct AppSettings: Codable {
    public var notificationsEnabled: Bool
    public var darkModeEnabled: Bool
    public var biometricAuthEnabled: Bool
    public var defaultCurrency: String
    public var autoBackupEnabled: Bool
    public var offlineModeEnabled: Bool
    public var autoSyncOnWiFi: Bool
    public var scannerSoundEnabled: Bool
    public var scannerSensitivity: ScannerSensitivity
    public var continuousScanDelay: Double
    public var enabledBarcodeFormats: [String]  // Store as strings for Codable
    
    public init(
        notificationsEnabled: Bool = true,
        darkModeEnabled: Bool = false,
        biometricAuthEnabled: Bool = false,
        defaultCurrency: String = "USD",
        autoBackupEnabled: Bool = true,
        offlineModeEnabled: Bool = true,
        autoSyncOnWiFi: Bool = true,
        scannerSoundEnabled: Bool = true,
        scannerSensitivity: ScannerSensitivity = .medium,
        continuousScanDelay: Double = 1.0,
        enabledBarcodeFormats: [String]? = nil
    ) {
        self.notificationsEnabled = notificationsEnabled
        self.darkModeEnabled = darkModeEnabled
        self.biometricAuthEnabled = biometricAuthEnabled
        self.defaultCurrency = defaultCurrency
        self.autoBackupEnabled = autoBackupEnabled
        self.offlineModeEnabled = offlineModeEnabled
        self.autoSyncOnWiFi = autoSyncOnWiFi
        self.scannerSoundEnabled = scannerSoundEnabled
        self.scannerSensitivity = scannerSensitivity
        self.continuousScanDelay = continuousScanDelay
        // Default to common formats if not specified
        self.enabledBarcodeFormats = enabledBarcodeFormats ?? [
            "ean13", "ean8", "upce", "code128", "qr"
        ]
    }
}


/// Dependencies required by the Settings module
public struct SettingsModuleDependencies {
    public let settingsStorage: any SettingsStorageProtocol
    public let itemRepository: (any ItemRepository)?
    public let receiptRepository: (any ReceiptRepository)?
    public let locationRepository: (any LocationRepository)?
    
    public init(
        settingsStorage: any SettingsStorageProtocol,
        itemRepository: (any ItemRepository)? = nil,
        receiptRepository: (any ReceiptRepository)? = nil,
        locationRepository: (any LocationRepository)? = nil
    ) {
        self.settingsStorage = settingsStorage
        self.itemRepository = itemRepository
        self.receiptRepository = receiptRepository
        self.locationRepository = locationRepository
    }
}