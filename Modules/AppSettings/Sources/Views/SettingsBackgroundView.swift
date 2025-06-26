//
//  SettingsBackgroundView.swift
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
//  Dependencies: SwiftUI, SharedUI
//  Testing: Modules/AppSettings/Tests/Views/SettingsBackgroundViewTests.swift
//
//  Description: Sophisticated animated background gradient view with floating shapes and pattern overlays for settings interface
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import SharedUI

/// Sophisticated background gradient for settings
struct SettingsBackgroundView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base gradient
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Subtle pattern overlay
                PatternOverlay()
                    .opacity(0.03)
                    .ignoresSafeArea()
                
                // Floating shapes
                FloatingShapes()
                    .opacity(0.05)
                    .ignoresSafeArea()
            }
        }
    }
    
    private var gradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(white: 0.1),
                Color(white: 0.05)
            ]
        } else {
            return [
                Color(white: 0.98),
                Color(white: 0.94)
            ]
        }
    }
}

struct PatternOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let size: CGFloat = 40
                let cols = Int(geometry.size.width / size) + 1
                let rows = Int(geometry.size.height / size) + 1
                
                for row in 0..<rows {
                    for col in 0..<cols {
                        let x = CGFloat(col) * size
                        let y = CGFloat(row) * size
                        
                        // Create a subtle dot pattern
                        path.addEllipse(in: CGRect(x: x, y: y, width: 2, height: 2))
                    }
                }
            }
            .fill(Color.primary)
        }
    }
}

struct FloatingShapes: View {
    @State private var isAnimating = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Circle 1
                Circle()
                    .fill(LinearGradient(
                        colors: [AppColors.primary.opacity(0.3), AppColors.primary.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 300, height: 300)
                    .offset(x: -100, y: -100)
                    .blur(radius: 40)
                    .offset(y: isAnimating ? -20 : 20)
                    .animation(
                        Animation.easeInOut(duration: 8)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                // Circle 2
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.purple.opacity(0.3), Color.purple.opacity(0.1)],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    ))
                    .frame(width: 250, height: 250)
                    .offset(x: geometry.size.width - 100, y: geometry.size.height - 200)
                    .blur(radius: 40)
                    .offset(x: isAnimating ? -20 : 20)
                    .animation(
                        Animation.easeInOut(duration: 10)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                // Circle 3
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(width: 200, height: 200)
                    .offset(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    .blur(radius: 30)
                    .scaleEffect(isAnimating ? 1.1 : 0.9)
                    .animation(
                        Animation.easeInOut(duration: 6)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    SettingsBackgroundView()
}