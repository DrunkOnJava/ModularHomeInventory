//
//  NaturalLanguageSearchView.swift
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
//  Module: Items
//  Dependencies: SwiftUI, Core, SharedUI
//  Testing: ItemsTests/NaturalLanguageSearchViewTests.swift
//
//  Description: Natural language search interface
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core
import SharedUI

/// Natural language search interface
/// Swift 5.9 - No Swift 6 features
struct NaturalLanguageSearchView: View {
    @StateObject private var viewModel: NaturalLanguageSearchViewModel
    @StateObject private var voiceSearch = VoiceSearchService()
    @State private var searchQuery = ""
    @State private var showingSuggestions = false
    @State private var selectedItem: Item?
    @State private var showingSearchHistory = false
    @State private var showingSavedSearches = false
    @State private var showingSaveSearch = false
    @State private var showingVoiceSearch = false
    @State private var useFuzzySearch = false
    @State private var fuzzyThreshold = 0.7
    @FocusState private var isSearchFocused: Bool
    
    // let suggestionsService: SearchSuggestionsService?
    
    init(
        itemRepository: any ItemRepository,
        searchHistoryRepository: (any SearchHistoryRepository)? = nil,
        savedSearchRepository: (any SavedSearchRepository)? = nil,
        locationRepository: (any LocationRepository)? = nil,
        categoryRepository: (any CategoryRepository)? = nil
    ) {
        let historyRepo = searchHistoryRepository ?? DefaultSearchHistoryRepository()
        let savedRepo = savedSearchRepository ?? DefaultSavedSearchRepository()
        
        self._viewModel = StateObject(wrappedValue: NaturalLanguageSearchViewModel(
            itemRepository: itemRepository,
            searchHistoryRepository: historyRepo,
            savedSearchRepository: savedRepo
        ))
        
        // TODO: Re-enable suggestions service after fixing dependencies
        // Create suggestions service if we have all required repositories
        /*
        if let locationRepo = locationRepository,
           let categoryRepo = categoryRepository {
            self.suggestionsService = SearchSuggestionsService(
                itemRepository: itemRepository,
                locationRepository: locationRepo,
                categoryRepository: categoryRepo,
                searchHistoryRepository: historyRepo
            )
        } else {
            self.suggestionsService = nil
        }
        */
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar with natural language hints
                VStack(alignment: .leading, spacing: 8) {
                    // TODO: Re-enable search field with suggestions
                    // Fallback to regular search field
                    HStack {
                        Button(action: {
                            showingVoiceSearch = true
                        }) {
                            Image(systemName: voiceSearch.isRecording ? "mic.fill" : "mic")
                                .foregroundStyle(voiceSearch.isRecording ? .red : .blue)
                                .symbolEffect(.bounce, value: voiceSearch.isRecording)
                        }
                        .disabled(!voiceSearch.isAuthorized)
                        
                        TextField("Try 'red shoes bought last month' or 'electronics under warranty'", text: $searchQuery)
                            .textFieldStyle(.plain)
                            .focused($isSearchFocused)
                            .onSubmit {
                                Task {
                                    await viewModel.performNaturalLanguageSearch(
                                        searchQuery,
                                        useFuzzySearch: useFuzzySearch,
                                        fuzzyThreshold: fuzzyThreshold
                                    )
                                }
                            }
                        
                        if viewModel.isSearching {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else if !searchQuery.isEmpty {
                            Button(action: {
                                searchQuery = ""
                                viewModel.clearSearch()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Button(action: {
                            Task {
                                await viewModel.performNaturalLanguageSearch(
                                    searchQuery,
                                    useFuzzySearch: useFuzzySearch,
                                    fuzzyThreshold: fuzzyThreshold
                                )
                            }
                        }) {
                            Image(systemName: "arrow.forward.circle.fill")
                                .foregroundStyle(.blue)
                        }
                        .disabled(searchQuery.isEmpty || viewModel.isSearching)
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    // Query interpretation
                    if let interpretation = viewModel.queryInterpretation {
                        QueryInterpretationView(interpretation: interpretation)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Fuzzy search toggle
                    FuzzySearchToggle(
                        isEnabled: $useFuzzySearch,
                        threshold: $fuzzyThreshold
                    )
                    .padding(.top, 4)
                }
                .padding()
                .animation(.easeInOut(duration: 0.2), value: viewModel.queryInterpretation != nil)
                .onAppear {
                    if !voiceSearch.isAuthorized {
                        voiceSearch.requestAuthorization()
                    }
                }
                .onChange(of: voiceSearch.transcribedText) { newText in
                    if !newText.isEmpty {
                        searchQuery = newText
                        if !voiceSearch.isRecording {
                            Task {
                                await viewModel.performNaturalLanguageSearch(
                                    searchQuery,
                                    useFuzzySearch: useFuzzySearch,
                                    fuzzyThreshold: fuzzyThreshold
                                )
                            }
                        }
                    }
                }
                
                // Example queries
                if viewModel.searchResults.isEmpty && searchQuery.isEmpty {
                    ExampleQueriesView { query in
                        searchQuery = query
                        Task {
                            await viewModel.performNaturalLanguageSearch(
                                query,
                                useFuzzySearch: useFuzzySearch,
                                fuzzyThreshold: fuzzyThreshold
                            )
                        }
                    }
                } else if viewModel.searchResults.isEmpty && !searchQuery.isEmpty && !viewModel.isSearching {
                    // No results
                    NLSearchNoResultsView(query: searchQuery)
                } else {
                    // Search results
                    NLSearchResultsList(
                        items: viewModel.searchResults,
                        onSelectItem: { item in
                            selectedItem = item
                        }
                    )
                }
            }
            .navigationTitle("Smart Search")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // Save current search button
                    if !searchQuery.isEmpty && !viewModel.searchResults.isEmpty {
                        Button(action: {
                            showingSaveSearch = true
                        }) {
                            Image(systemName: "bookmark")
                        }
                    }
                    
                    // Saved searches button
                    Button(action: {
                        showingSavedSearches = true
                    }) {
                        Image(systemName: "bookmark.fill")
                    }
                    
                    // Search history button
                    Button(action: {
                        showingSearchHistory = true
                    }) {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
            }
            .sheet(item: $selectedItem) { item in
                // In a real app, this would navigate to item detail
                // For now, just show the item name
                NavigationView {
                    VStack {
                        Text(item.name)
                            .font(.largeTitle)
                            .padding()
                        
                        if let brand = item.brand {
                            Text(brand)
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .navigationTitle("Item Detail")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                selectedItem = nil
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingSearchHistory) {
                SearchHistoryView(
                    searchHistoryRepository: viewModel.searchHistoryRepository,
                    onSelectEntry: { entry in
                        searchQuery = entry.query
                        Task {
                            await viewModel.performNaturalLanguageSearch(
                                entry.query,
                                useFuzzySearch: useFuzzySearch,
                                fuzzyThreshold: fuzzyThreshold
                            )
                        }
                    }
                )
            }
            .sheet(isPresented: $showingSavedSearches) {
                SavedSearchesView(
                    savedSearchRepository: viewModel.savedSearchRepository,
                    onSelectSearch: { savedSearch in
                        searchQuery = savedSearch.query
                        Task {
                            await viewModel.performSavedSearch(
                                savedSearch,
                                useFuzzySearch: useFuzzySearch,
                                fuzzyThreshold: fuzzyThreshold
                            )
                        }
                    }
                )
            }
            .sheet(isPresented: $showingSaveSearch) {
                AddSavedSearchView(
                    savedSearchRepository: viewModel.savedSearchRepository,
                    initialQuery: searchQuery,
                    initialSearchType: .natural,
                    onSave: { _ in
                        showingSaveSearch = false
                    }
                )
            }
            .onAppear {
                isSearchFocused = true
            }
            .sheet(isPresented: $showingVoiceSearch) {
                VoiceSearchSheet(
                    searchText: $searchQuery,
                    isPresented: $showingVoiceSearch,
                    onCommit: {
                        Task {
                            await viewModel.performNaturalLanguageSearch(
                                searchQuery,
                                useFuzzySearch: useFuzzySearch,
                                fuzzyThreshold: fuzzyThreshold
                            )
                        }
                    }
                )
            }
        }
    }
}

// MARK: - Fuzzy Search Toggle

extension NaturalLanguageSearchView {
    struct FuzzySearchToggle: View {
        @Binding var isEnabled: Bool
        @Binding var threshold: Double
        @State private var showingInfo = false
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Toggle("Fuzzy Search", isOn: $isEnabled)
                        .font(.caption)
                    
                    Button(action: { showingInfo.toggle() }) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
                
                if isEnabled {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Similarity: \(Int(threshold * 100))%")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        Slider(value: $threshold, in: 0.5...1.0, step: 0.05)
                            .tint(.blue)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .alert("Fuzzy Search", isPresented: $showingInfo) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Fuzzy search finds items even when there are typos or similar spellings. Lower similarity values find more matches but may be less accurate.")
            }
        }
    }
}

// MARK: - Voice Search Sheet

extension NaturalLanguageSearchView {
    struct VoiceSearchSheet: View {
        @Binding var searchText: String
        @Binding var isPresented: Bool
        let onCommit: () -> Void
        @StateObject private var voiceSearch = VoiceSearchService()
        @State private var isListening = false
        
        var body: some View {
            NavigationView {
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Microphone animation
                    ZStack {
                        if isListening {
                            ForEach(0..<3) { index in
                                Circle()
                                    .stroke(lineWidth: 2)
                                    .foregroundStyle(.blue.opacity(0.3))
                                    .scaleEffect(isListening ? 2 : 1)
                                    .opacity(isListening ? 0 : 1)
                                    .animation(
                                        Animation.easeOut(duration: 1.5)
                                            .repeatForever(autoreverses: false)
                                            .delay(Double(index) * 0.5),
                                        value: isListening
                                    )
                            }
                        }
                        
                        Image(systemName: isListening ? "mic.fill" : "mic")
                            .font(.system(size: 60))
                            .foregroundStyle(isListening ? .red : .blue)
                            .symbolEffect(.bounce, value: isListening)
                    }
                    .frame(width: 120, height: 120)
                    
                    Text(isListening ? "Listening..." : "Tap to speak")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if !voiceSearch.transcribedText.isEmpty {
                        Text(voiceSearch.transcribedText)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    // Control buttons
                    HStack(spacing: 20) {
                        Button(action: {
                            if isListening {
                                voiceSearch.stopRecording()
                                isListening = false
                            } else {
                                do {
                                    try voiceSearch.startRecording()
                                    isListening = true
                                } catch {
                                    print("Failed to start recording: \(error)")
                                }
                            }
                        }) {
                            Image(systemName: isListening ? "stop.circle.fill" : "mic.circle.fill")
                                .font(.system(size: 64))
                                .foregroundStyle(isListening ? .red : .blue)
                        }
                        .disabled(!voiceSearch.isAuthorized)
                        
                        if !voiceSearch.transcribedText.isEmpty {
                            Button(action: {
                                searchText = voiceSearch.transcribedText
                                isPresented = false
                                onCommit()
                            }) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 64))
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
                .navigationTitle("Voice Search")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            voiceSearch.stopRecording()
                            isPresented = false
                        }
                    }
                }
                .onAppear {
                    if !voiceSearch.isAuthorized {
                        voiceSearch.requestAuthorization()
                    }
                }
                .onDisappear {
                    voiceSearch.stopRecording()
                }
                .onChange(of: voiceSearch.isRecording) { isRecording in
                    isListening = isRecording
                }
            }
        }
    }
}




