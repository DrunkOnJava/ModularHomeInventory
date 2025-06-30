//
//  KeyboardShortcutHelpView.swift
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
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI

/// Help view showing available keyboard shortcuts
struct KeyboardShortcutHelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Navigation Shortcuts
                    ShortcutSection(title: "Navigation") {
                        ShortcutRow(command: "⌘1", description: "Items")
                        ShortcutRow(command: "⌘2", description: "Scanner")
                        ShortcutRow(command: "⌘3", description: "Analytics")
                        ShortcutRow(command: "⌘4", description: "Settings")
                    }
                    
                    // Actions Shortcuts
                    ShortcutSection(title: "Actions") {
                        ShortcutRow(command: "⌘N", description: "Add New Item")
                        ShortcutRow(command: "⌘F", description: "Search")
                        ShortcutRow(command: "⌘⇧I", description: "Import CSV")
                        ShortcutRow(command: "⌘⇧E", description: "Export Data")
                    }
                    
                    // View Shortcuts
                    ShortcutSection(title: "View") {
                        ShortcutRow(command: "⌘\\", description: "Toggle Slide Over")
                        ShortcutRow(command: "⌘+", description: "Increase Text Size")
                        ShortcutRow(command: "⌘-", description: "Decrease Text Size")
                        ShortcutRow(command: "⌘/", description: "Show This Help")
                    }
                }
                .padding()
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

struct ShortcutSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                content
            }
        }
    }
}

struct ShortcutRow: View {
    let command: String
    let description: String
    
    var body: some View {
        HStack {
            Text(command)
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray5))
                .cornerRadius(6)
            
            Text(description)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

#Preview {
    KeyboardShortcutHelpView()
}