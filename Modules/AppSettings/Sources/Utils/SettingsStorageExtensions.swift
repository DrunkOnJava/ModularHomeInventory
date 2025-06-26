//
//  SettingsStorageExtensions.swift
//  AppSettings Module
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
//  Module: AppSettings
//  Dependencies: Foundation, Core
//  Testing: Modules/AppSettings/Tests/Utils/SettingsStorageExtensionsTests.swift
//
//  Description: Protocol extensions for SettingsStorageProtocol providing convenient load/save methods for AppSettings and additional settings key definitions
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

//
//  SettingsStorageExtensions.swift
//  AppSettings Module
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
//  Module: AppSettings
//  Dependencies: Foundation, Core
//  Testing: Modules/AppSettings/Tests/AppSettingsTests/SettingsStorageExtensionsTests.swift
//
//  Description: Extensions to SettingsStorageProtocol providing AppSettings load/save functionality
//  and additional SettingsKey definitions for scanner, sync, and general app settings
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation
import Core

// MARK: - Settings Storage Extensions

extension SettingsStorageProtocol {
    /// Load AppSettings from storage
    public func loadSettings() -> AppSettings {
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
    public func saveSettings(_ settings: AppSettings) {
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