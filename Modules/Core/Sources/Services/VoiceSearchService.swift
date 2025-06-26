//
//  VoiceSearchService.swift
//  Core Module
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
//  Dependencies: Speech, AVFoundation
//  Testing: CoreTests/VoiceSearchServiceTests.swift
//
//  Description: Service for voice-based search functionality using Speech framework
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation
import Speech
import AVFoundation
import SwiftUI

/// Service for handling voice search functionality
public class VoiceSearchService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var isRecording = false
    @Published public var isAuthorized = false
    @Published public var transcribedText = ""
    @Published public var error: VoiceSearchError?
    @Published public var audioLevel: Float = 0.0
    
    // MARK: - Private Properties
    
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var audioLevelTimer: Timer?
    
    // MARK: - Initialization
    
    public override init() {
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
        super.init()
        
        speechRecognizer?.delegate = self
        checkAuthorization()
    }
    
    // MARK: - Public Methods
    
    /// Request speech recognition authorization
    public func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self?.isAuthorized = true
                    self?.error = nil
                case .denied:
                    self?.isAuthorized = false
                    self?.error = .authorizationDenied
                case .restricted:
                    self?.isAuthorized = false
                    self?.error = .restricted
                case .notDetermined:
                    self?.isAuthorized = false
                    self?.error = .notDetermined
                @unknown default:
                    self?.isAuthorized = false
                    self?.error = .unknown
                }
            }
        }
    }
    
    /// Start voice recording and transcription
    public func startRecording() throws {
        // Check authorization
        guard isAuthorized else {
            throw VoiceSearchError.notAuthorized
        }
        
        // Check if already recording
        if isRecording {
            stopRecording()
            return
        }
        
        // Cancel any existing task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw VoiceSearchError.requestCreationFailed
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false
        
        // Get audio input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Install tap on audio input
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            
            // Calculate audio level
            self?.updateAudioLevel(from: buffer)
        }
        
        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                DispatchQueue.main.async {
                    self.transcribedText = result.bestTranscription.formattedString
                }
                
                if result.isFinal {
                    self.stopRecording()
                }
            }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.error = .recognitionFailed(error.localizedDescription)
                    self.stopRecording()
                }
            }
        }
        
        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()
        
        // Update state
        DispatchQueue.main.async {
            self.isRecording = true
            self.error = nil
        }
        
        // Start audio level monitoring
        startAudioLevelMonitoring()
    }
    
    /// Stop voice recording
    public func stopRecording() {
        // Stop audio engine
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // Cancel recognition
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        // Clean up
        recognitionRequest = nil
        recognitionTask = nil
        
        // Stop audio level monitoring
        stopAudioLevelMonitoring()
        
        // Update state
        DispatchQueue.main.async {
            self.isRecording = false
            self.audioLevel = 0.0
        }
    }
    
    /// Clear transcribed text
    public func clearTranscription() {
        transcribedText = ""
    }
    
    // MARK: - Private Methods
    
    private func checkAuthorization() {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            isAuthorized = true
        case .denied, .restricted, .notDetermined:
            isAuthorized = false
        @unknown default:
            isAuthorized = false
        }
    }
    
    private func updateAudioLevel(from buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        
        let channelDataValue = channelData.pointee
        let channelDataValueArray = stride(from: 0, to: Int(buffer.frameLength), by: buffer.stride)
            .map { channelDataValue[$0] }
        
        let rms = sqrt(channelDataValueArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
        let avgPower = 20 * log10(rms)
        
        DispatchQueue.main.async {
            self.audioLevel = max(0.0, min(1.0, (avgPower + 50) / 50))
        }
    }
    
    private func startAudioLevelMonitoring() {
        audioLevelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            // Audio level is updated in updateAudioLevel method
            // This timer ensures UI updates happen regularly
        }
    }
    
    private func stopAudioLevelMonitoring() {
        audioLevelTimer?.invalidate()
        audioLevelTimer = nil
    }
}

// MARK: - SFSpeechRecognizerDelegate

extension VoiceSearchService: SFSpeechRecognizerDelegate {
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        DispatchQueue.main.async {
            if !available {
                self.error = .recognizerNotAvailable
                self.stopRecording()
            }
        }
    }
}

// MARK: - Voice Search Errors

public enum VoiceSearchError: LocalizedError, Equatable {
    case notAuthorized
    case authorizationDenied
    case restricted
    case notDetermined
    case recognizerNotAvailable
    case requestCreationFailed
    case recognitionFailed(String)
    case unknown
    
    public var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Speech recognition is not authorized. Please enable it in Settings."
        case .authorizationDenied:
            return "Speech recognition access was denied. Please enable it in Settings."
        case .restricted:
            return "Speech recognition is restricted on this device."
        case .notDetermined:
            return "Speech recognition authorization has not been determined."
        case .recognizerNotAvailable:
            return "Speech recognizer is not available. Please try again later."
        case .requestCreationFailed:
            return "Failed to create speech recognition request."
        case .recognitionFailed(let message):
            return "Speech recognition failed: \(message)"
        case .unknown:
            return "An unknown error occurred."
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .notAuthorized, .authorizationDenied:
            return "Go to Settings > Privacy & Security > Speech Recognition and enable access for Home Inventory."
        case .recognizerNotAvailable:
            return "Make sure you have an active internet connection and try again."
        default:
            return nil
        }
    }
}