//
//  iPadDragDrop.swift
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
//  Dependencies: SwiftUI, UniformTypeIdentifiers, Core
//  Testing: HomeInventoryModularTests/iPadDragDropTests.swift
//
//  Description: Drag and drop functionality implementation for iPad multitasking and file management
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers
import Core

/// Drag and Drop support for iPad
/// Enables dragging items between views and to external apps
struct iPadDragDropModifier: ViewModifier {
    let item: Item
    
    func body(content: Content) -> some View {
        content
            .onDrag {
                itemProvider(for: item)
            }
    }
    
    private func itemProvider(for item: Item) -> NSItemProvider {
        let provider = NSItemProvider()
        
        // Provide item as JSON
        provider.registerDataRepresentation(forTypeIdentifier: UTType.json.identifier, visibility: .all) { completion in
            do {
                let data = try JSONEncoder().encode(item)
                completion(data, nil)
            } catch {
                completion(nil, error)
            }
            return nil
        }
        
        // Provide item as plain text
        provider.registerDataRepresentation(forTypeIdentifier: UTType.plainText.identifier, visibility: .all) { completion in
            let text = """
            \(item.name)
            \(item.brand ?? "")
            \(item.model ?? "")
            Price: \(item.purchasePrice.map { "\($0)" } ?? "N/A")
            """
            let data = text.data(using: .utf8)
            completion(data, nil)
            return nil
        }
        
        return provider
    }
}

// MARK: - Drop Destination

struct iPadDropDestinationModifier: ViewModifier {
    let supportedTypes: [UTType]
    let onDrop: ([NSItemProvider]) -> Bool
    @State private var isTargeted = false
    
    func body(content: Content) -> some View {
        content
            .onDrop(of: supportedTypes, isTargeted: $isTargeted) { providers in
                onDrop(providers)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.blue, lineWidth: 2)
                    .opacity(isTargeted ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: isTargeted)
            )
    }
}

// MARK: - Multi-Item Drag

struct MultiItemDragProvider {
    static func createProvider(for items: [Item]) -> NSItemProvider {
        let provider = NSItemProvider()
        
        // Provide as JSON array
        provider.registerDataRepresentation(forTypeIdentifier: UTType.json.identifier, visibility: .all) { completion in
            do {
                let data = try JSONEncoder().encode(items)
                completion(data, nil)
            } catch {
                completion(nil, error)
            }
            return nil
        }
        
        // Provide as CSV
        provider.registerDataRepresentation(forTypeIdentifier: UTType.commaSeparatedText.identifier, visibility: .all) { completion in
            var csv = "Name,Brand,Model,Price,Quantity,Location\n"
            for item in items {
                csv += "\"\(item.name)\","
                csv += "\"\(item.brand ?? "")\","
                csv += "\"\(item.model ?? "")\","
                csv += "\(item.purchasePrice.map { "\($0)" } ?? ""),"
                csv += "\(item.quantity),"
                csv += "\"\(item.notes ?? "")\"\n"
            }
            let data = csv.data(using: .utf8)
            completion(data, nil)
            return nil
        }
        
        return provider
    }
}

// MARK: - View Extensions

extension View {
    func iPadDraggable(_ item: Item) -> some View {
        self.modifier(iPadDragDropModifier(item: item))
    }
    
    func iPadDropDestination(
        supportedTypes: [UTType] = [.json, .plainText, .commaSeparatedText],
        onDrop: @escaping ([NSItemProvider]) -> Bool
    ) -> ModifiedContent<Self, iPadDropDestinationModifier> {
        self.modifier(iPadDropDestinationModifier(supportedTypes: supportedTypes, onDrop: onDrop))
    }
}

// MARK: - Drag Preview

struct DragPreview: View {
    let item: Item
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.category.icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Color(item.category.color))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .lineLimit(1)
                
                if let brand = item.brand {
                    Text(brand)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(width: 250)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 4)
    }
}

// MARK: - Drop Handlers

struct ItemDropHandler {
    @EnvironmentObject var coordinator: AppCoordinator
    
    func handleDrop(providers: [NSItemProvider], to location: Location?) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.json.identifier) {
                provider.loadDataRepresentation(forTypeIdentifier: UTType.json.identifier) { data, error in
                    guard let data = data,
                          let items = try? JSONDecoder().decode([Item].self, from: data) else {
                        // Try single item
                        if let data = data,
                           let item = try? JSONDecoder().decode(Item.self, from: data) {
                            Task { @MainActor in
                                // Update item location
                                var updatedItem = item
                                updatedItem.locationId = location?.id
                                // Save through coordinator
                            }
                        }
                        return
                    }
                    
                    Task { @MainActor in
                        // Update multiple items
                        for item in items {
                            var updatedItem = item
                            updatedItem.locationId = location?.id
                            // Save through coordinator
                        }
                    }
                }
            }
        }
        return true
    }
    
    func handleCSVDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.commaSeparatedText.identifier) {
                provider.loadDataRepresentation(forTypeIdentifier: UTType.commaSeparatedText.identifier) { data, error in
                    guard let data = data,
                          let csv = String(data: data, encoding: .utf8) else { return }
                    
                    Task { @MainActor in
                        // Process CSV import
                        NotificationCenter.default.post(
                            name: .importCSV,
                            object: csv
                        )
                    }
                }
            }
        }
        return true
    }
}

// MARK: - Drag Session

class DragSession: ObservableObject {
    @Published var isDragging = false
    @Published var draggedItems: [Item] = []
    @Published var dropLocation: CGPoint = .zero
    
    func startDrag(items: [Item]) {
        isDragging = true
        draggedItems = items
    }
    
    func endDrag() {
        isDragging = false
        draggedItems = []
        dropLocation = .zero
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let importCSV = Notification.Name("importCSV")
    static let itemsDropped = Notification.Name("itemsDropped")
}