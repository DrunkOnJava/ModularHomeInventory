//
//  ConflictResolutionService.swift
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
//  Module: Sync
//  Dependencies: Foundation, Core, Combine, UIKit
//  Testing: Modules/Sync/Tests/SyncTests/ConflictResolutionServiceTests.swift
//
//  Description: Service for detecting and resolving sync conflicts with multiple resolution strategies
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation
import Core
import Combine
import UIKit

/// Service for detecting and resolving sync conflicts
/// Swift 5.9 - No Swift 6 features
@MainActor
public final class ConflictResolutionService: ObservableObject {
    
    // Published properties
    @Published public var activeConflicts: [SyncConflict] = []
    @Published public var isResolving = false
    @Published public var lastResolutionDate: Date?
    
    // Dependencies
    private let itemRepository: any ItemRepository
    private let receiptRepository: any ReceiptRepository
    private let locationRepository: any LocationRepository
    
    // Conflict detection
    private var conflictHistory: [UUID: ConflictResolutionResult] = [:]
    
    public init(
        itemRepository: any ItemRepository,
        receiptRepository: any ReceiptRepository,
        locationRepository: any LocationRepository
    ) {
        self.itemRepository = itemRepository
        self.receiptRepository = receiptRepository
        self.locationRepository = locationRepository
    }
    
    // MARK: - Public Methods
    
    /// Detect conflicts between local and remote data
    public func detectConflicts(
        localData: [String: [Any]],
        remoteData: [String: [Any]]
    ) async throws -> [SyncConflict] {
        var conflicts: [SyncConflict] = []
        
        // Check items
        if let localItems = localData["items"] as? [Item],
           let remoteItems = remoteData["items"] as? [Item] {
            let itemConflicts = await detectItemConflicts(
                localItems: localItems,
                remoteItems: remoteItems
            )
            conflicts.append(contentsOf: itemConflicts)
        }
        
        // Check receipts
        if let localReceipts = localData["receipts"] as? [Receipt],
           let remoteReceipts = remoteData["receipts"] as? [Receipt] {
            let receiptConflicts = await detectReceiptConflicts(
                localReceipts: localReceipts,
                remoteReceipts: remoteReceipts
            )
            conflicts.append(contentsOf: receiptConflicts)
        }
        
        // Check locations
        if let localLocations = localData["locations"] as? [Location],
           let remoteLocations = remoteData["locations"] as? [Location] {
            let locationConflicts = await detectLocationConflicts(
                localLocations: localLocations,
                remoteLocations: remoteLocations
            )
            conflicts.append(contentsOf: locationConflicts)
        }
        
        activeConflicts = conflicts
        return conflicts
    }
    
    /// Resolve a single conflict
    public func resolveConflict(
        _ conflict: SyncConflict,
        resolution: ConflictResolution
    ) async throws -> ConflictResolutionResult {
        isResolving = true
        defer { isResolving = false }
        
        let resolvedData: Data
        
        switch resolution {
        case .keepLocal:
            resolvedData = conflict.localVersion.data
            
        case .keepRemote:
            resolvedData = conflict.remoteVersion.data
            
        case .merge(let strategy):
            resolvedData = try await mergeConflict(conflict, strategy: strategy)
            
        case .custom(let data):
            resolvedData = data
        }
        
        // Apply resolution
        try await applyResolution(
            conflict: conflict,
            resolvedData: resolvedData
        )
        
        let result = ConflictResolutionResult(
            conflictId: conflict.id,
            resolution: resolution,
            resolvedData: resolvedData
        )
        
        // Store resolution history
        conflictHistory[conflict.id] = result
        
        // Remove from active conflicts
        activeConflicts.removeAll { $0.id == conflict.id }
        lastResolutionDate = Date()
        
        return result
    }
    
    /// Resolve all conflicts with a strategy
    public func resolveAllConflicts(
        strategy: ConflictResolution
    ) async throws -> [ConflictResolutionResult] {
        var results: [ConflictResolutionResult] = []
        
        for conflict in activeConflicts {
            let result = try await resolveConflict(conflict, resolution: strategy)
            results.append(result)
        }
        
        return results
    }
    
    /// Get conflict details for display
    public func getConflictDetails(_ conflict: SyncConflict) async throws -> ConflictDetails {
        switch conflict.entityType {
        case .item:
            return try await getItemConflictDetails(conflict)
        case .receipt:
            return try await getReceiptConflictDetails(conflict)
        case .location:
            return try await getLocationConflictDetails(conflict)
        default:
            throw ConflictError.unsupportedEntityType
        }
    }
    
