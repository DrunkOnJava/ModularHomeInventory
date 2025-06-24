import SwiftUI
import UIKit

/// Keyboard shortcuts for iPad
/// Provides comprehensive keyboard navigation and shortcuts
struct iPadKeyboardShortcuts: ViewModifier {
    @ObservedObject var navigationState: iPadNavigationState
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                // Register for keyboard shortcuts
                setupKeyCommands()
            }
            .keyboardShortcut("n", modifiers: .command) {
                // New item
                navigationState.showAddItem = true
            }
            .keyboardShortcut("f", modifiers: .command) {
                // Find/Search
                navigationState.selectedTab = .search
                isSearchFocused = true
            }
            .keyboardShortcut("1", modifiers: .command) {
                // Jump to Items
                navigationState.selectedTab = .items
            }
            .keyboardShortcut("2", modifiers: .command) {
                // Jump to Collections
                navigationState.selectedTab = .collections
            }
            .keyboardShortcut("3", modifiers: .command) {
                // Jump to Analytics
                navigationState.selectedTab = .analytics
            }
            .keyboardShortcut("4", modifiers: .command) {
                // Jump to Scanner
                navigationState.selectedTab = .scanner
            }
            .keyboardShortcut(",", modifiers: .command) {
                // Settings
                navigationState.selectedTab = .settings
            }
            .keyboardShortcut("r", modifiers: .command) {
                // Refresh
                NotificationCenter.default.post(name: .refreshData, object: nil)
            }
            .keyboardShortcut("e", modifiers: .command) {
                // Export
                navigationState.selectedTab = .importExport
            }
            .keyboardShortcut("i", modifiers: [.command, .shift]) {
                // Import
                navigationState.selectedTab = .importExport
            }
            .keyboardShortcut("d", modifiers: .command) {
                // Duplicate selected item
                if let item = navigationState.selectedItem {
                    NotificationCenter.default.post(
                        name: .duplicateItem,
                        object: nil,
                        userInfo: ["item": item]
                    )
                }
            }
            .keyboardShortcut(.delete, modifiers: .command) {
                // Delete selected item
                if let item = navigationState.selectedItem {
                    NotificationCenter.default.post(
                        name: .deleteItem,
                        object: nil,
                        userInfo: ["item": item]
                    )
                }
            }
            .keyboardShortcut(.escape) {
                // Dismiss sheets/close detail
                navigationState.showAddItem = false
                navigationState.selectedItem = nil
            }
            .keyboardShortcut(.space) {
                // Quick look selected item
                if let item = navigationState.selectedItem {
                    NotificationCenter.default.post(
                        name: .quickLookItem,
                        object: nil,
                        userInfo: ["item": item]
                    )
                }
            }
    }
    
    private func setupKeyCommands() {
        // Additional setup if needed
    }
}

// MARK: - Keyboard Command Builder

struct KeyboardCommandBuilder {
    static func buildCommands() -> some Commands {
        CommandGroup(after: .newItem) {
            Button("New Item") {
                NotificationCenter.default.post(name: .createNewItem, object: nil)
            }
            .keyboardShortcut("n", modifiers: .command)
            
            Button("Duplicate Item") {
                NotificationCenter.default.post(name: .duplicateSelectedItem, object: nil)
            }
            .keyboardShortcut("d", modifiers: .command)
            
            Divider()
            
            Button("Import...") {
                NotificationCenter.default.post(name: .showImport, object: nil)
            }
            .keyboardShortcut("i", modifiers: [.command, .shift])
            
            Button("Export...") {
                NotificationCenter.default.post(name: .showExport, object: nil)
            }
            .keyboardShortcut("e", modifiers: .command)
        }
        
        CommandGroup(replacing: .sidebar) {
            Button("Toggle Sidebar") {
                NotificationCenter.default.post(name: .toggleSidebar, object: nil)
            }
            .keyboardShortcut("s", modifiers: [.command, .control])
        }
        
        CommandMenu("Navigate") {
            Button("Items") {
                NotificationCenter.default.post(
                    name: .navigateToTab,
                    object: nil,
                    userInfo: ["tab": iPadTab.items]
                )
            }
            .keyboardShortcut("1", modifiers: .command)
            
            Button("Collections") {
                NotificationCenter.default.post(
                    name: .navigateToTab,
                    object: nil,
                    userInfo: ["tab": iPadTab.collections]
                )
            }
            .keyboardShortcut("2", modifiers: .command)
            
            Button("Analytics") {
                NotificationCenter.default.post(
                    name: .navigateToTab,
                    object: nil,
                    userInfo: ["tab": iPadTab.analytics]
                )
            }
            .keyboardShortcut("3", modifiers: .command)
            
            Button("Scanner") {
                NotificationCenter.default.post(
                    name: .navigateToTab,
                    object: nil,
                    userInfo: ["tab": iPadTab.scanner]
                )
            }
            .keyboardShortcut("4", modifiers: .command)
            
            Divider()
            
            Button("Search") {
                NotificationCenter.default.post(name: .focusSearch, object: nil)
            }
            .keyboardShortcut("f", modifiers: .command)
        }
    }
}

