//
//  AccessibilitySettingsView.swift
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
//  Module: AppSettings
//  Dependencies: SwiftUI, SharedUI, Core
//  Testing: Modules/AppSettings/Tests/SettingsTests/AccessibilitySettingsViewTests.swift
//
//  Description: Accessibility settings view for customizing text size, contrast, and visual options
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import SharedUI
import Core

struct AccessibilitySettingsView: View {
    @StateObject private var settingsWrapper: SettingsStorageWrapper
    
    init(settingsStorage: any SettingsStorageProtocol) {
        self._settingsWrapper = StateObject(wrappedValue: SettingsStorageWrapper(storage: settingsStorage))
    }
    @State private var selectedTextSize: TextSizePreference = .medium
    @State private var showPreview = false
    @Environment(\.sizeCategory) private var sizeCategory
    
    var body: some View {
        List {
            textSizeSection
            previewSection
            additionalSettingsSection
            informationSection
        }
        .navigationTitle("Accessibility")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadCurrentTextSize()
        }
    }
    
    // MARK: - Sections
    
    private var textSizeSection: some View {
        Section {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Text Size")
                    .dynamicTextStyle(.headlineMedium)
                
                Text("Adjust the text size throughout the app to match your preferences.")
                    .dynamicTextStyle(.bodySmall)
                    .foregroundStyle(AppColors.textSecondary)
                
                Picker("Text Size", selection: $selectedTextSize) {
                    ForEach(TextSizePreference.allCases, id: \.self) { size in
                        Text(size.displayName)
                            .tag(size)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedTextSize) { newSize in
                    saveTextSize(newSize)
                }
                
                // Size comparison
                HStack(spacing: AppSpacing.lg) {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Default")
                            .font(.caption)
                            .foregroundStyle(AppColors.textTertiary)
                        Text("Sample Text")
                            .font(.body)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                        Text("Your Size")
                            .font(.caption)
                            .foregroundStyle(AppColors.textTertiary)
                        Text("Sample Text")
                            .environment(\.sizeCategory, selectedTextSize.contentSizeCategory)
                    }
                }
                .appPadding()
                .background(AppColors.secondaryBackground)
                .appCornerRadius(.small)
            }
        } header: {
            Label("Dynamic Type", systemImage: "textformat.size")
        } footer: {
            Text("This overrides your system text size settings within the app.")
                .dynamicTextStyle(.labelSmall)
        }
    }
    
    private var previewSection: some View {
        Section {
            Button(action: { showPreview.toggle() }) {
                HStack {
                    Label("Preview Text Sizes", systemImage: "eye")
                    Spacer()
                    Image(systemName: showPreview ? "chevron.up" : "chevron.down")
                        .font(.footnote)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            
            if showPreview {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Group {
                        Text("Display Large")
                            .dynamicTextStyle(.displayLarge)
                        Text("Headline Medium")
                            .dynamicTextStyle(.headlineMedium)
                        Text("Body Medium")
                            .dynamicTextStyle(.bodyMedium)
                        Text("Label Small")
                            .dynamicTextStyle(.labelSmall)
                    }
                    .environment(\.sizeCategory, selectedTextSize.contentSizeCategory)
                }
                .appPadding()
            }
        }
    }
    
    private var additionalSettingsSection: some View {
        Section {
            Toggle(isOn: bindingForBool(key: .enableBoldText, defaultValue: false)) {
                Label("Bold Text", systemImage: "bold")
            }
            
            Toggle(isOn: bindingForBool(key: .increaseContrast, defaultValue: false)) {
                Label("Increase Contrast", systemImage: "circle.lefthalf.filled")
            }
            
            Toggle(isOn: bindingForBool(key: .reduceTransparency, defaultValue: false)) {
                Label("Reduce Transparency", systemImage: "square.on.square")
            }
            
            Toggle(isOn: bindingForBool(key: .reduceMotion, defaultValue: false)) {
                Label("Reduce Motion", systemImage: "figure.walk.motion")
            }
        } header: {
            Text("Visual Settings")
        } footer: {
            Text("These settings help improve readability and reduce visual complexity.")
                .dynamicTextStyle(.labelSmall)
        }
    }
    
    private var informationSection: some View {
        Section {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundStyle(AppColors.primary)
                NavigationLink(destination: VoiceOverSettingsView(settingsStorage: settingsWrapper.storage)) {
                    Text("Configure VoiceOver settings for enhanced screen reader support.")
                        .dynamicTextStyle(.bodySmall)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            
            HStack {
                Image(systemName: "info.circle")
                    .foregroundStyle(AppColors.primary)
                Text("Use iOS Accessibility settings for additional options like Smart Invert and Display Accommodations.")
                    .dynamicTextStyle(.bodySmall)
                    .foregroundStyle(AppColors.textSecondary)
            }
        } header: {
            Text("Additional Information")
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadCurrentTextSize() {
        if let savedSize = settingsWrapper.string(forKey: .textSizePreference),
           let size = TextSizePreference(rawValue: savedSize) {
            selectedTextSize = size
        } else {
            // Map current system size category to our preference
            selectedTextSize = mapSystemSizeToPreference(sizeCategory)
        }
    }
    
    private func saveTextSize(_ size: TextSizePreference) {
        settingsWrapper.set(size.rawValue, forKey: .textSizePreference)
        
        // Apply to the app immediately
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = window.overrideUserInterfaceStyle
            }
        }
    }
    
    private func mapSystemSizeToPreference(_ category: ContentSizeCategory) -> TextSizePreference {
        switch category {
        case .extraSmall: return .extraSmall
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        case .extraLarge: return .extraLarge
        case .extraExtraLarge: return .extraExtraLarge
        case .extraExtraExtraLarge: return .extraExtraExtraLarge
        default: return .medium
        }
    }
    
    private func bindingForBool(key: SettingsKey, defaultValue: Bool) -> Binding<Bool> {
        Binding(
            get: { settingsWrapper.bool(forKey: key) ?? defaultValue },
            set: { settingsWrapper.set($0, forKey: key) }
        )
    }
}

