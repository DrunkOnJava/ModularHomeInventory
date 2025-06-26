//
//  SoundFeedbackService.swift
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
//  Module: BarcodeScanner
//  Dependencies: AVFoundation, UIKit, Core, AppSettings
//  Testing: Modules/BarcodeScanner/Tests/ScannerTests/SoundFeedbackServiceTests.swift
//
//  Description: Service for providing audio and haptic feedback during barcode scanning,
//               including success sounds and error notifications
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

//
//  SoundFeedbackService.swift
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
//  Module: BarcodeScanner
//  Dependencies: AVFoundation, UIKit, Core, AppSettings
//  Testing: N/A (Service class - unit testing recommended)
//
//  Description: Service for providing audio and haptic feedback during barcode scanning operations.
//  This service plays system sounds and provides haptic feedback for successful scans and errors,
//  with settings integration to enable/disable feedback based on user preferences.
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import AVFoundation
import UIKit
import Core
import AppSettings

/// Service for playing scanner sound effects
/// Swift 5.9 - No Swift 6 features
@MainActor
public final class SoundFeedbackService {
    private var soundPlayer: AVAudioPlayer?
    private let settingsStorage: any SettingsStorageProtocol
    
    public init(settingsStorage: any SettingsStorageProtocol) {
        self.settingsStorage = settingsStorage
        setupSound()
    }
    
    private func setupSound() {
        // Create a simple beep sound using system sound
        // In a production app, you would load a sound file from the bundle
        // For now, we'll use the system notification sound
    }
    
    public func playSuccessSound() {
        // Check if sound is enabled in settings
        let settings = settingsStorage.loadSettings()
        guard settings.scannerSoundEnabled else { return }
        
        // Play success sound
        // Using system sound for now - in production, use a custom sound file
        AudioServicesPlaySystemSound(1057) // System sound ID for "Tink"
        
        // Also provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    public func playErrorSound() {
        // Check if sound is enabled in settings
        let settings = settingsStorage.loadSettings()
        guard settings.scannerSoundEnabled else { return }
        
        // Play error sound
        AudioServicesPlaySystemSound(1053) // System sound ID for error
        
        // Also provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
}

// MARK: - System Sound IDs Reference
// Common system sound IDs that can be used:
// 1057 - Tink (success)
// 1053 - Error
// 1054 - Key press click
// 1055 - Lock
// 1056 - Unlock
// 1103 - Begin recording
// 1104 - End recording
// 1105 - JBL Begin
// 1106 - JBL Confirm
// 1107 - JBL Cancel
// 1108 - Begin video recording
// 1109 - End video recording
// 1110 - VC Invitation Accepted
// 1111 - VC Ringing
// 1112 - VC Ended
// 1113 - VC Call Waiting
// 1114 - VC Call Upgrade
// 1115 - Photostream Activity
// 1116 - Ringer Vibrate Changed
// 1117 - Silent Vibrate Changed
// 1118 - Vibrate