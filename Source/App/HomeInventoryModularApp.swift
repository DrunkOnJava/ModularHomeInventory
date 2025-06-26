//
//  HomeInventoryModularApp.swift
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
//  Module: Main App Target
//  Dependencies: SwiftUI, SharedUI, Core
//  Testing: HomeInventoryModularTests/HomeInventoryModularAppTests.swift
//
//  Description: Main app entry point with scene configuration and environment setup
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import SharedUI
import Core

@main
struct HomeInventoryModularApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var coordinator = AppCoordinator()
    @StateObject private var settingsStorage = Core.UserDefaultsSettingsStorage()
    @State private var selectedItem: Item?
    @State private var showingItem = false
    
    private let launchOptimizer = AppLaunchOptimizer.shared
    
    init() {
        // Start pre-main tracking
        launchOptimizer.startPhase(.preMain)
        
        // Minimal initialization only
        print("HomeInventory Modular App Starting...")
        
        // Defer iPad configuration
        launchOptimizer.deferWork { [weak launchOptimizer] in
            if UIDevice.current.userInterfaceIdiom == .pad {
                HomeInventoryModularApp.configureiPadFeatures()
            }
        }
        
        // End pre-main phase
        launchOptimizer.endPhase(.preMain)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(coordinator)
                .themedView()
                .onAppear {
                    // Track initial view controller phase
                    launchOptimizer.startPhase(.initialViewController)
                    
                    // Preload critical data
                    Task {
                        await launchOptimizer.preloadCriticalData()
                    }
                }
                .task {
                    // End initial view phase when first frame renders
                    launchOptimizer.endPhase(.initialViewController)
                    launchOptimizer.startPhase(.firstFrame)
                    
                    // Small delay to ensure frame is rendered
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                    
                    launchOptimizer.endPhase(.firstFrame)
                    launchOptimizer.startPhase(.interactive)
                    
                    // App is now interactive
                    launchOptimizer.endPhase(.interactive)
                }
                .onContinueUserActivity(SpotlightService.viewItemActivityType) { userActivity in
                    handleSpotlightActivity(userActivity)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                    handleSpotlightActivity(userActivity)
                }
                .sheet(isPresented: $showingItem) {
                    if let item = selectedItem {
                        coordinator.itemsModule.makeItemDetailView(item: item)
                    }
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
        .commands {
            // iPad keyboard commands
            CommandGroup(after: .newItem) {
                Button("New Window") {
                    // Request new window
                    UIApplication.shared.requestSceneSessionActivation(nil, userActivity: nil, options: nil)
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
        }
    }
    
    private func handleSpotlightActivity(_ userActivity: NSUserActivity) {
        Task { @MainActor in
            if let item = await SpotlightIntegrationManager.shared.handleUserActivity(userActivity) {
                selectedItem = item
                showingItem = true
            }
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        // Handle deep links for multi-window support
        if url.scheme == "homeinventory" {
            // Parse and handle the URL
        }
    }
    
    private static func configureiPadFeatures() {
        // Enable enhanced iPad features
        if #available(iOS 15.0, *) {
            // Enable drag and drop for multi-window
            UIApplication.shared.isIdleTimerDisabled = false
            
            // Configure for multitasking
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.sizeRestrictions?.minimumSize = CGSize(width: 320, height: 480)
                windowScene.sizeRestrictions?.maximumSize = CGSize(width: CGFloat.infinity, height: CGFloat.infinity)
            }
        }
    }
}