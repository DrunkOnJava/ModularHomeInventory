//
//  Spacing.swift
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
//  Dependencies: Foundation, SwiftUI
//  Testing: Modules/SharedUI/Tests/SharedUITests/SpacingTests.swift
//
//  Description: Design system spacing constants based on 8pt grid for consistent layouts
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation
import SwiftUI

/// Spacing system based on 8pt grid
public struct AppSpacing {
    /// 4pt
    public static let xxs: CGFloat = 4
    
    /// 8pt
    public static let xs: CGFloat = 8
    
    /// 12pt
    public static let sm: CGFloat = 12
    
    /// 16pt
    public static let md: CGFloat = 16
    
    /// 24pt
    public static let lg: CGFloat = 24
    
    /// 32pt
    public static let xl: CGFloat = 32
    
    /// 48pt
    public static let xxl: CGFloat = 48
    
    /// 64pt
    public static let xxxl: CGFloat = 64
}

/// Padding view modifier for consistent spacing
public struct AppPadding: ViewModifier {
    let edges: Edge.Set
    let spacing: CGFloat
    
    public func body(content: Content) -> some View {
        content.padding(edges, spacing)
    }
}

public extension View {
    /// Apply padding with app spacing values
    func appPadding(_ edges: Edge.Set = .all, _ spacing: CGFloat = AppSpacing.md) -> some View {
        modifier(AppPadding(edges: edges, spacing: spacing))
    }
}