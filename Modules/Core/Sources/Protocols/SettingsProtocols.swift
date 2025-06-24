import Foundation

/// Settings key for key-value storage
public struct SettingsKey: Hashable, ExpressibleByStringLiteral {
    public let key: String
    
    public init(_ key: String) {
        self.key = key
    }
    
    public init(stringLiteral value: String) {
        self.key = value
    }
}

/// Protocol for settings storage
public protocol SettingsStorageProtocol: AnyObject {
    // Key-value storage for individual settings
    func string(forKey key: SettingsKey) -> String?
    func set(_ value: String?, forKey key: SettingsKey)
    
    func bool(forKey key: SettingsKey) -> Bool?
    func set(_ value: Bool, forKey key: SettingsKey)
    
    func integer(forKey key: SettingsKey) -> Int?
    func set(_ value: Int, forKey key: SettingsKey)
    
    func double(forKey key: SettingsKey) -> Double?
    func set(_ value: Double, forKey key: SettingsKey)
}

// MARK: - Common Settings Keys

extension SettingsKey {
    // Dynamic Type
    public static let textSizePreference = SettingsKey("text_size_preference")
    public static let enableBoldText = SettingsKey("enable_bold_text")
    public static let increaseContrast = SettingsKey("increase_contrast")
    public static let reduceTransparency = SettingsKey("reduce_transparency")
    public static let reduceMotion = SettingsKey("reduce_motion")
    
    // Theme
    public static let darkModeEnabled = SettingsKey("dark_mode_enabled")
    public static let useSystemTheme = SettingsKey("use_system_theme")
    
    // Notifications
    public static let notificationsEnabled = SettingsKey("notifications_enabled")
    
    // Security
    public static let biometricAuthEnabled = SettingsKey("biometric_auth_enabled")
    
    // General
    public static let defaultCurrency = SettingsKey("default_currency")
    public static let autoBackupEnabled = SettingsKey("auto_backup_enabled")
    public static let offlineModeEnabled = SettingsKey("offline_mode_enabled")
    public static let autoSyncOnWiFi = SettingsKey("auto_sync_on_wifi")
    
    // VoiceOver
    public static let voiceOverEnabled = SettingsKey("voiceover_enabled")
    public static let voiceOverSpeakingRate = SettingsKey("voiceover_speaking_rate")
    public static let voiceOverVerbosity = SettingsKey("voiceover_verbosity")
    
    // Crash Reporting
    public static let crashReportingEnabled = SettingsKey("crash_reporting_enabled")
    public static let crashReportingAutoSend = SettingsKey("crash_reporting_auto_send")
}