//
//  PrivateModeService.swift
//  Core
//
//  Service for managing private mode to hide sensitive items
//

import Foundation
import SwiftUI
import LocalAuthentication

@available(iOS 15.0, *)
public final class PrivateModeService: ObservableObject {
    public static let shared = PrivateModeService()
    
    // MARK: - Published Properties
    
    @Published public var isPrivateModeEnabled = false
    @Published public var requireAuthenticationToView = true
    @Published public var privateItemIds: Set<UUID> = []
    @Published public var privateCategories: Set<String> = []
    @Published public var privateTags: Set<String> = []
    @Published public var hideValuesInLists = true
    @Published public var blurPhotosInLists = true
    @Published public var maskSerialNumbers = true
    @Published public var hideFromSearch = true
    @Published public var hideFromAnalytics = true
    @Published public var hideFromWidgets = true
    @Published public var isAuthenticated = false
    @Published public var sessionTimeout: TimeInterval = 300 // 5 minutes
    @Published public var lastAuthenticationTime: Date?
    
    // MARK: - Types
    
    public enum PrivacyLevel: Int, CaseIterable, Codable {
        case none = 0
        case partial = 1
        case full = 2
        
        public var displayName: String {
            switch self {
            case .none: return "Public"
            case .partial: return "Partially Hidden"
            case .full: return "Fully Private"
            }
        }
        
        public var icon: String {
            switch self {
            case .none: return "eye"
            case .partial: return "eye.slash"
            case .full: return "lock.fill"
            }
        }
        
        public var description: String {
            switch self {
            case .none:
                return "Item is visible everywhere"
            case .partial:
                return "Values and photos are hidden in lists"
            case .full:
                return "Item is completely hidden until authenticated"
            }
        }
    }
    
    public struct PrivateItemSettings: Codable {
        public var itemId: UUID
        public var privacyLevel: PrivacyLevel
        public var hideValue: Bool
        public var hidePhotos: Bool
        public var hideLocation: Bool
        public var hideSerialNumber: Bool
        public var hidePurchaseInfo: Bool
        public var hideFromFamily: Bool
        public var customMessage: String?
        
        public init(
            itemId: UUID,
            privacyLevel: PrivacyLevel = .full,
            hideValue: Bool = true,
            hidePhotos: Bool = true,
            hideLocation: Bool = true,
            hideSerialNumber: Bool = true,
            hidePurchaseInfo: Bool = true,
            hideFromFamily: Bool = true,
            customMessage: String? = nil
        ) {
            self.itemId = itemId
            self.privacyLevel = privacyLevel
            self.hideValue = hideValue
            self.hidePhotos = hidePhotos
            self.hideLocation = hideLocation
            self.hideSerialNumber = hideSerialNumber
            self.hidePurchaseInfo = hidePurchaseInfo
            self.hideFromFamily = hideFromFamily
            self.customMessage = customMessage
        }
    }
    
    public enum AuthenticationError: LocalizedError {
        case notEnabled
        case authenticationFailed
        case sessionExpired
        case biometryNotAvailable
        
        public var errorDescription: String? {
            switch self {
            case .notEnabled:
                return "Private mode is not enabled"
            case .authenticationFailed:
                return "Authentication failed"
            case .sessionExpired:
                return "Your private mode session has expired"
            case .biometryNotAvailable:
                return "Biometric authentication is not available"
            }
        }
    }
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    private let keychain = KeychainManager.shared
    private var privateSettings: [UUID: PrivateItemSettings] = [:]
    private var sessionTimer: Timer?
    private let context = LAContext()
    
    private let privateModeEnabledKey = "private_mode_enabled"
    private let requireAuthKey = "private_mode_require_auth"
    private let privateItemsKey = "private_item_ids"
    private let privateCategoriesKey = "private_categories"
    private let privateTagsKey = "private_tags"
    private let privateSettingsKey = "private_item_settings"
    private let hideValuesKey = "hide_values_in_lists"
    private let blurPhotosKey = "blur_photos_in_lists"
    private let maskSerialKey = "mask_serial_numbers"
    private let hideFromSearchKey = "hide_from_search"
    private let hideFromAnalyticsKey = "hide_from_analytics"
    private let hideFromWidgetsKey = "hide_from_widgets"
    
    // MARK: - Initialization
    
    private init() {
        loadSettings()
    }
    
    // MARK: - Public Methods
    
    /// Enable private mode
    public func enablePrivateMode() {
        isPrivateModeEnabled = true
        userDefaults.set(true, forKey: privateModeEnabledKey)
        
        // Reset authentication when enabling
        isAuthenticated = false
        lastAuthenticationTime = nil
    }
    
    /// Disable private mode
    public func disablePrivateMode() async throws {
        // Require authentication to disable
        if requireAuthenticationToView {
            try await authenticate()
        }
        
        isPrivateModeEnabled = false
        isAuthenticated = false
        lastAuthenticationTime = nil
        userDefaults.set(false, forKey: privateModeEnabledKey)
        
        stopSessionTimer()
    }
    
