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

/// Protocol for settings storage
public protocol SettingsStorageProtocol {
    func loadSettings() -> AppSettings
    func saveSettings(_ settings: AppSettings)
}

/// Dependencies required by the Settings module
public struct SettingsModuleDependencies {
    public let settingsStorage: SettingsStorageProtocol
    public let itemRepository: (any ItemRepository)?
    public let receiptRepository: (any ReceiptRepository)?
    public let locationRepository: (any LocationRepository)?
    
    public init(
        settingsStorage: SettingsStorageProtocol,
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