// MARK: - Keyboard Navigation

struct KeyboardNavigationModifier: ViewModifier {
    @FocusState private var focusedField: FocusableField?
    
    enum FocusableField: Hashable {
        case search
        case itemName
        case itemDescription
        case itemPrice
    }
    
    func body(content: Content) -> some View {
        content
            .focused($focusedField)
            .onKeyPress(.tab) {
                // Custom tab navigation
                advanceFocus()
                return .handled
            }
            .onKeyPress(.tab, modifiers: .shift) {
                // Reverse tab navigation
                reverseFocus()
                return .handled
            }
    }
    
    private func advanceFocus() {
        switch focusedField {
        case .search:
            focusedField = .itemName
        case .itemName:
            focusedField = .itemDescription
        case .itemDescription:
            focusedField = .itemPrice
        case .itemPrice:
            focusedField = .search
        case .none:
            focusedField = .search
        }
    }
    
    private func reverseFocus() {
        switch focusedField {
        case .search:
            focusedField = .itemPrice
        case .itemName:
            focusedField = .search
        case .itemDescription:
            focusedField = .itemName
        case .itemPrice:
            focusedField = .itemDescription
        case .none:
            focusedField = .itemPrice
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
                    ShortcutRow(key: "⌘1", description: "Go to Items")
                    ShortcutRow(key: "⌘2", description: "Go to Collections")
                    ShortcutRow(key: "⌘3", description: "Go to Analytics")
                    ShortcutRow(key: "⌘4", description: "Go to Scanner")
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
                    ShortcutRow(key: "⌘K", description: "Quick Find")
                    ShortcutRow(key: "Esc", description: "Clear Search")
                }
                
                Section("Import/Export") {
                    ShortcutRow(key: "⌘⇧I", description: "Import")
                    ShortcutRow(key: "⌘E", description: "Export")
                }
                
                Section("View Controls") {
                    ShortcutRow(key: "⌘R", description: "Refresh")
                    ShortcutRow(key: "⌘^S", description: "Toggle Sidebar")
                    ShortcutRow(key: "⌘+", description: "Increase Text Size")
                    ShortcutRow(key: "⌘-", description: "Decrease Text Size")
                }
                
                Section("Selection") {
                    ShortcutRow(key: "↑/↓", description: "Navigate List")
                    ShortcutRow(key: "⌘A", description: "Select All")
                    ShortcutRow(key: "⇧Click", description: "Multi-select")
                }
            }
            .navigationTitle("Keyboard Shortcuts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
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
                .foregroundStyle(AppColors.primary)
                .frame(width: 80, alignment: .leading)
            
            Text(description)
                .foregroundStyle(AppColors.textPrimary)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let refreshData = Notification.Name("refreshData")
    static let createNewItem = Notification.Name("createNewItem")
    static let duplicateItem = Notification.Name("duplicateItem")
    static let deleteItem = Notification.Name("deleteItem")
    static let quickLookItem = Notification.Name("quickLookItem")
    static let duplicateSelectedItem = Notification.Name("duplicateSelectedItem")
    static let showImport = Notification.Name("showImport")
    static let showExport = Notification.Name("showExport")
    static let toggleSidebar = Notification.Name("toggleSidebar")
    static let navigateToTab = Notification.Name("navigateToTab")
    static let focusSearch = Notification.Name("focusSearch")
}

// MARK: - View Extension

extension View {
    func iPadKeyboardShortcuts(navigationState: iPadNavigationState) -> some View {
        self.modifier(iPadKeyboardShortcuts(navigationState: navigationState))
    }
    
    func keyboardNavigation() -> some View {
        self.modifier(KeyboardNavigationModifier())
    }
}