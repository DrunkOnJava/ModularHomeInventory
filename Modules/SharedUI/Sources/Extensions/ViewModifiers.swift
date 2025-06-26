//
//  ViewModifiers.swift
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
//  Testing: Modules/SharedUI/Tests/SharedUITests/ViewModifiersTests.swift
//
//  Description: Custom SwiftUI view modifiers for consistent styling across the app
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI

// MARK: - Corner Radius Modifier

public struct CornerRadiusModifier: ViewModifier {
    let size: CornerRadiusSize
    
    public func body(content: Content) -> some View {
        content.cornerRadius(size.value)
    }
}

/// View modifiers for consistent styling
public extension View {
    /// Apply a corner radius from the design system
    func appCornerRadius(_ radius: CGFloat) -> some View {
        self.cornerRadius(radius)
    }
    
    /// Apply a corner radius using semantic size names
    func appCornerRadius(_ size: CornerRadiusSize) -> some View {
        self.modifier(CornerRadiusModifier(size: size))
    }
}

/// Semantic corner radius sizes
public enum CornerRadiusSize {
    case xs
    case small
    case medium
    case large
    case xl
    case full
    
    var value: CGFloat {
        switch self {
        case .xs: return AppCornerRadius.xs
        case .small: return AppCornerRadius.small
        case .medium: return AppCornerRadius.medium
        case .large: return AppCornerRadius.large
        case .xl: return AppCornerRadius.xl
        case .full: return AppCornerRadius.full
        }
    }
}