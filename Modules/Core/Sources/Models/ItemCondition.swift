//
//  ItemCondition.swift
//  Core
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
//  Module: Core
//  Dependencies: Foundation
//  Testing: Modules/Core/Tests/CoreTests/ItemConditionTests.swift
//
//  Description: Enumeration defining condition states for inventory items (new, used, damaged, etc.)
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation

/// Condition states for items
public enum ItemCondition: String, Codable, CaseIterable {
    case new = "New"
    case likeNew = "Like New"
    case excellent = "Excellent"
    case veryGood = "Very Good"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
    case forParts = "For Parts"
    
    public var displayName: String {
        self.rawValue
    }
    
    public var icon: String {
        switch self {
        case .new: return "sparkles"
        case .likeNew: return "star.fill"
        case .excellent: return "star"
        case .veryGood: return "hand.thumbsup.fill"
        case .good: return "hand.thumbsup"
        case .fair: return "minus.circle"
        case .poor: return "exclamationmark.triangle"
        case .forParts: return "wrench.and.screwdriver"
        }
    }
    
    public var colorName: String {
        switch self {
        case .new, .likeNew: return "green"
        case .excellent, .veryGood: return "blue"
        case .good: return "teal"
        case .fair: return "orange"
        case .poor, .forParts: return "red"
        }
    }
}