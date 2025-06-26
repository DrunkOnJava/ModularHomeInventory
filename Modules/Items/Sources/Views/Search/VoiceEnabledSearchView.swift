//
//  VoiceEnabledSearchView.swift
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
//  Dependencies: SwiftUI, Core, SharedUI
//  Testing: ItemsTests/VoiceEnabledSearchViewTests.swift
//
//  Description: Search view with integrated voice search capability
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core
import SharedUI

/// Search view that combines text and voice search capabilities
public struct VoiceEnabledSearchView: View {
    @Binding var searchText: String
    @Binding var isPresented: Bool
    let onSearch: (String) -> Void
    
    @State private var showingVoiceSearch = false
    @FocusState private var isSearchFocused: Bool
    
    public init(
        searchText: Binding<String>,
        isPresented: Binding<Bool>,
        onSearch: @escaping (String) -> Void
    ) {
        self._searchText = searchText
        self._isPresented = isPresented
        self.onSearch = onSearch
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Enhanced search bar with voice
                EnhancedSearchBar(
                    text: $searchText,
                    placeholder: "Search items or use voice",
                    onCommit: {
                        if !searchText.isEmpty {
                            onSearch(searchText)
                            isPresented = false
                        }
                    }
                )
                .padding()
                
                // Recent searches
                if searchText.isEmpty {
                    RecentSearchesSection(onSelectSearch: { query in
                        searchText = query
                        onSearch(query)
                        isPresented = false
                    })
                }
                
                Spacer()
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !searchText.isEmpty {
                        Button("Search") {
                            onSearch(searchText)
                            isPresented = false
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .onAppear {
                isSearchFocused = true
            }
        }
    }
}

// MARK: - Recent Searches Section

struct RecentSearchesSection: View {
    let onSelectSearch: (String) -> Void
    @AppStorage("recentSearches") private var recentSearchesData = Data()
    
    var recentSearches: [String] {
        (try? JSONDecoder().decode([String].self, from: recentSearchesData)) ?? []
    }
    
    var body: some View {
        if !recentSearches.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Searches")
                    .font(.headline)
                    .padding(.horizontal)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(recentSearches.prefix(10), id: \.self) { search in
                            Button(action: {
                                onSelectSearch(search)
                            }) {
                                HStack {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(search)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.up.left")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
            }
            .padding(.top)
        } else {
            VoiceSearchPrompt()
        }
    }
}

// MARK: - Voice Search Prompt

struct VoiceSearchPrompt: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.blue)
                .symbolEffect(.pulse)
            
            VStack(spacing: 8) {
                Text("Try Voice Search")
                    .font(.headline)
                
                Text("Tap the microphone to search by voice")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Example voice queries
            VStack(alignment: .leading, spacing: 8) {
                Text("You can say things like:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                ForEach([
                    "Show me all electronics",
                    "Find items in the bedroom",
                    "Search for Nike shoes",
                    "Items under warranty"
                ], id: \.self) { example in
                    HStack {
                        Image(systemName: "quote.opening")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        Text(example)
                            .font(.caption)
                            .italic()
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }
}