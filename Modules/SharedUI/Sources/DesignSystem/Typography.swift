//
//  Typography.swift
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
//  Dependencies: SwiftUI
//  Testing: Modules/SharedUI/Tests/SharedUITests/TypographyTests.swift
//
//  Description: Typography system with predefined text styles supporting Dynamic Type for accessibility
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI

/// Typography system with predefined text styles
/// Updated to support Dynamic Type
public struct AppTypography {
    // MARK: - Display
    public static func displayLarge(_ text: String) -> some View {
        Text(text)
            .dynamicTextStyle(.displayLarge)
    }
    
    public static func displayMedium(_ text: String) -> some View {
        Text(text)
            .dynamicTextStyle(.displayMedium)
    }
    
    public static func displaySmall(_ text: String) -> some View {
        Text(text)
            .dynamicTextStyle(.displaySmall)
    }
    
    // MARK: - Headline
    public static func headlineLarge(_ text: String) -> some View {
        Text(text)
            .dynamicTextStyle(.headlineLarge)
    }
    
    public static func headlineMedium(_ text: String) -> some View {
        Text(text)
            .dynamicTextStyle(.headlineMedium)
    }
    
    public static func headlineSmall(_ text: String) -> some View {
        Text(text)
            .dynamicTextStyle(.headlineSmall)
    }
    
    // MARK: - Body
    public static func bodyLarge(_ text: String) -> some View {
        Text(text)
            .dynamicTextStyle(.bodyLarge)
    }
    
    public static func bodyMedium(_ text: String) -> some View {
        Text(text)
            .dynamicTextStyle(.bodyMedium)
    }
    
    public static func bodySmall(_ text: String) -> some View {
        Text(text)
            .dynamicTextStyle(.bodySmall)
    }
    
    // MARK: - Label
    public static func labelLarge(_ text: String) -> some View {
        Text(text)
            .dynamicTextStyle(.labelLarge)
    }
    
    public static func labelMedium(_ text: String) -> some View {
        Text(text)
            .dynamicTextStyle(.labelMedium)
    }
    
    public static func labelSmall(_ text: String) -> some View {
        Text(text)
            .dynamicTextStyle(.labelSmall)
    }
}

// MARK: - Text Style View Modifier (Deprecated - Use dynamicTextStyle instead)
@available(*, deprecated, message: "Use dynamicTextStyle for Dynamic Type support")
public struct TextStyle: ViewModifier {
    public enum Style {
        case displayLarge, displayMedium, displaySmall
        case headlineLarge, headlineMedium, headlineSmall
        case bodyLarge, bodyMedium, bodySmall
        case labelLarge, labelMedium, labelSmall
        
        var font: Font {
            switch self {
            case .displayLarge: return .system(size: 34, weight: .bold)
            case .displayMedium: return .system(size: 28, weight: .semibold)
            case .displaySmall: return .system(size: 22, weight: .semibold)
            case .headlineLarge: return .system(size: 20, weight: .semibold)
            case .headlineMedium: return .system(size: 17, weight: .semibold)
            case .headlineSmall: return .system(size: 15, weight: .semibold)
            case .bodyLarge: return .system(size: 17, weight: .regular)
            case .bodyMedium: return .system(size: 15, weight: .regular)
            case .bodySmall: return .system(size: 13, weight: .regular)
            case .labelLarge: return .system(size: 13, weight: .medium)
            case .labelMedium: return .system(size: 11, weight: .medium)
            case .labelSmall: return .system(size: 10, weight: .medium)
            }
        }
    }
    
    let style: Style
    
    public func body(content: Content) -> some View {
        content.font(style.font)
    }
}

public extension View {
    /// Apply text style with Dynamic Type support
    func textStyle(_ style: DynamicTextStyle.Style) -> some View {
        modifier(DynamicTextStyle(style: style))
    }
}