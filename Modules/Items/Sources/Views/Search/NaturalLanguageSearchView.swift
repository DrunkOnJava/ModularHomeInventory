import SwiftUI
import Core
import SharedUI

/// Natural language search interface
/// Swift 5.9 - No Swift 6 features
struct NaturalLanguageSearchView: View {
    @StateObject private var viewModel: NaturalLanguageSearchViewModel
    @State private var searchQuery = ""
    @State private var showingSuggestions = false
    @State private var selectedItem: Item?
    @State private var showingSearchHistory = false
    @State private var showingSavedSearches = false
    @State private var showingSaveSearch = false
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
        NavigationView {
            VStack(spacing: 0) {
                // Search bar with natural language hints
                VStack(alignment: .leading, spacing: 8) {
                    // TODO: Re-enable search field with suggestions
                    // Fallback to regular search field
                    HStack {
                        Image(systemName: "mic.fill")
                            .foregroundStyle(.secondary)
                            .onTapGesture {
                                // TODO: Voice input
                            }
                        
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
                    NoResultsView(query: searchQuery)
                } else {
                    // Search results
                    SearchResultsList(
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
        }
    }
}

// MARK: - Query Interpretation View
struct QueryInterpretationView: View {
    let interpretation: QueryInterpretation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Searching for:")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(interpretation.components, id: \.self) { component in
                        InterpretationChip(component: component)
                    }
                }
            }
        }
        .padding(.horizontal, 4)
    }
}

struct InterpretationChip: View {
    let component: QueryComponent
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: component.icon)
                .font(.caption)
            Text(component.value)
                .font(.caption)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(hex: component.color).opacity(0.2))
        .foregroundStyle(Color(hex: component.color))
        .cornerRadius(15)
    }
}

// MARK: - Example Queries
struct ExampleQueriesView: View {
    let onSelectQuery: (String) -> Void
    
