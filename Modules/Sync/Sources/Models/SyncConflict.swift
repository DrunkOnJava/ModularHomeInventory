//
//  SyncConflict.swift
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
//  Dependencies: Foundation, Core
//  Testing: Modules/Sync/Tests/SyncTests/SyncConflictTests.swift
//
//  Description: Data models for representing sync conflicts between local and remote data with resolution strategies
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation
import Core

/// Model representing a sync conflict between local and remote data
/// Swift 5.9 - No Swift 6 features
public struct SyncConflict: Identifiable {
    public let id = UUID()
    public let entityType: EntityType
    public let entityId: UUID
    public let localVersion: ConflictVersion
    public let remoteVersion: ConflictVersion
    public let conflictType: ConflictType
    public let detectedAt: Date
    
    public enum EntityType: String, CaseIterable {
        case item = "Item"
        case receipt = "Receipt"
        case location = "Location"
        case collection = "Collection"
        case warranty = "Warranty"
        case document = "Document"
        
        public var icon: String {
            switch self {
            case .item: return "shippingbox"
            case .receipt: return "doc.text"
            case .location: return "location"
            case .collection: return "folder"
            case .warranty: return "shield"
            case .document: return "doc"
            }
        }
    }
    
    public enum ConflictType {
        case update  // Both sides modified
        case delete  // One side deleted, other modified
        case create  // Duplicate creation
        
        public var displayName: String {
            switch self {
            case .update: return "Update Conflict"
            case .delete: return "Delete Conflict"
            case .create: return "Duplicate Creation"
            }
        }
        
        public var description: String {
            switch self {
            case .update:
                return "This item was modified in multiple places"
            case .delete:
                return "This item was deleted on one device but modified on another"
            case .create:
                return "This item was created on multiple devices"
            }
        }
    }
    
    public init(
        entityType: EntityType,
        entityId: UUID,
        localVersion: ConflictVersion,
        remoteVersion: ConflictVersion,
        conflictType: ConflictType,
        detectedAt: Date = Date()
    ) {
        self.entityType = entityType
        self.entityId = entityId
        self.localVersion = localVersion
        self.remoteVersion = remoteVersion
        self.conflictType = conflictType
        self.detectedAt = detectedAt
    }
}

/// Version information for conflict resolution
public struct ConflictVersion {
    public let data: Data
    public let modifiedAt: Date
    public let modifiedBy: String?
    public let deviceName: String?
    public let changes: [FieldChange]
    
    public init(
        data: Data,
        modifiedAt: Date,
        modifiedBy: String? = nil,
        deviceName: String? = nil,
        changes: [FieldChange] = []
    ) {
        self.data = data
        self.modifiedAt = modifiedAt
        self.modifiedBy = modifiedBy
        self.deviceName = deviceName
        self.changes = changes
    }
}

/// Represents a field-level change
public struct FieldChange: Identifiable {
    public let id = UUID()
    public let fieldName: String
    public let displayName: String
    public let oldValue: String?
    public let newValue: String?
    public let isConflicting: Bool
    
    public init(
        fieldName: String,
        displayName: String,
        oldValue: String?,
        newValue: String?,
        isConflicting: Bool = false
    ) {
        self.fieldName = fieldName
        self.displayName = displayName
        self.oldValue = oldValue
        self.newValue = newValue
        self.isConflicting = isConflicting
    }
}

/// Resolution strategy for conflicts
public enum ConflictResolution: Equatable {
    case keepLocal
    case keepRemote
    case merge(MergeStrategy)
    case custom(Data)
    
    public var displayName: String {
        switch self {
        case .keepLocal: return "Keep Local Version"
        case .keepRemote: return "Keep Remote Version"
        case .merge(let strategy): return "Merge (\(strategy.displayName))"
        case .custom: return "Custom Resolution"
        }
    }
}

/// Merge strategies for conflict resolution
public enum MergeStrategy: Equatable {
    case latestWins
    case localPriority
    case remotePriority
    case fieldLevel([FieldResolution])
    
    public var displayName: String {
        switch self {
        case .latestWins: return "Latest Changes Win"
        case .localPriority: return "Local Priority"
        case .remotePriority: return "Remote Priority"
        case .fieldLevel: return "Field-by-Field"
        }
    }
}

/// Field-level resolution
public struct FieldResolution: Equatable {
    public let fieldName: String
    public let resolution: FieldResolutionType
    
    public enum FieldResolutionType: Equatable {
        case useLocal
        case useRemote
        case concatenate(separator: String)
        case average  // For numeric fields
        case latest   // Use most recent
    }
    
    public init(fieldName: String, resolution: FieldResolutionType) {
        self.fieldName = fieldName
        self.resolution = resolution
    }
}

/// Result of conflict resolution
public struct ConflictResolutionResult {
    public let conflictId: UUID
    public let resolution: ConflictResolution
    public let resolvedData: Data
    public let resolvedAt: Date
    public let resolvedBy: String?
    
    public init(
        conflictId: UUID,
        resolution: ConflictResolution,
        resolvedData: Data,
        resolvedAt: Date = Date(),
        resolvedBy: String? = nil
    ) {
        self.conflictId = conflictId
        self.resolution = resolution
        self.resolvedData = resolvedData
        self.resolvedAt = resolvedAt
        self.resolvedBy = resolvedBy
    }
}