//
//  ThemeManager.swift
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
//  Module: SharedUI
//  Dependencies: SwiftUI, Combine
//  Testing: Modules/SharedUI/Tests/SharedUITests/ThemeManagerTests.swift
//
//  Description: Theme manager for handling dark mode preferences and app-wide theming
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Combine

/// Theme manager for handling dark mode preferences
/// Swift 5.9 - No Swift 6 features
@MainActor
public final class ThemeManager: ObservableObject {
    public static let shared = ThemeManager()
    
    @Published public var colorScheme: ColorScheme?
    @Published public var isDarkMode: Bool = false
    @Published public var useSystemTheme: Bool = true
    
    private init() {
        // Load saved preferences
        loadPreferences()
    }
    
    private func loadPreferences() {
        // Check if user has previously set a preference
        if UserDefaults.standard.object(forKey: "isDarkMode") != nil {
            // User has set a preference, use it
            useSystemTheme = false
            isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
            colorScheme = isDarkMode ? .dark : .light
        } else {
            // No preference set, use system theme
            useSystemTheme = true
            colorScheme = nil
        }
    }
    
    public func setDarkMode(_ isDark: Bool) {
        isDarkMode = isDark
        useSystemTheme = false
        colorScheme = isDarkMode ? .dark : .light
        
        // Save preference
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
    }
}

// MARK: - Additional Theme Colors
public extension AppColors {
    // Additional dynamic colors that aren't in the main Colors.swift
    static var groupedBackground: Color {
        Color(UIColor.systemGroupedBackground)
    }
    
    static var divider: Color {
        Color(UIColor.separator)
    }
    
    static var primaryMuted: Color {
        primary.opacity(0.1)
    }
    
    static var successMuted: Color {
        success.opacity(0.1)
    }
    
    static var warningMuted: Color {
        warning.opacity(0.1)
    }
    
    static var danger: Color {
        error
    }
    
    static var dangerMuted: Color {
        error.opacity(0.1)
    }
}

// MARK: - View Modifier for Theme
public struct ThemedView: ViewModifier {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    public func body(content: Content) -> some View {
        content
            .preferredColorScheme(themeManager.colorScheme)
    }
}

public extension View {
    func themedView() -> some View {
        modifier(ThemedView())
    }
}