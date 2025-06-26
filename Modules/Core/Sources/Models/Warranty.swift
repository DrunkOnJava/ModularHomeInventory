//
//  Warranty.swift
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
//  Testing: Modules/Core/Tests/CoreTests/WarrantyTests.swift
//
//  Description: Warranty model with comprehensive coverage tracking and provider information
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation

/// Warranty information for an item
/// Swift 5.9 - No Swift 6 features
public struct Warranty: Identifiable, Codable, Equatable {
    public let id: UUID
    public var itemId: UUID
    public var type: WarrantyType
    public var provider: String
    public var startDate: Date
    public var endDate: Date
    public var coverageDetails: String?
    public var registrationNumber: String?
    public var phoneNumber: String?
    public var email: String?
    public var website: String?
    public var documentIds: [UUID]
    public var notes: String?
    public var isExtended: Bool
    public var cost: Decimal?
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        itemId: UUID,
        type: WarrantyType = .manufacturer,
        provider: String,
        startDate: Date,
        endDate: Date,
        coverageDetails: String? = nil,
        registrationNumber: String? = nil,
        phoneNumber: String? = nil,
        email: String? = nil,
        website: String? = nil,
        documentIds: [UUID] = [],
        notes: String? = nil,
        isExtended: Bool = false,
        cost: Decimal? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.itemId = itemId
        self.type = type
        self.provider = provider
        self.startDate = startDate
        self.endDate = endDate
        self.coverageDetails = coverageDetails
        self.registrationNumber = registrationNumber
        self.phoneNumber = phoneNumber
        self.email = email
        self.website = website
        self.documentIds = documentIds
        self.notes = notes
        self.isExtended = isExtended
        self.cost = cost
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Warranty Type

public enum WarrantyType: String, Codable, CaseIterable {
    case manufacturer = "manufacturer"
    case retailer = "retailer"
    case extended = "extended"
    case protection = "protection"
    case service = "service"
    case insurance = "insurance"
    
    public var displayName: String {
        switch self {
        case .manufacturer: return "Manufacturer Warranty"
        case .retailer: return "Retailer Warranty"
        case .extended: return "Extended Warranty"
        case .protection: return "Protection Plan"
        case .service: return "Service Contract"
        case .insurance: return "Insurance"
        }
    }
    
    public var icon: String {
        switch self {
        case .manufacturer: return "wrench.and.screwdriver"
        case .retailer: return "storefront"
        case .extended: return "calendar.badge.plus"
        case .protection: return "shield"
        case .service: return "gearshape.2"
        case .insurance: return "umbrella"
        }
    }
}

// MARK: - Warranty Status

public extension Warranty {
    enum Status: Equatable {
        case active
        case expiringSoon(daysRemaining: Int)
        case expired
        
        public var displayName: String {
            switch self {
            case .active: return "Active"
            case .expiringSoon(let days): return "Expiring in \(days) days"
            case .expired: return "Expired"
            }
        }
        
        public var color: String {
            switch self {
            case .active: return "green"
            case .expiringSoon: return "orange"
            case .expired: return "red"
            }
        }
        
        public var icon: String {
            switch self {
            case .active: return "checkmark.circle.fill"
            case .expiringSoon: return "exclamationmark.triangle.fill"
            case .expired: return "xmark.circle.fill"
            }
        }
    }
    
    var status: Status {
        let now = Date()
        let daysRemaining = Calendar.current.dateComponents([.day], from: now, to: endDate).day ?? 0
        
        if endDate < now {
            return .expired
        } else if daysRemaining <= 30 {
            return .expiringSoon(daysRemaining: daysRemaining)
        } else {
            return .active
        }
    }
    
    var daysRemaining: Int {
        max(0, Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0)
    }
    
    var progress: Double {
        let total = startDate.distance(to: endDate)
        let elapsed = startDate.distance(to: min(Date(), endDate))
        return total > 0 ? elapsed / total : 1.0
    }
}

// MARK: - Common Warranty Providers

public struct WarrantyProvider {
    public let name: String
    public let phoneNumber: String?
    public let website: String?
    public let email: String?
    
    public static let commonProviders = [
        WarrantyProvider(
            name: "AppleCare",
            phoneNumber: "1-800-275-2273",
            website: "https://support.apple.com",
            email: nil
        ),
        WarrantyProvider(
            name: "Samsung Care",
            phoneNumber: "1-800-726-7864",
            website: "https://www.samsung.com/support",
            email: nil
        ),
        WarrantyProvider(
            name: "Best Buy Geek Squad",
            phoneNumber: "1-800-433-5778",
            website: "https://www.bestbuy.com/geeksquad",
            email: nil
        ),
        WarrantyProvider(
            name: "SquareTrade",
            phoneNumber: "1-877-927-7268",
            website: "https://www.squaretrade.com",
            email: nil
        ),
        WarrantyProvider(
            name: "Asurion",
            phoneNumber: "1-866-551-5924",
            website: "https://www.asurion.com",
            email: nil
        ),
        WarrantyProvider(
            name: "Amazon Protection Plan",
            phoneNumber: "1-866-216-1072",
            website: "https://www.amazon.com/protectionplans",
            email: nil
        )
    ]
}