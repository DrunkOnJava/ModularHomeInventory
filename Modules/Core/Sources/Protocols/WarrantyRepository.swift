//
//  WarrantyRepository.swift
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
//  Dependencies: Foundation, Combine
//  Testing: Modules/Core/Tests/CoreTests/WarrantyRepositoryTests.swift
//
//  Description: Repository protocol for warranty management with expiration tracking and reactive updates
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation
import Combine

/// Repository protocol for managing warranties
/// Swift 5.9 - No Swift 6 features
public protocol WarrantyRepository: Repository {
    /// Fetch all warranties
    func fetchAll() async throws -> [Warranty]
    
    /// Fetch warranty by ID
    func fetch(by id: UUID) async throws -> Warranty?
    
    /// Fetch warranties for a specific item
    func fetchWarranties(for itemId: UUID) async throws -> [Warranty]
    
    /// Fetch expiring warranties within specified days
    func fetchExpiring(within days: Int) async throws -> [Warranty]
    
    /// Fetch expired warranties
    func fetchExpired() async throws -> [Warranty]
    
    /// Save warranty
    func save(_ warranty: Warranty) async throws
    
    /// Delete warranty
    func delete(_ warranty: Warranty) async throws
    
    /// Publisher for warranty changes
    var warrantiesPublisher: AnyPublisher<[Warranty], Never> { get }
}

// MARK: - Default implementations

public extension WarrantyRepository {
    func fetchExpiring(within days: Int) async throws -> [Warranty] {
        let allWarranties = try await fetchAll()
        let futureDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        
        return allWarranties.filter { warranty in
            warranty.endDate > Date() && warranty.endDate <= futureDate
        }
    }
    
    func fetchExpired() async throws -> [Warranty] {
        let allWarranties = try await fetchAll()
        return allWarranties.filter { $0.endDate < Date() }
    }
}