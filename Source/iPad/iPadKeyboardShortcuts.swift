//
//  iPadKeyboardShortcuts.swift
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
//  Dependencies: SwiftUI, UIKit
//  Testing: HomeInventoryModularTests/iPadKeyboardShortcutsTests.swift
//
//  Description: Comprehensive keyboard shortcuts and navigation for iPad productivity
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import UIKit

/// Keyboard shortcuts for iPad
/// Provides comprehensive keyboard navigation and shortcuts
struct iPadKeyboardShortcutsModifier: ViewModifier {
    @ObservedObject var navigationState: IPadNavigationState
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                // Register for keyboard shortcuts
                setupKeyCommands()
            }
            // Navigation shortcuts
            .keyboardShortcut("n", modifiers: .command)
            .keyboardShortcut("f", modifiers: .command)
            .keyboardShortcut("1", modifiers: .command)
            .keyboardShortcut("2", modifiers: .command)
            .keyboardShortcut("3", modifiers: .command)
            .keyboardShortcut("4", modifiers: .command)
            .keyboardShortcut(",", modifiers: .command)
            .keyboardShortcut("r", modifiers: .command)
            .keyboardShortcut("e", modifiers: .command)
            .keyboardShortcut("i", modifiers: [.command, .shift])
            .keyboardShortcut("d", modifiers: .command)
            .keyboardShortcut(.delete, modifiers: .command)
            .keyboardShortcut(.escape)
            .keyboardShortcut(.space)
            .onChange(of: navigationState.selectedTab) { _, newTab in
                handleTabChange(newTab)
            }
            .onReceive(NotificationCenter.default.publisher(for: .keyboardShortcutTriggered)) { notification in
                if let shortcut = notification.object as? String {
                    handleKeyboardShortcut(shortcut)
                }
            }
    }
    
    private func setupKeyCommands() {
        // This will be handled by the app's key command system
    }
    
    private func handleTabChange(_ tab: IPadTab) {
        // Handle tab changes
    }
    
    private func handleKeyboardShortcut(_ shortcut: String) {
        switch shortcut {
        case "cmd+n":
            navigationState.showAddItem = true
        case "cmd+f":
            navigationState.selectedTab = .search
            isSearchFocused = true
        case "cmd+1":
            navigationState.selectedTab = .items
        case "cmd+2":
            navigationState.selectedTab = .insurance
        case "cmd+3":
            navigationState.selectedTab = .analytics
        case "cmd+4":
            navigationState.selectedTab = .scanner
        case "cmd+,":
            navigationState.selectedTab = .settings
        case "cmd+r":
            NotificationCenter.default.post(name: .refreshData, object: nil)
        case "cmd+e":
            navigationState.showExport = true
        case "cmd+shift+i":
            navigationState.showImport = true
        case "cmd+d":
            if navigationState.selectedItem != nil {
                navigationState.showDuplicate = true
            }
        case "cmd+delete":
            if navigationState.selectedItem != nil {
                navigationState.showDeleteConfirmation = true
            }
        case "escape":
            navigationState.selectedItem = nil
            navigationState.selectedInsurancePolicy = nil
            navigationState.selectedLocation = nil
            isSearchFocused = false
        case "space":
            if navigationState.selectedItem != nil {
                navigationState.showQuickLook = true
            }
        default:
            break
        }
    }
}

// MARK: - Keyboard Commands

extension iPadKeyboardShortcutsModifier {
    static func buildCommands() -> some Commands {
        Group {
            CommandGroup(after: .newItem) {
                Button("New Item") {
                    NotificationCenter.default.post(
                        name: .keyboardShortcutTriggered,
                        object: "cmd+n"
                    )
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button("Duplicate Item") {
                    NotificationCenter.default.post(
                        name: .keyboardShortcutTriggered,
                        object: "cmd+d"
                    )
                }
                .keyboardShortcut("d", modifiers: .command)
                .disabled(true) // Will be enabled when item is selected
            }
            
            CommandGroup(replacing: .sidebar) {
                Button("Toggle Sidebar") {
                    NotificationCenter.default.post(
                        name: .keyboardShortcutTriggered,
                        object: "cmd+ctrl+s"
                    )
                }
                .keyboardShortcut("s", modifiers: [.command, .control])
            }
            
            CommandMenu("Navigate") {
                Button("Items") {
                    NotificationCenter.default.post(
                        name: .keyboardShortcutTriggered,
                        object: "cmd+1"
                    )
                }
                .keyboardShortcut("1", modifiers: .command)
                
                Button("Collections") {
                    NotificationCenter.default.post(
                        name: .keyboardShortcutTriggered,
                        object: "cmd+2"
                    )
                }
                .keyboardShortcut("2", modifiers: .command)
                
                Button("Analytics") {
                    NotificationCenter.default.post(
                        name: .keyboardShortcutTriggered,
                        object: "cmd+3"
                    )
                }
                .keyboardShortcut("3", modifiers: .command)
                
                Button("Scanner") {
                    NotificationCenter.default.post(
                        name: .keyboardShortcutTriggered,
                        object: "cmd+4"
                    )
                }
                .keyboardShortcut("4", modifiers: .command)
            }
        }
    }
}

// MARK: - Keyboard Navigation

struct KeyboardNavigationModifier: ViewModifier {
    enum FocusableField: Hashable {
        case searchField
        case nameField
        case priceField
        case quantityField
        case notesField
    }
    
