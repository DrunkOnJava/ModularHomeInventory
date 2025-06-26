//
//  SettingsProtocols.swift
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
//  Dependencies: Foundation
//  Testing: Modules/Core/Tests/CoreTests/SettingsProtocolsTests.swift
//
//  Description: Protocols and types for app settings storage with predefined keys for common settings
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

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
    public static let crashReportingDetailLevel = SettingsKey("crash_reporting_detail_level")
    
    // VoiceOver Additional
    public static let voiceOverAnnouncementDelay = SettingsKey("voiceover_announcement_delay")
}