//
//  VoiceSearchButton.swift
//  SharedUI Module
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
//  Module: SharedUI
//  Dependencies: SwiftUI, Core
//  Testing: SharedUITests/VoiceSearchButtonTests.swift
//
//  Description: Voice search button component with visual feedback
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core

/// Voice search button with recording animation
public struct VoiceSearchButton: View {
    @StateObject private var voiceSearch = VoiceSearchService()
    @Binding var searchText: String
    @State private var showingError = false
    @State private var pulseAnimation = false
    
    let onCommit: () -> Void
    
    public init(
        searchText: Binding<String>,
        onCommit: @escaping () -> Void = {}
    ) {
        self._searchText = searchText
        self.onCommit = onCommit
    }
    
    public var body: some View {
        Button(action: toggleRecording) {
            ZStack {
                // Background circle with pulse animation
                if voiceSearch.isRecording {
                    Circle()
                        .fill(Color.red.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 0.5)
                                .repeatForever(autoreverses: true),
                            value: pulseAnimation
                        )
                }
                
                // Main button circle
                Circle()
                    .fill(voiceSearch.isRecording ? Color.red : Color.blue)
                    .frame(width: 44, height: 44)
                
                // Microphone icon
                Image(systemName: voiceSearch.isRecording ? "mic.fill" : "mic")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                
                // Audio level indicator
                if voiceSearch.isRecording {
                    AudioLevelIndicator(level: voiceSearch.audioLevel)
                        .frame(width: 80, height: 80)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!voiceSearch.isAuthorized)
        .opacity(voiceSearch.isAuthorized ? 1.0 : 0.6)
        .onAppear {
            if !voiceSearch.isAuthorized {
                voiceSearch.requestAuthorization()
            }
        }
        .onChange(of: voiceSearch.isRecording) { isRecording in
            withAnimation {
                pulseAnimation = isRecording
            }
        }
        .onChange(of: voiceSearch.transcribedText) { newText in
            searchText = newText
            if !voiceSearch.isRecording && !newText.isEmpty {
                onCommit()
            }
        }
        .alert("Voice Search Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
            if voiceSearch.error?.recoverySuggestion != nil {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        } message: {
            if let error = voiceSearch.error {
                Text(error.localizedDescription)
                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                }
            }
        }
        .onChange(of: voiceSearch.error) { error in
            showingError = error != nil
        }
    }
    
    private func toggleRecording() {
        if voiceSearch.isRecording {
            voiceSearch.stopRecording()
        } else {
            do {
                try voiceSearch.startRecording()
            } catch {
                voiceSearch.error = error as? VoiceSearchError ?? .unknown
            }
        }
    }
}

// MARK: - Audio Level Indicator

struct AudioLevelIndicator: View {
    let level: Float
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<3) { ring in
                    Circle()
                        .stroke(
                            Color.white.opacity(0.5 - Double(ring) * 0.15),
                            lineWidth: 2
                        )
                        .scaleEffect(1.0 + CGFloat(ring) * 0.3 + CGFloat(level) * 0.5)
                        .opacity(Double(1.0 - Float(ring) * 0.3) * Double(level))
                        .animation(
                            Animation.easeOut(duration: 0.3),
                            value: level
                        )
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

// MARK: - Voice Search Sheet

public struct VoiceSearchSheet: View {
    @StateObject private var voiceSearch = VoiceSearchService()
    @Binding var searchText: String
    @Binding var isPresented: Bool
    @State private var showingError = false
    
    let onCommit: () -> Void
    
    public init(
        searchText: Binding<String>,
        isPresented: Binding<Bool>,
        onCommit: @escaping () -> Void = {}
    ) {
        self._searchText = searchText
        self._isPresented = isPresented
        self.onCommit = onCommit
    }
    
    public var body: some View {
        VStack(spacing: 30) {
            // Title
            Text("Voice Search")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Voice animation
            ZStack {
                // Background circles
                ForEach(0..<3) { index in
                    let size = 150 + CGFloat(index * 50)
                    let scale = voiceSearch.isRecording ? 1.1 : 1.0
                    
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: size, height: size)
                        .scaleEffect(scale)
                        .animation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: voiceSearch.isRecording
                        )
                }
                
                // Main button
                Button(action: toggleRecording) {
                    ZStack {
                        Circle()
                            .fill(voiceSearch.isRecording ? Color.red : Color.blue)
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: voiceSearch.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // Audio level visualization
                if voiceSearch.isRecording {
                    AudioWaveform(level: voiceSearch.audioLevel)
                        .frame(width: 200, height: 100)
                        .offset(y: 120)
                }
            }
            
            // Instructions or transcription
            VStack(spacing: 8) {
                if voiceSearch.isRecording {
                    Text("Listening...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if !voiceSearch.transcribedText.isEmpty {
                        Text(voiceSearch.transcribedText)
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .frame(minHeight: 60)
                    }
                } else if !voiceSearch.transcribedText.isEmpty {
                    Text(voiceSearch.transcribedText)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    HStack(spacing: 20) {
                        Button("Clear") {
                            voiceSearch.clearTranscription()
                            searchText = ""
                        }
                        .foregroundColor(.red)
                        
                        Button("Search") {
                            searchText = voiceSearch.transcribedText
                            isPresented = false
                            onCommit()
                        }
                        .fontWeight(.semibold)
                    }
                    .padding(.top)
                } else {
                    Text("Tap the microphone to start")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Cancel button
            Button("Cancel") {
                voiceSearch.stopRecording()
                isPresented = false
            }
            .foregroundColor(.secondary)
        }
        .padding()
        .onAppear {
            if !voiceSearch.isAuthorized {
                voiceSearch.requestAuthorization()
            }
        }
        .onDisappear {
            voiceSearch.stopRecording()
        }
        .alert("Voice Search Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
            if voiceSearch.error?.recoverySuggestion != nil {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        } message: {
            if let error = voiceSearch.error {
                Text(error.localizedDescription)
                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                }
            }
        }
        .onChange(of: voiceSearch.error) { error in
            showingError = error != nil
        }
    }
    
    private func toggleRecording() {
        if voiceSearch.isRecording {
            voiceSearch.stopRecording()
        } else {
            do {
                try voiceSearch.startRecording()
            } catch {
                voiceSearch.error = error as? VoiceSearchError ?? .unknown
            }
        }
    }
}

// MARK: - Audio Waveform

struct AudioWaveform: View {
    let level: Float
    @State private var phase: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let midHeight = height / 2
                
                path.move(to: CGPoint(x: 0, y: midHeight))
                
                for x in stride(from: 0, to: width, by: 2) {
                    let relativeX = x / width
                    let sine = sin(relativeX * .pi * 4 + phase) * CGFloat(level) * 30
                    path.addLine(to: CGPoint(x: x, y: midHeight + sine))
                }
            }
            .stroke(Color.blue, lineWidth: 2)
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 2)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = .pi * 2
                }
            }
        }
    }
}