    // MARK: - Private Methods
    
    private func detectItemConflicts(
        localItems: [Item],
        remoteItems: [Item]
    ) async -> [SyncConflict] {
        var conflicts: [SyncConflict] = []
        
        // Create lookup dictionaries
        let localDict = Dictionary(uniqueKeysWithValues: localItems.map { ($0.id, $0) })
        let remoteDict = Dictionary(uniqueKeysWithValues: remoteItems.map { ($0.id, $0) })
        
        // Check for update conflicts
        for (id, localItem) in localDict {
            if let remoteItem = remoteDict[id] {
                if localItem.updatedAt != remoteItem.updatedAt {
                    // Both modified - create conflict
                    let conflict = createItemConflict(
                        localItem: localItem,
                        remoteItem: remoteItem,
                        type: .update
                    )
                    conflicts.append(conflict)
                }
            }
        }
        
        return conflicts
    }
    
    private func detectReceiptConflicts(
        localReceipts: [Receipt],
        remoteReceipts: [Receipt]
    ) async -> [SyncConflict] {
        var conflicts: [SyncConflict] = []
        
        let localDict = Dictionary(uniqueKeysWithValues: localReceipts.map { ($0.id, $0) })
        let remoteDict = Dictionary(uniqueKeysWithValues: remoteReceipts.map { ($0.id, $0) })
        
        for (id, localReceipt) in localDict {
            if let remoteReceipt = remoteDict[id] {
                if localReceipt.updatedAt != remoteReceipt.updatedAt {
                    let conflict = createReceiptConflict(
                        localReceipt: localReceipt,
                        remoteReceipt: remoteReceipt,
                        type: .update
                    )
                    conflicts.append(conflict)
                }
            }
        }
        
        return conflicts
    }
    
    private func detectLocationConflicts(
        localLocations: [Location],
        remoteLocations: [Location]
    ) async -> [SyncConflict] {
        var conflicts: [SyncConflict] = []
        
        let localDict = Dictionary(uniqueKeysWithValues: localLocations.map { ($0.id, $0) })
        let remoteDict = Dictionary(uniqueKeysWithValues: remoteLocations.map { ($0.id, $0) })
        
        for (id, localLocation) in localDict {
            if let remoteLocation = remoteDict[id] {
                if localLocation.updatedAt != remoteLocation.updatedAt {
                    let conflict = createLocationConflict(
                        localLocation: localLocation,
                        remoteLocation: remoteLocation,
                        type: .update
                    )
                    conflicts.append(conflict)
                }
            }
        }
        
        return conflicts
    }
    
    private func createItemConflict(
        localItem: Item,
        remoteItem: Item,
        type: SyncConflict.ConflictType
    ) -> SyncConflict {
        let encoder = JSONEncoder()
        
        let localData = (try? encoder.encode(localItem)) ?? Data()
        let remoteData = (try? encoder.encode(remoteItem)) ?? Data()
        
        let localChanges = detectItemChanges(from: localItem, to: remoteItem)
        let remoteChanges = detectItemChanges(from: remoteItem, to: localItem)
        
        let localVersion = ConflictVersion(
            data: localData,
            modifiedAt: localItem.updatedAt,
            deviceName: UIDevice.current.name,
            changes: localChanges
        )
        
        let remoteVersion = ConflictVersion(
            data: remoteData,
            modifiedAt: remoteItem.updatedAt,
            changes: remoteChanges
        )
        
        return SyncConflict(
            entityType: .item,
            entityId: localItem.id,
            localVersion: localVersion,
            remoteVersion: remoteVersion,
            conflictType: type
        )
    }
    
    private func createReceiptConflict(
        localReceipt: Receipt,
        remoteReceipt: Receipt,
        type: SyncConflict.ConflictType
    ) -> SyncConflict {
        let encoder = JSONEncoder()
        
        let localData = (try? encoder.encode(localReceipt)) ?? Data()
        let remoteData = (try? encoder.encode(remoteReceipt)) ?? Data()
        
        let localVersion = ConflictVersion(
            data: localData,
            modifiedAt: localReceipt.updatedAt,
            deviceName: UIDevice.current.name
        )
        
        let remoteVersion = ConflictVersion(
            data: remoteData,
            modifiedAt: remoteReceipt.updatedAt
        )
        
        return SyncConflict(
            entityType: .receipt,
            entityId: localReceipt.id,
            localVersion: localVersion,
            remoteVersion: remoteVersion,
            conflictType: type
        )
    }
    
