//
//  ItemCategory.swift
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
//  Testing: Modules/Core/Tests/CoreTests/ItemCategoryTests.swift
//
//  Description: Legacy enum for item categories (deprecated in favor of ItemCategoryModel)
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation

/// Categories for organizing items
public enum ItemCategory: String, Codable, CaseIterable, Hashable {
    case electronics = "Electronics"
    case furniture = "Furniture"
    case clothing = "Clothing"
    case books = "Books"
    case kitchen = "Kitchen"
    case tools = "Tools"
    case sports = "Sports"
    case toys = "Toys"
    case jewelry = "Jewelry"
    case art = "Art"
    case collectibles = "Collectibles"
    case appliances = "Appliances"
    case outdoor = "Outdoor"
    case office = "Office"
    case automotive = "Automotive"
    case health = "Health"
    case beauty = "Beauty"
    case home = "Home"
    case garden = "Garden"
    case other = "Other"
    
    public var icon: String {
        switch self {
        case .electronics: return "tv"
        case .furniture: return "chair"
        case .clothing: return "tshirt"
        case .books: return "book"
        case .kitchen: return "fork.knife"
        case .tools: return "wrench"
        case .sports: return "sportscourt"
        case .toys: return "teddybear"
        case .jewelry: return "sparkles"
        case .art: return "paintpalette"
        case .collectibles: return "star"
        case .appliances: return "washer"
        case .outdoor: return "tent"
        case .office: return "paperclip"
        case .automotive: return "car"
        case .health: return "heart"
        case .beauty: return "eyebrow"
        case .home: return "house"
        case .garden: return "leaf"
        case .other: return "square.grid.2x2"
        }
    }
    
    public var displayName: String {
        self.rawValue
    }
    
    public var color: String {
        switch self {
        case .electronics: return "#3B82F6"
        case .furniture: return "#92400E"
        case .clothing: return "#9333EA"
        case .books: return "#F97316"
        case .kitchen: return "#EF4444"
        case .tools: return "#6B7280"
        case .sports: return "#10B981"
        case .toys: return "#EC4899"
        case .jewelry: return "#F59E0B"
        case .art: return "#6366F1"
        case .collectibles: return "#14B8A6"
        case .appliances: return "#06B6D4"
        case .outdoor: return "#059669"
        case .office: return "#1E3A8A"
        case .automotive: return "#7F1D1D"
        case .health: return "#10B981"
        case .beauty: return "#F43F5E"
        case .home: return "#D97706"
        case .garden: return "#84CC16"
        case .other: return "#6B7280"
        }
    }
}