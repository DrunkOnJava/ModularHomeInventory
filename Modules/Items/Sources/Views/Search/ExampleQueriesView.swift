//
//  ExampleQueriesView.swift
//  Items Module
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
//  Module: Items
//  Dependencies: SwiftUI, Core
//  Testing: ItemsTests/ExampleQueriesViewTests.swift
//
//  Description: View displaying example search queries to guide user input
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core
import SharedUI

// MARK: - Example Queries
struct ExampleQueriesView: View {
    let onSelectQuery: (String) -> Void
    
    let examples = [
        ("paintpalette", "Color Search", "red items in bedroom"),
        ("calendar", "Time-based", "items bought last month"),
        ("dollarsign.circle", "Price Range", "electronics under $100"),
        ("location", "Location", "tools in garage"),
        ("tag", "Brand", "Apple products"),
        ("checkmark.shield", "Warranty", "items under warranty"),
        ("sparkles", "Recent", "recently added items"),
        ("storefront", "Store", "items from Amazon"),
        ("shippingbox", "Category", "electronics in office"),
        ("magnifyingglass", "Combined", "black Nike shoes under $200")
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Try these example searches:")
                    .font(.headline)
                    .padding(.horizontal)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(examples, id: \.2) { example in
                        ExampleQueryCard(
                            iconName: example.0,
                            title: example.1,
                            query: example.2,
                            onTap: {
                                onSelectQuery(example.2)
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

struct ExampleQueryCard: View {
    let iconName: String
    let title: String
    let query: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: iconName)
                        .font(.title2)
                        .foregroundStyle(.blue)
                    Text(title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Spacer()
                }
                Text(query)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - No Results View
struct NLSearchNoResultsView: View {
    let query: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("No items found")
                .font(.headline)
            
            Text("Try different keywords or check the spelling")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            // Suggestions
            VStack(alignment: .leading, spacing: 8) {
                Text("Search tips:")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                BulletPoint("Use simple, descriptive words")
                BulletPoint("Try color, brand, or location")
                BulletPoint("Use time references like 'last month'")
                BulletPoint("Combine multiple attributes")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal, 40)
        }
        .padding()
    }
}


// MARK: - Search Results List
struct NLSearchResultsList: View {
    let items: [Item]
    let onSelectItem: (Item) -> Void
    
    var body: some View {
        List {
            Section {
                ForEach(items) { item in
                    Button(action: { onSelectItem(item) }) {
                        ItemSearchResultRow(item: item)
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                HStack {
                    Text("\(items.count) items found")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
    }
}