    private func createLocationConflict(
        localLocation: Location,
        remoteLocation: Location,
        type: SyncConflict.ConflictType
    ) -> SyncConflict {
        let encoder = JSONEncoder()
        
        let localData = (try? encoder.encode(localLocation)) ?? Data()
        let remoteData = (try? encoder.encode(remoteLocation)) ?? Data()
        
        let localVersion = ConflictVersion(
            data: localData,
            modifiedAt: localLocation.updatedAt,
            deviceName: UIDevice.current.name
        )
        
        let remoteVersion = ConflictVersion(
            data: remoteData,
            modifiedAt: remoteLocation.updatedAt
        )
        
        return SyncConflict(
            entityType: .location,
            entityId: localLocation.id,
            localVersion: localVersion,
            remoteVersion: remoteVersion,
            conflictType: type
        )
    }
    
    private func detectItemChanges(from oldItem: Item, to newItem: Item) -> [FieldChange] {
        var changes: [FieldChange] = []
        
        if oldItem.name != newItem.name {
            changes.append(FieldChange(
                fieldName: "name",
                displayName: "Name",
                oldValue: oldItem.name,
                newValue: newItem.name,
                isConflicting: true
            ))
        }
        
        if oldItem.purchasePrice != newItem.purchasePrice {
            changes.append(FieldChange(
                fieldName: "purchasePrice",
                displayName: "Purchase Price",
                oldValue: oldItem.purchasePrice?.description,
                newValue: newItem.purchasePrice?.description,
                isConflicting: true
            ))
        }
        
        if oldItem.quantity != newItem.quantity {
            changes.append(FieldChange(
                fieldName: "quantity",
                displayName: "Quantity",
                oldValue: String(oldItem.quantity),
                newValue: String(newItem.quantity),
                isConflicting: true
            ))
        }
        
        if oldItem.locationId != newItem.locationId {
            changes.append(FieldChange(
                fieldName: "locationId",
                displayName: "Location",
                oldValue: oldItem.locationId?.uuidString,
                newValue: newItem.locationId?.uuidString,
                isConflicting: true
            ))
        }
        
        return changes
    }
    
    private func mergeConflict(
        _ conflict: SyncConflict,
        strategy: MergeStrategy
    ) async throws -> Data {
        switch strategy {
        case .latestWins:
            if conflict.localVersion.modifiedAt > conflict.remoteVersion.modifiedAt {
                return conflict.localVersion.data
            } else {
                return conflict.remoteVersion.data
            }
            
        case .localPriority:
            return conflict.localVersion.data
            
        case .remotePriority:
            return conflict.remoteVersion.data
            
        case .fieldLevel(let resolutions):
            return try await mergeFieldLevel(conflict, resolutions: resolutions)
        }
    }
    
    private func mergeFieldLevel(
        _ conflict: SyncConflict,
        resolutions: [FieldResolution]
    ) async throws -> Data {
        // Implementation depends on entity type
        switch conflict.entityType {
        case .item:
            return try await mergeItemFields(conflict, resolutions: resolutions)
        default:
            throw ConflictError.mergeNotSupported
        }
    }
    
    private func mergeItemFields(
        _ conflict: SyncConflict,
        resolutions: [FieldResolution]
    ) async throws -> Data {
        let decoder = JSONDecoder()
        let encoder = JSONEncoder()
        
        guard var localItem = try? decoder.decode(Item.self, from: conflict.localVersion.data),
              let remoteItem = try? decoder.decode(Item.self, from: conflict.remoteVersion.data) else {
            throw ConflictError.decodingFailed
        }
        
        // Apply field resolutions
        for resolution in resolutions {
            switch resolution.fieldName {
            case "name":
                switch resolution.resolution {
                case .useLocal:
                    break // Keep local
                case .useRemote:
                    localItem = Item(
                        id: localItem.id,
                        name: remoteItem.name,
                        brand: localItem.brand,
                        model: localItem.model,
                        category: localItem.category,
                        condition: localItem.condition,
                        quantity: localItem.quantity,
                        value: localItem.value,
                        purchasePrice: localItem.purchasePrice,
                        purchaseDate: localItem.purchaseDate,
                        notes: localItem.notes,
                        barcode: localItem.barcode,
                        serialNumber: localItem.serialNumber,
                        tags: localItem.tags,
                        imageIds: localItem.imageIds,
                        locationId: localItem.locationId,
                        warrantyId: localItem.warrantyId,
                        createdAt: localItem.createdAt,
                        updatedAt: Date()
                    )
                default:
                    break
                }
            default:
                break
            }
        }
        
        return try encoder.encode(localItem)
    }
    
