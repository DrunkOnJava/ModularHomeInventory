import SwiftUI
import Core

/// Public API for the Settings module
/// Swift 5.9 - No Swift 6 features
@MainActor
public protocol SettingsModuleAPI {
    /// Creates the main settings view
    func makeSettingsView() -> AnyView
    
    /// Creates the about view
    func makeAboutView() -> AnyView
}

/// Settings values that can be configured
public struct AppSettings: Codable {
    public var notificationsEnabled: Bool
    public var darkModeEnabled: Bool
    public var biometricAuthEnabled: Bool
    public var defaultCurrency: String
    public var autoBackupEnabled: Bool
    
    public init(
        notificationsEnabled: Bool = true,
        darkModeEnabled: Bool = false,
        biometricAuthEnabled: Bool = false,
        defaultCurrency: String = "USD",
        autoBackupEnabled: Bool = true
    ) {
        self.notificationsEnabled = notificationsEnabled
        self.darkModeEnabled = darkModeEnabled
        self.biometricAuthEnabled = biometricAuthEnabled
        self.defaultCurrency = defaultCurrency
        self.autoBackupEnabled = autoBackupEnabled
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
    
    public init(settingsStorage: SettingsStorageProtocol) {
        self.settingsStorage = settingsStorage
    }
}