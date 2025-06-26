//
//  ViewOnlyModeService.swift
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
//  Dependencies: Foundation, SwiftUI, UIKit
//  Testing: CoreTests/ViewOnlyModeServiceTests.swift
//
//  Description: Service for managing view-only mode and read-only sharing
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

public class ViewOnlyModeService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var isViewOnlyMode = false
    @Published public var viewOnlySettings = ViewOnlySettings()
    @Published public var sharedLinks: [SharedLink] = []
    @Published public var isGeneratingLink = false
    @Published public var error: ViewOnlyError?
    
    // MARK: - Types
    
    public struct ViewOnlySettings {
        public var allowPhotos = true
        public var allowPrices = false
        public var allowLocations = true
        public var allowSerialNumbers = false
        public var allowReceipts = false
        public var allowNotes = true
        public var allowWarrantyInfo = false
        public var expirationDate: Date?
        public var requirePassword = false
        public var password = ""
        public var maxViews: Int?
        public var watermarkText = ""
        
        public init() {}
    }
    
    public struct SharedLink: Identifiable, Codable {
        public let id = UUID()
        public let url: URL
        public let shortCode: String
        public let createdAt: Date
        public let expiresAt: Date?
        public let settings: ViewOnlySettings
        public let itemIds: [UUID]
        public var viewCount: Int = 0
        public let createdBy: String
        public var isActive: Bool = true
        
        public var shareableURL: URL {
            URL(string: "https://homeinventory.app/view/\(shortCode)")!
        }
    }
    
    public enum ViewOnlyError: LocalizedError {
        case linkGenerationFailed
        case invalidSettings
        case sharingDisabled
        case linkExpired
        case maxViewsReached
        case passwordRequired
        case networkError(Error)
        
        public var errorDescription: String? {
            switch self {
            case .linkGenerationFailed:
                return "Failed to generate sharing link"
            case .invalidSettings:
                return "Invalid view-only settings"
            case .sharingDisabled:
                return "Sharing is currently disabled"
            case .linkExpired:
                return "This sharing link has expired"
            case .maxViewsReached:
                return "Maximum number of views reached"
            case .passwordRequired:
                return "Password is required to view this content"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Private Properties
    
    private let settingsStorage = UserDefaultsSettingsStorage()
    private let shareBaseURL = "https://homeinventory.app/view/"
    
    // MARK: - Public Methods
    
    /// Generate a view-only sharing link for items
    public func generateShareLink(
        for items: [Item],
        settings: ViewOnlySettings = ViewOnlySettings()
    ) async throws -> SharedLink {
        
        guard !items.isEmpty else {
            throw ViewOnlyError.invalidSettings
        }
        
        await MainActor.run {
            isGeneratingLink = true
        }
        
        do {
            // Generate unique short code
            let shortCode = generateShortCode()
            
            // Create shared link data
            let linkData = SharedLinkData(
                shortCode: shortCode,
                itemIds: items.map { $0.id.uuidString },
                settings: settings,
                createdAt: Date(),
                expiresAt: settings.expirationDate,
                viewCount: 0,
                isActive: true,
                createdBy: getUserIdentifier()
            )
            
            // Save to local storage (in a real app, this would be saved to a backend)
            saveLinkData(linkData)
            
            // Create local shared link
            let sharedLink = SharedLink(
                url: URL(string: "https://homeinventory.app/view/\(shortCode)")!,
                shortCode: shortCode,
                createdAt: Date(),
                expiresAt: settings.expirationDate,
                settings: settings,
                itemIds: items.map { $0.id },
                createdBy: getUserIdentifier()
            )
            
            await MainActor.run {
                sharedLinks.append(sharedLink)
                isGeneratingLink = false
            }
            
            // Save to local storage
            saveSharedLinks()
            
            return sharedLink
            
        } catch {
            await MainActor.run {
                isGeneratingLink = false
                self.error = .networkError(error)
            }
            throw error
        }
    }
    
    /// Revoke a shared link
    public func revokeLink(_ link: SharedLink) async throws {
        // Update local storage
        if let index = sharedLinks.firstIndex(where: { $0.id == link.id }) {
            sharedLinks[index].isActive = false
        }
        saveSharedLinks()
        
        // In a real app, this would update the backend
        // For now, we just update local storage
    }
    
    /// Load items from a shared link
    public func loadSharedItems(shortCode: String, password: String? = nil) async throws -> (items: [Item], settings: ViewOnlySettings) {
        // Find the shared link in local storage
        guard let linkData = loadLinkData(shortCode: shortCode) else {
            throw ViewOnlyError.linkExpired
        }
        
        // Check if link is active
        guard linkData.isActive else {
            throw ViewOnlyError.linkExpired
        }
        
        // Check expiration
        if let expiresAt = linkData.expiresAt, expiresAt < Date() {
            throw ViewOnlyError.linkExpired
        }
        
        // Check view count
        if let maxViews = linkData.settings.maxViews, linkData.viewCount >= maxViews {
            throw ViewOnlyError.maxViewsReached
        }
        
        // Check password if required
        if linkData.settings.requirePassword {
            guard let providedPassword = password,
                  providedPassword == linkData.settings.password else {
                throw ViewOnlyError.passwordRequired
            }
        }
        
        // Increment view count
        incrementViewCount(for: shortCode)
        
        // Load items
        let itemIds = linkData.itemIds.compactMap { UUID(uuidString: $0) }
        let items = await loadItems(with: itemIds)
        
        // Filter items based on settings
        let filteredItems = filterItemsForViewOnly(items, settings: linkData.settings)
        
        return (filteredItems, linkData.settings)
    }
    
    /// Enable view-only mode locally
    public func enableViewOnlyMode(settings: ViewOnlySettings = ViewOnlySettings()) {
        isViewOnlyMode = true
        viewOnlySettings = settings
        
        // Notify app to update UI
        NotificationCenter.default.post(
            name: .viewOnlyModeChanged,
            object: nil,
            userInfo: ["enabled": true, "settings": settings]
        )
    }
    
    /// Disable view-only mode
    public func disableViewOnlyMode() {
        isViewOnlyMode = false
        viewOnlySettings = ViewOnlySettings()
        
        // Notify app to update UI
        NotificationCenter.default.post(
            name: .viewOnlyModeChanged,
            object: nil,
            userInfo: ["enabled": false]
        )
    }
    
    /// Check if a feature is allowed in view-only mode
    public func isFeatureAllowed(_ feature: ViewOnlyFeature) -> Bool {
        guard isViewOnlyMode else { return true }
        
        switch feature {
        case .viewPhotos:
            return viewOnlySettings.allowPhotos
        case .viewPrices:
            return viewOnlySettings.allowPrices
        case .viewLocations:
            return viewOnlySettings.allowLocations
        case .viewSerialNumbers:
            return viewOnlySettings.allowSerialNumbers
        case .viewReceipts:
            return viewOnlySettings.allowReceipts
        case .viewNotes:
            return viewOnlySettings.allowNotes
        case .viewWarrantyInfo:
            return viewOnlySettings.allowWarrantyInfo
        case .edit, .delete, .add, .share, .export:
            return false
        }
    }
    
    // MARK: - Private Methods
    
    private func generateShortCode() -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<8).map { _ in characters.randomElement()! })
    }
    
    private func getUserIdentifier() -> String {
        // Get user identifier from CloudKit or device
        return UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
    }
    
    // MARK: - Link Data Storage
    
    private struct SharedLinkData: Codable {
        let shortCode: String
        let itemIds: [String]
        let settings: ViewOnlySettings
        let createdAt: Date
        let expiresAt: Date?
        var viewCount: Int
        let isActive: Bool
        let createdBy: String
    }
    
    private func saveLinkData(_ data: SharedLinkData) {
        var allLinks = loadAllLinkData()
        allLinks[data.shortCode] = data
        
        if let encoded = try? JSONEncoder().encode(allLinks) {
            UserDefaults.standard.set(encoded, forKey: "ViewOnlyLinkData")
        }
    }
    
    private func loadLinkData(shortCode: String) -> SharedLinkData? {
        let allLinks = loadAllLinkData()
        return allLinks[shortCode]
    }
    
    private func loadAllLinkData() -> [String: SharedLinkData] {
        guard let data = UserDefaults.standard.data(forKey: "ViewOnlyLinkData"),
              let links = try? JSONDecoder().decode([String: SharedLinkData].self, from: data) else {
            return [:]
        }
        return links
    }
    
    private func incrementViewCount(for shortCode: String) {
        var allLinks = loadAllLinkData()
        if var linkData = allLinks[shortCode] {
            linkData.viewCount += 1
            allLinks[shortCode] = linkData
            
            if let encoded = try? JSONEncoder().encode(allLinks) {
                UserDefaults.standard.set(encoded, forKey: "ViewOnlyLinkData")
            }
        }
    }
    
    private func loadItems(with ids: [UUID]) async -> [Item] {
        // This would load items from the database
        // For now, returning empty array as placeholder
        []
    }
    
    private func filterItemsForViewOnly(_ items: [Item], settings: ViewOnlySettings) -> [Item] {
        items.map { item in
            var filteredItem = item
            
            if !settings.allowPrices {
                filteredItem.value = nil
                filteredItem.purchasePrice = nil
            }
            
            if !settings.allowSerialNumbers {
                filteredItem.serialNumber = nil
            }
            
            if !settings.allowNotes {
                filteredItem.notes = nil
            }
            
            return filteredItem
        }
    }
    
    private func saveSharedLinks() {
        if let data = try? JSONEncoder().encode(sharedLinks) {
            UserDefaults.standard.set(data, forKey: "ViewOnlySharedLinks")
        }
    }
    
    private func loadSharedLinks() {
        if let data = UserDefaults.standard.data(forKey: "ViewOnlySharedLinks"),
           let links = try? JSONDecoder().decode([SharedLink].self, from: data) {
            sharedLinks = links
        }
    }
    
    // MARK: - Initialization
    
    public init() {
        loadSharedLinks()
    }
    
    // MARK: - Singleton
    
    public static let shared = ViewOnlyModeService()
}

// MARK: - View Only Features

public enum ViewOnlyFeature {
    case viewPhotos
    case viewPrices
    case viewLocations
    case viewSerialNumbers
    case viewReceipts
    case viewNotes
    case viewWarrantyInfo
    case edit
    case delete
    case add
    case share
    case export
}

// MARK: - Notification Extension

public extension Notification.Name {
    static let viewOnlyModeChanged = Notification.Name("viewOnlyModeChanged")
}

// MARK: - ViewOnlySettings Codable

extension ViewOnlyModeService.ViewOnlySettings: Codable {
    enum CodingKeys: String, CodingKey {
        case allowPhotos
        case allowPrices
        case allowLocations
        case allowSerialNumbers
        case allowReceipts
        case allowNotes
        case allowWarrantyInfo
        case expirationDate
        case requirePassword
        case password
        case maxViews
        case watermarkText
    }
}