//
//  BarcodeFormatSettingsView.swift
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
//  Dependencies: SwiftUI, Core, SharedUI
//  Testing: Modules/AppSettings/Tests/SettingsTests/BarcodeFormatSettingsViewTests.swift
//
//  Description: Settings view for managing enabled barcode format types and scanner configuration
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core
import SharedUI

/// View for managing enabled barcode formats
/// Swift 5.9 - No Swift 6 features
struct BarcodeFormatSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var searchText = ""
    @State private var selectedGroup: BarcodeFormat.FormatGroup?
    
    var body: some View {
        NavigationView {
            List {
                // Quick Actions
                Section {
                    HStack {
                        Button("Enable All") {
                            enableAllFormats()
                        }
                        .foregroundStyle(AppColors.primary)
                        
                        Spacer()
                        
                        Button("Reset to Common") {
                            resetToCommonFormats()
                        }
                        .foregroundStyle(AppColors.textSecondary)
                    }
                    .appPadding(.vertical, AppSpacing.xs)
                }
                
                // Format Groups
                Section("Format Groups") {
                    ForEach(BarcodeFormat.FormatGroup.allCases, id: \.self) { group in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(group.rawValue)
                                    .textStyle(.bodyLarge)
                                Text("\(group.formats.count) formats")
                                    .textStyle(.bodySmall)
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                            
                            Spacer()
                            
                            if selectedGroup == group {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppColors.primary)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedGroup = group
                        }
                    }
                }
                
                // Individual Formats
                Section("Individual Formats") {
                    ForEach(filteredFormats, id: \.metadataObjectType) { format in
                        BarcodeFormatRow(
                            format: format,
                            isEnabled: isFormatEnabled(format),
                            onToggle: { enabled in
                                toggleFormat(format, enabled: enabled)
                            }
                        )
                    }
                }
                
                // Statistics
                Section {
                    HStack {
                        Text("Enabled Formats")
                            .textStyle(.bodyMedium)
                        Spacer()
                        Text("\(viewModel.settings.enabledBarcodeFormats.count) of \(BarcodeFormat.allFormats.count)")
                            .textStyle(.bodyMedium)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search formats")
            .navigationTitle("Barcode Formats")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var filteredFormats: [BarcodeFormat] {
        let formats = selectedGroup?.formats ?? BarcodeFormat.allFormats
        
        if searchText.isEmpty {
            return formats
        }
        
        return formats.filter { format in
            format.name.localizedCaseInsensitiveContains(searchText) ||
            format.description.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private func isFormatEnabled(_ format: BarcodeFormat) -> Bool {
        viewModel.settings.enabledBarcodeFormats.contains(
            format.metadataObjectType.rawValue
        )
    }
    
    private func toggleFormat(_ format: BarcodeFormat, enabled: Bool) {
        var formats = Set(viewModel.settings.enabledBarcodeFormats)
        if enabled {
            formats.insert(format.metadataObjectType.rawValue)
        } else {
            formats.remove(format.metadataObjectType.rawValue)
        }
        viewModel.settings.enabledBarcodeFormats = Array(formats)
        viewModel.saveSettings()
    }
    
    private func enableAllFormats() {
        viewModel.settings.enabledBarcodeFormats = BarcodeFormat.allFormats.map {
            $0.metadataObjectType.rawValue
        }
        viewModel.saveSettings()
    }
    
    private func resetToCommonFormats() {
        viewModel.settings.enabledBarcodeFormats = BarcodeFormat.commonMetadataTypes.map {
            $0.rawValue
        }
        viewModel.saveSettings()
    }
}

// MARK: - Format Row
struct BarcodeFormatRow: View {
    let format: BarcodeFormat
    let isEnabled: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        Toggle(isOn: Binding(
            get: { isEnabled },
            set: { onToggle($0) }
        )) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack {
                    Text(format.name)
                        .textStyle(.bodyLarge)
                    
                    if format.isCommon {
                        Text("Common")
                            .textStyle(.labelSmall)
                            .foregroundStyle(AppColors.primary)
                            .appPadding(.horizontal, AppSpacing.xs)
                            .appPadding(.vertical, 2)
                            .background(AppColors.primary.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                Text(format.description)
                    .textStyle(.bodySmall)
                    .foregroundStyle(AppColors.textSecondary)
                
                Text("Example: \(format.example)")
                    .textStyle(.bodySmall)
                    .foregroundStyle(AppColors.textSecondary)
                    .fontDesign(.monospaced)
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: AppColors.primary))
    }
}

// MARK: - Preview
#Preview {
    BarcodeFormatSettingsView(viewModel: SettingsViewModel(
        settingsStorage: UserDefaultsSettingsStorage()
    ))
}