    private func applyResolution(
        conflict: SyncConflict,
        resolvedData: Data
    ) async throws {
        switch conflict.entityType {
        case .item:
            let decoder = JSONDecoder()
            if let item = try? decoder.decode(Item.self, from: resolvedData) {
                try await itemRepository.save(item)
            }
        case .receipt:
            let decoder = JSONDecoder()
            if let receipt = try? decoder.decode(Receipt.self, from: resolvedData) {
                try await receiptRepository.save(receipt)
            }
        case .location:
            let decoder = JSONDecoder()
            if let location = try? decoder.decode(Location.self, from: resolvedData) {
                try await locationRepository.save(location)
            }
        default:
            throw ConflictError.unsupportedEntityType
        }
    }
    
    private func getItemConflictDetails(_ conflict: SyncConflict) async throws -> ConflictDetails {
        let decoder = JSONDecoder()
        
        guard let localItem = try? decoder.decode(Item.self, from: conflict.localVersion.data),
              let remoteItem = try? decoder.decode(Item.self, from: conflict.remoteVersion.data) else {
            throw ConflictError.decodingFailed
        }
        
        return ItemConflictDetails(
            localItem: localItem,
            remoteItem: remoteItem,
            changes: conflict.localVersion.changes
        )
    }
    
    private func getReceiptConflictDetails(_ conflict: SyncConflict) async throws -> ConflictDetails {
        let decoder = JSONDecoder()
        
        guard let localReceipt = try? decoder.decode(Receipt.self, from: conflict.localVersion.data),
              let remoteReceipt = try? decoder.decode(Receipt.self, from: conflict.remoteVersion.data) else {
            throw ConflictError.decodingFailed
        }
        
        return ReceiptConflictDetails(
            localReceipt: localReceipt,
            remoteReceipt: remoteReceipt,
            changes: conflict.localVersion.changes
        )
    }
    
    private func getLocationConflictDetails(_ conflict: SyncConflict) async throws -> ConflictDetails {
        let decoder = JSONDecoder()
        
        guard let localLocation = try? decoder.decode(Location.self, from: conflict.localVersion.data),
              let remoteLocation = try? decoder.decode(Location.self, from: conflict.remoteVersion.data) else {
            throw ConflictError.decodingFailed
        }
        
        return LocationConflictDetails(
            localLocation: localLocation,
            remoteLocation: remoteLocation,
            changes: conflict.localVersion.changes
        )
    }
}

// MARK: - Error Types

public enum ConflictError: LocalizedError {
    case unsupportedEntityType
    case decodingFailed
    case mergeNotSupported
    case resolutionFailed
    
    public var errorDescription: String? {
        switch self {
        case .unsupportedEntityType:
            return "This entity type is not supported for conflict resolution"
        case .decodingFailed:
            return "Failed to decode conflict data"
        case .mergeNotSupported:
            return "Merge is not supported for this entity type"
        case .resolutionFailed:
            return "Failed to apply conflict resolution"
        }
    }
}

// MARK: - Conflict Details

public protocol ConflictDetails {
    var entityType: SyncConflict.EntityType { get }
    var changes: [FieldChange] { get }
}

public struct ItemConflictDetails: ConflictDetails {
    public let entityType = SyncConflict.EntityType.item
    public let localItem: Item
    public let remoteItem: Item
    public let changes: [FieldChange]
}

public struct ReceiptConflictDetails: ConflictDetails {
    public let entityType = SyncConflict.EntityType.receipt
    public let localReceipt: Receipt
    public let remoteReceipt: Receipt
    public let changes: [FieldChange]
}

public struct LocationConflictDetails: ConflictDetails {
    public let entityType = SyncConflict.EntityType.location
    public let localLocation: Location
    public let remoteLocation: Location
    public let changes: [FieldChange]
}