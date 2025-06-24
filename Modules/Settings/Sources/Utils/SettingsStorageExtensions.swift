import Foundation
import Core

// MARK: - Settings Storage Extensions

extension SettingsStorageProtocol {
    /// Load AppSettings from storage
    func loadSettings() -> AppSettings {
        AppSettings(
            notificationsEnabled: bool(forKey: .notificationsEnabled) ?? true,
            darkModeEnabled: bool(forKey: .darkModeEnabled) ?? false,
            biometricAuthEnabled: bool(forKey: .biometricAuthEnabled) ?? false,
            defaultCurrency: string(forKey: .defaultCurrency) ?? "USD",
            autoBackupEnabled: bool(forKey: .autoBackupEnabled) ?? true,
            offlineModeEnabled: bool(forKey: .offlineModeEnabled) ?? true,
            autoSyncOnWiFi: bool(forKey: .autoSyncOnWiFi) ?? true,
            scannerSoundEnabled: bool(forKey: SettingsKey("scanner_sound_enabled")) ?? true,
            scannerSensitivity: ScannerSensitivity(
                rawValue: string(forKey: SettingsKey("scanner_sensitivity")) ?? "Medium"
            ) ?? .medium,
            continuousScanDelay: double(forKey: SettingsKey("continuous_scan_delay")) ?? 1.0,
            enabledBarcodeFormats: loadBarcodeFormats()
        )
    }
    
    /// Save AppSettings to storage
    func saveSettings(_ settings: AppSettings) {
        set(settings.notificationsEnabled, forKey: .notificationsEnabled)
        set(settings.darkModeEnabled, forKey: .darkModeEnabled)
        set(settings.biometricAuthEnabled, forKey: .biometricAuthEnabled)
        set(settings.defaultCurrency, forKey: .defaultCurrency)
        set(settings.autoBackupEnabled, forKey: .autoBackupEnabled)
        set(settings.offlineModeEnabled, forKey: .offlineModeEnabled)
        set(settings.autoSyncOnWiFi, forKey: .autoSyncOnWiFi)
        set(settings.scannerSoundEnabled, forKey: SettingsKey("scanner_sound_enabled"))
        set(settings.scannerSensitivity.rawValue, forKey: SettingsKey("scanner_sensitivity"))
        set(settings.continuousScanDelay, forKey: SettingsKey("continuous_scan_delay"))
        saveBarcodeFormats(settings.enabledBarcodeFormats)
    }
    
    private func loadBarcodeFormats() -> [String] {
        // Load barcode formats as a comma-separated string
        let formatsString = string(forKey: SettingsKey("enabled_barcode_formats")) ?? ""
        if formatsString.isEmpty {
            return ["ean13", "ean8", "upce", "code128", "qr"]
        }
        return formatsString.split(separator: ",").map { String($0) }
    }
    
    private func saveBarcodeFormats(_ formats: [String]) {
        // Save barcode formats as a comma-separated string
        let formatsString = formats.joined(separator: ",")
        set(formatsString, forKey: SettingsKey("enabled_barcode_formats"))
    }
}

// MARK: - Additional Settings Keys

extension SettingsKey {
    // Scanner settings
    public static let scannerSoundEnabled = SettingsKey("scanner_sound_enabled")
    public static let scannerSensitivity = SettingsKey("scanner_sensitivity")
    public static let continuousScanDelay = SettingsKey("continuous_scan_delay")
    public static let enabledBarcodeFormats = SettingsKey("enabled_barcode_formats")
    
    // Sync settings
    public static let autoBackupEnabled = SettingsKey("auto_backup_enabled")
    public static let offlineModeEnabled = SettingsKey("offline_mode_enabled")
    public static let autoSyncOnWiFi = SettingsKey("auto_sync_on_wifi")
    
    // General settings
    public static let defaultCurrency = SettingsKey("default_currency")
    public static let notificationsEnabled = SettingsKey("notifications_enabled")
    public static let darkModeEnabled = SettingsKey("dark_mode_enabled")
    public static let biometricAuthEnabled = SettingsKey("biometric_auth_enabled")
}