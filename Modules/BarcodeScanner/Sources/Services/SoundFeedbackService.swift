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