    let examples = [
        ("🔴 Color Search", "red items in bedroom"),
        ("📅 Time-based", "items bought last month"),
        ("💰 Price Range", "electronics under $100"),
        ("📍 Location", "tools in garage"),
        ("🏷️ Brand", "Apple products"),
        ("✅ Warranty", "items under warranty"),
        ("🆕 Recent", "recently added items"),
        ("🏪 Store", "items from Amazon"),
        ("📦 Category", "electronics in office"),
        ("🔍 Combined", "black Nike shoes under $200")
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Try these example searches:")
                    .font(.headline)
                    .padding(.horizontal)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(examples, id: \.1) { example in
                        ExampleQueryCard(
                            icon: example.0,
                            query: example.1,
                            onTap: {
                                onSelectQuery(example.1)
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
    let icon: String
    let query: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Text(icon)
                    .font(.title2)
                Text(query)
                    .font(.caption)
                    .foregroundStyle(.primary)
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
struct NoResultsView: View {
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

struct BulletPoint: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Search Results List
struct SearchResultsList: View {
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

// MARK: - View Model
@MainActor
final class NaturalLanguageSearchViewModel: ObservableObject {
    @Published var searchResults: [Item] = []
    @Published var isSearching = false
    @Published var queryInterpretation: QueryInterpretation?
    @Published var searchHistory: [String] = []
    
    let itemRepository: any ItemRepository
    let nlSearchService = NaturalLanguageSearchService()
    let searchHistoryRepository: any SearchHistoryRepository
    let savedSearchRepository: any SavedSearchRepository
    
    init(itemRepository: any ItemRepository, searchHistoryRepository: any SearchHistoryRepository, savedSearchRepository: any SavedSearchRepository) {
        self.itemRepository = itemRepository
        self.searchHistoryRepository = searchHistoryRepository
        self.savedSearchRepository = savedSearchRepository
        loadSearchHistory()
    }
    
    func performNaturalLanguageSearch(
        _ query: String,
        useFuzzySearch: Bool = false,
        fuzzyThreshold: Double = 0.7
    ) async {
        guard !query.isEmpty else { return }
        
        isSearching = true
        defer { isSearching = false }
        
        // Parse the natural language query
        let nlQuery = nlSearchService.parseQuery(query)
        
        // Update interpretation
        queryInterpretation = buildInterpretation(from: nlQuery)
        
        // Convert to search criteria
        let criteria = nlSearchService.convertToSearchCriteria(nlQuery)
        
        do {
            // Perform the search
            if useFuzzySearch && criteria.searchText != nil {
                // Use fuzzy search for the text portion
                let fuzzyResults = try await itemRepository.fuzzySearch(
                    query: criteria.searchText ?? "",
                    threshold: fuzzyThreshold
                )
                
                // Then apply other filters
                searchResults = fuzzyResults.filter { item in
                    // Apply category filter
                    if !criteria.categories.isEmpty && !criteria.categories.contains(item.category) {
                        return false
                    }
                    
                    // Apply date range filter
                    if let startDate = criteria.purchaseDateStart,
                       let purchaseDate = item.purchaseDate,
                       purchaseDate < startDate {
                        return false
                    }
                    
                    if let endDate = criteria.purchaseDateEnd,
                       let purchaseDate = item.purchaseDate,
                       purchaseDate > endDate {
                        return false
                    }
                    
                    // Apply price range filter
                    if let minPrice = criteria.minPrice,
                       let purchasePrice = item.purchasePrice,
                       purchasePrice < Decimal(minPrice) {
                        return false
                    }
                    
                    if let maxPrice = criteria.maxPrice,
                       let purchasePrice = item.purchasePrice,
                       purchasePrice > Decimal(maxPrice) {
                        return false
                    }
                    
                    return true
                }
            } else {
                searchResults = try await itemRepository.searchWithCriteria(criteria)
            }
            
            // Add to search history
            addToSearchHistory(query)
            
            // Save to persistent search history
            let historyEntry = SearchHistoryEntry(
                query: query,
                searchType: .natural,
                resultCount: searchResults.count
            )
            try? await searchHistoryRepository.save(historyEntry)
        } catch {
            print("Search error: \(error)")
            searchResults = []
        }
    }
    
    func clearSearch() {
        searchResults = []
        queryInterpretation = nil
    }
    
    func performSavedSearch(_ savedSearch: SavedSearch, useFuzzySearch: Bool = false, fuzzyThreshold: Double = 0.7) async {
        // Record usage
        try? await savedSearchRepository.recordUsage(of: savedSearch)
        
        // Perform the search
        await performNaturalLanguageSearch(savedSearch.query, useFuzzySearch: useFuzzySearch, fuzzyThreshold: fuzzyThreshold)
    }
    
    private func buildInterpretation(from nlQuery: NaturalLanguageQuery) -> QueryInterpretation {
        var components: [QueryComponent] = []
        
        // Add color components
        for color in nlQuery.colors {
            components.append(QueryComponent(
                type: .color,
                value: color,
                icon: "paintpalette",
                color: "#FF6B6B"
            ))
        }
        
        // Add item components
        for item in nlQuery.items {
            components.append(QueryComponent(
                type: .item,
                value: item,
                icon: "cube.box",
                color: "#4ECDC4"
            ))
        }
        
        // Add location components
        for location in nlQuery.locations {
            components.append(QueryComponent(
                type: .location,
                value: location,
                icon: "location",
                color: "#FFE66D"
            ))
        }
        
        // Add time components
        for timeRef in nlQuery.timeReferences {
            components.append(QueryComponent(
                type: .time,
                value: timeRef,
                icon: "calendar",
                color: "#95E1D3"
            ))
        }
        
        // Add price components
        for priceRange in nlQuery.priceRanges {
            let value: String
            if let min = priceRange.min, let max = priceRange.max {
                value = "$\(Int(min))-$\(Int(max))"
            } else if let min = priceRange.min {
                value = "over $\(Int(min))"
            } else if let max = priceRange.max {
                value = "under $\(Int(max))"
            } else {
                continue
            }
            
            components.append(QueryComponent(
                type: .price,
                value: value,
                icon: "dollarsign.circle",
                color: "#A8E6CF"
            ))
        }
        
        // Add brand components
        for brand in nlQuery.brands {
            components.append(QueryComponent(
                type: .brand,
                value: brand,
                icon: "tag",
                color: "#C7CEEA"
            ))
        }
        
        // Add category components
        for category in nlQuery.categories {
            components.append(QueryComponent(
                type: .category,
                value: category,
                icon: "folder",
                color: "#FFDAB9"
            ))
        }
        
        // Add action components
        for action in nlQuery.actions {
            if action.lowercased().contains("warranty") {
                components.append(QueryComponent(
                    type: .action,
                    value: "under warranty",
                    icon: "shield",
                    color: "#B19CD9"
                ))
            }
        }
        
        return QueryInterpretation(components: components)
    }
    
    private func loadSearchHistory() {
        if let data = UserDefaults.standard.data(forKey: "searchHistory"),
           let history = try? JSONDecoder().decode([String].self, from: data) {
            searchHistory = history
        }
    }
    
    private func addToSearchHistory(_ query: String) {
        // Remove if already exists
        searchHistory.removeAll { $0 == query }
        
        // Add to beginning
        searchHistory.insert(query, at: 0)
        
        // Keep only last 20
        if searchHistory.count > 20 {
            searchHistory = Array(searchHistory.prefix(20))
        }
        
        // Save to UserDefaults
        if let data = try? JSONEncoder().encode(searchHistory) {
            UserDefaults.standard.set(data, forKey: "searchHistory")
        }
    }
}

// MARK: - Data Models
struct QueryInterpretation {
    let components: [QueryComponent]
}

struct QueryComponent: Hashable {
    enum ComponentType {
        case color, item, location, time, price, brand, category, action
    }
    
    let type: ComponentType
    let value: String
    let icon: String
    let color: String
}