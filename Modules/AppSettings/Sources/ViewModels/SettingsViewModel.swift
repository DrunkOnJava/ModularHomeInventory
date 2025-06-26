//
//  SettingsViewModel.swift
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
//  Dependencies: Foundation, Combine, Core
//  Testing: Modules/AppSettings/Tests/ViewModels/SettingsViewModelTests.swift
//
//  Description: Observable view model for managing app settings state with auto-save functionality, conflict detection, and data export capabilities
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation
import Combine
import Core

/// View model for managing settings state
/// Swift 5.9 - No Swift 6 features
@MainActor
public final class SettingsViewModel: ObservableObject {
    @Published public var settings: AppSettings
    @Published public var hasConflicts = false
    @Published public var conflictCount = 0
    
    public let settingsStorage: SettingsStorageProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // Repository references for conflict resolution
    public var itemRepository: (any ItemRepository)?
    public var receiptRepository: (any ReceiptRepository)?
    public var locationRepository: (any LocationRepository)?
    
    public init(
        settingsStorage: SettingsStorageProtocol,
        itemRepository: (any ItemRepository)? = nil,
        receiptRepository: (any ReceiptRepository)? = nil,
        locationRepository: (any LocationRepository)? = nil
    ) {
        self.settingsStorage = settingsStorage
        self.settings = settingsStorage.loadSettings()
        self.itemRepository = itemRepository
        self.receiptRepository = receiptRepository
        self.locationRepository = locationRepository
        
        // Auto-save settings when they change
        $settings
            .dropFirst() // Skip initial value
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] updatedSettings in
                self?.settingsStorage.saveSettings(updatedSettings)
            }
            .store(in: &cancellables)
        
        // Check for conflicts periodically (in a real app)
        checkForConflicts()
    }
    
    // MARK: - Public Methods
    
    func resetToDefaults() {
        settings = AppSettings()
        settingsStorage.saveSettings(settings)
    }
    
    func exportData() {
        // TODO: Implement data export
        print("Export data requested")
    }
    
    func clearCache() {
        // TODO: Implement cache clearing
        print("Clear cache requested")
    }
    
    func saveSettings() {
        settingsStorage.saveSettings(settings)
    }
    
    func checkForConflicts() {
        // In a real app, this would check with the sync service
        // For demo purposes, we'll simulate some conflicts
        Task {
            // Simulate checking for conflicts
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // For demo: randomly show conflicts
            let hasConflicts = Bool.random()
            self.hasConflicts = hasConflicts
            self.conflictCount = hasConflicts ? Int.random(in: 1...5) : 0
        }
    }
}