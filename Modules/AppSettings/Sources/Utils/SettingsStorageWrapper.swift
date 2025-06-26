//
//  SettingsStorageWrapper.swift
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
//  Dependencies: SwiftUI, Core
//  Testing: Modules/AppSettings/Tests/Utils/SettingsStorageWrapperTests.swift
//
//  Description: Observable wrapper for SettingsStorageProtocol providing SwiftUI-compatible binding operations for different data types
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

//
//  SettingsStorageWrapper.swift
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
//  Dependencies: SwiftUI, Core
//  Testing: Modules/AppSettings/Tests/AppSettingsTests/SettingsStorageWrapperTests.swift
//
//  Description: ObservableObject wrapper for SettingsStorageProtocol providing SwiftUI compatibility
//  with reactive updates for string, boolean, integer, and double value operations
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core

/// Observable wrapper for SettingsStorageProtocol to work with SwiftUI
@MainActor
public class SettingsStorageWrapper: ObservableObject {
    let storage: any SettingsStorageProtocol
    @Published private var updateTrigger = false
    
    public init(storage: any SettingsStorageProtocol) {
        self.storage = storage
    }
    
    // MARK: - String Operations
    
    public func string(forKey key: SettingsKey) -> String? {
        storage.string(forKey: key)
    }
    
    public func set(_ value: String?, forKey key: SettingsKey) {
        storage.set(value, forKey: key)
        updateTrigger.toggle()
    }
    
    // MARK: - Bool Operations
    
    public func bool(forKey key: SettingsKey) -> Bool? {
        storage.bool(forKey: key)
    }
    
    public func set(_ value: Bool, forKey key: SettingsKey) {
        storage.set(value, forKey: key)
        updateTrigger.toggle()
    }
    
    // MARK: - Integer Operations
    
    public func integer(forKey key: SettingsKey) -> Int? {
        storage.integer(forKey: key)
    }
    
    public func set(_ value: Int, forKey key: SettingsKey) {
        storage.set(value, forKey: key)
        updateTrigger.toggle()
    }
    
    // MARK: - Double Operations
    
    public func double(forKey key: SettingsKey) -> Double? {
        storage.double(forKey: key)
    }
    
    public func set(_ value: Double, forKey key: SettingsKey) {
        storage.set(value, forKey: key)
        updateTrigger.toggle()
    }
}