    /// Authenticate to view private items
    public func authenticate() async throws {
        guard isPrivateModeEnabled else {
            throw AuthenticationError.notEnabled
        }
        
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        context.localizedFallbackTitle = "Enter Passcode"
        
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            throw AuthenticationError.biometryNotAvailable
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Authenticate to view private items"
            )
            
            if success {
                isAuthenticated = true
                lastAuthenticationTime = Date()
                startSessionTimer()
            } else {
                throw AuthenticationError.authenticationFailed
            }
            
        } catch {
            throw AuthenticationError.authenticationFailed
        }
    }
    
    /// Check if authentication is still valid
    public func checkAuthenticationStatus() {
        guard let lastAuth = lastAuthenticationTime else {
            isAuthenticated = false
            return
        }
        
        let elapsed = Date().timeIntervalSince(lastAuth)
        if elapsed > sessionTimeout {
            isAuthenticated = false
            lastAuthenticationTime = nil
            stopSessionTimer()
        }
    }
    
    /// Mark item as private
    public func markItemAsPrivate(_ itemId: UUID, settings: PrivateItemSettings? = nil) {
        privateItemIds.insert(itemId)
        
        let itemSettings = settings ?? PrivateItemSettings(itemId: itemId)
        privateSettings[itemId] = itemSettings
        
        saveSettings()
    }
    
    /// Remove item from private
    public func removeItemFromPrivate(_ itemId: UUID) {
        privateItemIds.remove(itemId)
        privateSettings.removeValue(forKey: itemId)
        
        saveSettings()
    }
    
    /// Toggle item privacy
    public func toggleItemPrivacy(_ itemId: UUID) {
        if privateItemIds.contains(itemId) {
            removeItemFromPrivate(itemId)
        } else {
            markItemAsPrivate(itemId)
        }
    }
    
    /// Check if item is private
    public func isItemPrivate(_ itemId: UUID) -> Bool {
        return privateItemIds.contains(itemId)
    }
    
    /// Get privacy settings for item
    public func getPrivacySettings(for itemId: UUID) -> PrivateItemSettings? {
        return privateSettings[itemId]
    }
    
    /// Update privacy settings for item
    public func updatePrivacySettings(_ settings: PrivateItemSettings) {
        privateSettings[settings.itemId] = settings
        if settings.privacyLevel != .none {
            privateItemIds.insert(settings.itemId)
        } else {
            privateItemIds.remove(settings.itemId)
        }
        saveSettings()
    }
    
    /// Mark category as private
    public func markCategoryAsPrivate(_ category: String) {
        privateCategories.insert(category)
        saveSettings()
    }
    
    /// Remove category from private
    public func removeCategoryFromPrivate(_ category: String) {
        privateCategories.remove(category)
        saveSettings()
    }
    
    /// Mark tag as private
    public func markTagAsPrivate(_ tag: String) {
        privateTags.insert(tag)
        saveSettings()
    }
    
    /// Remove tag from private
    public func removeTagFromPrivate(_ tag: String) {
        privateTags.remove(tag)
        saveSettings()
    }
    
    /// Check if item should be hidden based on category or tags
    public func shouldHideItem(category: String?, tags: [String]) -> Bool {
        guard isPrivateModeEnabled else { return false }
        
        // Check category
        if let category = category, privateCategories.contains(category) {
            return !isAuthenticated
        }
        
        // Check tags
        for tag in tags {
            if privateTags.contains(tag) {
                return !isAuthenticated
            }
        }
        
        return false
    }
    
    /// Get display value for private items
    public func getDisplayValue(for value: Decimal?, itemId: UUID) -> String {
        guard isPrivateModeEnabled,
              let value = value,
              shouldHideValue(for: itemId) else {
            return value?.formatted(.currency(code: "USD")) ?? "—"
        }
        
        return "••••"
    }
    
    /// Check if value should be hidden
    public func shouldHideValue(for itemId: UUID) -> Bool {
        guard isPrivateModeEnabled else { return false }
        
        if !isAuthenticated && privateItemIds.contains(itemId) {
            return privateSettings[itemId]?.hideValue ?? hideValuesInLists
        }
        
        return false
    }
    
    /// Check if photos should be blurred
    public func shouldBlurPhotos(for itemId: UUID) -> Bool {
        guard isPrivateModeEnabled else { return false }
        
        if !isAuthenticated && privateItemIds.contains(itemId) {
            return privateSettings[itemId]?.hidePhotos ?? blurPhotosInLists
        }
        
        return false
    }
    
    /// Get masked serial number
    public func getMaskedSerialNumber(_ serialNumber: String?, itemId: UUID) -> String? {
        guard let serialNumber = serialNumber,
              isPrivateModeEnabled,
              shouldMaskSerialNumber(for: itemId) else {
            return serialNumber
        }
        
        // Show last 4 characters only
        if serialNumber.count > 4 {
            let suffix = String(serialNumber.suffix(4))
            let prefixLength = serialNumber.count - 4
            let masked = String(repeating: "•", count: prefixLength) + suffix
            return masked
        } else {
            return String(repeating: "•", count: serialNumber.count)
        }
    }
    
    /// Check if serial number should be masked
    public func shouldMaskSerialNumber(for itemId: UUID) -> Bool {
        guard isPrivateModeEnabled else { return false }
        
        if !isAuthenticated && privateItemIds.contains(itemId) {
            return privateSettings[itemId]?.hideSerialNumber ?? maskSerialNumbers
        }
        
        return false
    }
    
    /// Update settings
    public func updateSettings(
        requireAuth: Bool? = nil,
        hideValues: Bool? = nil,
        blurPhotos: Bool? = nil,
        maskSerial: Bool? = nil,
        hideSearch: Bool? = nil,
        hideAnalytics: Bool? = nil,
        hideWidgets: Bool? = nil
    ) {
        if let requireAuth = requireAuth {
            requireAuthenticationToView = requireAuth
            userDefaults.set(requireAuth, forKey: requireAuthKey)
        }
        
        if let hideValues = hideValues {
            hideValuesInLists = hideValues
            userDefaults.set(hideValues, forKey: hideValuesKey)
        }
        
        if let blurPhotos = blurPhotos {
            blurPhotosInLists = blurPhotos
            userDefaults.set(blurPhotos, forKey: blurPhotosKey)
        }
        
        if let maskSerial = maskSerial {
            maskSerialNumbers = maskSerial
            userDefaults.set(maskSerial, forKey: maskSerialKey)
        }
        
        if let hideSearch = hideSearch {
            hideFromSearch = hideSearch
            userDefaults.set(hideSearch, forKey: hideFromSearchKey)
        }
        
        if let hideAnalytics = hideAnalytics {
            hideFromAnalytics = hideAnalytics
            userDefaults.set(hideAnalytics, forKey: hideFromAnalyticsKey)
        }
        
        if let hideWidgets = hideWidgets {
            hideFromWidgets = hideWidgets
            userDefaults.set(hideWidgets, forKey: hideFromWidgetsKey)
        }
    }
    
    // MARK: - Private Methods
    
    private func loadSettings() {
        isPrivateModeEnabled = userDefaults.object(forKey: privateModeEnabledKey) as? Bool ?? false
        requireAuthenticationToView = userDefaults.object(forKey: requireAuthKey) as? Bool ?? true
        hideValuesInLists = userDefaults.object(forKey: hideValuesKey) as? Bool ?? true
        blurPhotosInLists = userDefaults.object(forKey: blurPhotosKey) as? Bool ?? true
        maskSerialNumbers = userDefaults.object(forKey: maskSerialKey) as? Bool ?? true
        hideFromSearch = userDefaults.object(forKey: hideFromSearchKey) as? Bool ?? true
        hideFromAnalytics = userDefaults.object(forKey: hideFromAnalyticsKey) as? Bool ?? true
        hideFromWidgets = userDefaults.object(forKey: hideFromWidgetsKey) as? Bool ?? true
        
        // Load private items
        if let itemIds = userDefaults.object(forKey: privateItemsKey) as? [String] {
            privateItemIds = Set(itemIds.compactMap { UUID(uuidString: $0) })
        }
        
        // Load private categories
        if let categories = userDefaults.object(forKey: privateCategoriesKey) as? [String] {
            privateCategories = Set(categories)
        }
        
        // Load private tags
        if let tags = userDefaults.object(forKey: privateTagsKey) as? [String] {
            privateTags = Set(tags)
        }
        
        // Load private settings
        if let data = userDefaults.data(forKey: privateSettingsKey) {
            do {
                let decoder = JSONDecoder()
                privateSettings = try decoder.decode([UUID: PrivateItemSettings].self, from: data)
            } catch {
                print("Failed to load private settings: \(error)")
            }
        }
    }
    
    private func saveSettings() {
        // Save private items
        let itemIds = privateItemIds.map { $0.uuidString }
        userDefaults.set(itemIds, forKey: privateItemsKey)
        
        // Save private categories
        userDefaults.set(Array(privateCategories), forKey: privateCategoriesKey)
        
        // Save private tags
        userDefaults.set(Array(privateTags), forKey: privateTagsKey)
        
        // Save private settings
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(privateSettings)
            userDefaults.set(data, forKey: privateSettingsKey)
        } catch {
            print("Failed to save private settings: \(error)")
        }
    }
    
    private func startSessionTimer() {
        stopSessionTimer()
        
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.checkAuthenticationStatus()
        }
    }
    
    private func stopSessionTimer() {
        sessionTimer?.invalidate()
        sessionTimer = nil
    }
}

// MARK: - Keychain Manager (Stub)

class KeychainManager {
    static let shared = KeychainManager()
    private init() {}
}