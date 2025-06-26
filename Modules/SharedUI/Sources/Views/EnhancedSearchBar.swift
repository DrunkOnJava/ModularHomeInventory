//
//  EnhancedSearchBar.swift
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
//  Testing: SharedUITests/EnhancedSearchBarTests.swift
//
//  Description: Enhanced search bar with voice search support
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core

/// Enhanced search bar with voice search capability
public struct EnhancedSearchBar: View {
    @Binding var text: String
    let placeholder: String
    let onEditingChanged: ((Bool) -> Void)?
    let onCommit: (() -> Void)?
    
    @FocusState private var isFocused: Bool
    @State private var showingVoiceSearch = false
    
    public init(
        text: Binding<String>,
        placeholder: String = "Search",
        onEditingChanged: ((Bool) -> Void)? = nil,
        onCommit: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.onEditingChanged = onEditingChanged
        self.onCommit = onCommit
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .onSubmit {
                        onCommit?()
                    }
                    .onChange(of: isFocused) { newValue in
                        onEditingChanged?(newValue)
                    }
                
                if !text.isEmpty {
                    Button(action: {
                        text = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // Voice search button
            Button(action: {
                showingVoiceSearch = true
            }) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                    .frame(width: 36, height: 36)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }
        }
        .sheet(isPresented: $showingVoiceSearch) {
            VoiceSearchSheet(
                searchText: $text,
                isPresented: $showingVoiceSearch,
                onCommit: {
                    onCommit?()
                }
            )
        }
    }
}

// MARK: - Inline Voice Search Bar

public struct InlineVoiceSearchBar: View {
    @Binding var text: String
    let placeholder: String
    let onCommit: (() -> Void)?
    
    @StateObject private var voiceSearch = VoiceSearchService()
    @FocusState private var isFocused: Bool
    @State private var showingError = false
    
    public init(
        text: Binding<String>,
        placeholder: String = "Search or speak",
        onCommit: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.onCommit = onCommit
    }
    
    public var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .onSubmit {
                    onCommit?()
                }
            
            Spacer()
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
            
            // Inline voice button
            Button(action: toggleVoiceSearch) {
                Image(systemName: voiceSearch.isRecording ? "mic.fill" : "mic")
                    .foregroundStyle(voiceSearch.isRecording ? .red : .blue)
                    .symbolEffect(.bounce, value: voiceSearch.isRecording)
            }
            .disabled(!voiceSearch.isAuthorized)
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(voiceSearch.isRecording ? Color.red : Color.clear, lineWidth: 2)
                .animation(.easeInOut(duration: 0.3), value: voiceSearch.isRecording)
        )
        .onAppear {
            if !voiceSearch.isAuthorized {
                voiceSearch.requestAuthorization()
            }
        }
        .onChange(of: voiceSearch.transcribedText) { newText in
            if !newText.isEmpty {
                text = newText
                if !voiceSearch.isRecording {
                    onCommit?()
                }
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
    
    private func toggleVoiceSearch() {
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