    @FocusState private var focusedField: FocusableField?
    
    func body(content: Content) -> some View {
        content
            .focused($focusedField, equals: .searchField)
            .onKeyPress(.tab) {
                handleTabNavigation(forward: true)
                return .handled
            }
            .onKeyPress(.tab, phases: .down) { press in
                if press.modifiers.contains(.shift) {
                    handleTabNavigation(forward: false)
                    return .handled
                }
                return .ignored
            }
            .onKeyPress(.return) {
                handleReturnKey()
                return .handled
            }
    }
    
    private func handleTabNavigation(forward: Bool) {
        let fields: [FocusableField] = [.searchField, .nameField, .priceField, .quantityField, .notesField]
        
        guard let currentIndex = fields.firstIndex(where: { $0 == focusedField }) else {
            focusedField = forward ? fields.first : fields.last
            return
        }
        
        if forward {
            let nextIndex = (currentIndex + 1) % fields.count
            focusedField = fields[nextIndex]
        } else {
            let previousIndex = currentIndex == 0 ? fields.count - 1 : currentIndex - 1
            focusedField = fields[previousIndex]
        }
    }
    
    private func handleReturnKey() {
        // Submit form or move to next field
        switch focusedField {
        case .searchField:
            // Trigger search
            break
        case .notesField:
            // Allow multiline in notes
            break
        default:
            // Move to next field
            handleTabNavigation(forward: true)
        }
    }
}

// MARK: - Keyboard Shortcut Help

struct KeyboardShortcutHelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Navigation") {
                    ShortcutRow(key: "⌘1", description: "Jump to Items")
                    ShortcutRow(key: "⌘2", description: "Jump to Collections")
                    ShortcutRow(key: "⌘3", description: "Jump to Analytics")
                    ShortcutRow(key: "⌘4", description: "Jump to Scanner")
                    ShortcutRow(key: "⌘,", description: "Open Settings")
                }
                
                Section("Item Management") {
                    ShortcutRow(key: "⌘N", description: "New Item")
                    ShortcutRow(key: "⌘D", description: "Duplicate Item")
                    ShortcutRow(key: "⌘⌫", description: "Delete Item")
                    ShortcutRow(key: "Space", description: "Quick Look")
                }
                
                Section("Search & Filter") {
                    ShortcutRow(key: "⌘F", description: "Search")
                    ShortcutRow(key: "Esc", description: "Clear Search/Dismiss")
                }
                
                Section("Import/Export") {
                    ShortcutRow(key: "⌘⇧I", description: "Import")
                    ShortcutRow(key: "⌘E", description: "Export")
                }
                
                Section("View Controls") {
                    ShortcutRow(key: "⌘R", description: "Refresh")
                    ShortcutRow(key: "⌘^S", description: "Toggle Sidebar")
                    ShortcutRow(key: "⌘/", description: "Show This Help")
                }
            }
            .navigationTitle("Keyboard Shortcuts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ShortcutRow: View {
    let key: String
    let description: String
    
    var body: some View {
        HStack {
            Text(key)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.blue)
                .frame(minWidth: 80, alignment: .leading)
            
            Text(description)
                .foregroundStyle(.primary)
            
            Spacer()
        }
    }
}

// MARK: - Extensions

extension View {
    func iPadKeyboardShortcuts(navigationState: IPadNavigationState) -> ModifiedContent<Self, iPadKeyboardShortcutsModifier> {
        self.modifier(iPadKeyboardShortcutsModifier(navigationState: navigationState))
    }
    
    func keyboardNavigation() -> ModifiedContent<Self, KeyboardNavigationModifier> {
        self.modifier(KeyboardNavigationModifier())
    }
}

extension Notification.Name {
    static let keyboardShortcutTriggered = Notification.Name("keyboardShortcutTriggered")
    static let refreshData = Notification.Name("refreshData")
}