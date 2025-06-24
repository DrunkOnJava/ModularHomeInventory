import SwiftUI
import Core
import SharedUI

/// View for searching documents with advanced filters
/// Swift 5.9 - No Swift 6 features
struct DocumentSearchView: View {
    @StateObject private var viewModel: DocumentSearchViewModel
    @State private var searchText = ""
    @State private var showingAdvancedFilters = false
    @State private var selectedDocument: Document?
    @State private var selectedCategory: Document.DocumentCategory?
    @State private var selectedTags: Set<String> = []
    @State private var dateRangeEnabled = false
    @State private var startDate = Date().addingTimeInterval(-30 * 24 * 60 * 60) // 30 days ago
    @State private var endDate = Date()
    @FocusState private var searchFieldFocused: Bool
    
    init(documentRepository: any DocumentRepository,
         documentStorage: DocumentStorageProtocol,
         itemRepository: any ItemRepository) {
        self._viewModel = StateObject(wrappedValue: DocumentSearchViewModel(
            documentRepository: documentRepository,
            documentStorage: documentStorage,
            itemRepository: itemRepository
        ))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                searchBar
                
                // Quick filters
                if !viewModel.availableTags.isEmpty || selectedCategory != nil || dateRangeEnabled {
                    quickFilters
                }
                
                // Search results
                if searchText.isEmpty && !hasActiveFilters {
                    emptyState
                } else if viewModel.isSearching {
                    loadingView
                } else if viewModel.searchResults.isEmpty {
                    noResultsView
                } else {
                    searchResultsList
                }
            }
            .navigationTitle("Search Documents")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAdvancedFilters.toggle() }) {
                        Image(systemName: "slider.horizontal.3")
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .task {
                await viewModel.loadInitialData()
                searchFieldFocused = true
            }
            .sheet(isPresented: $showingAdvancedFilters) {
                AdvancedFiltersSheet(
                    selectedCategory: $selectedCategory,
                    selectedTags: $selectedTags,
                    dateRangeEnabled: $dateRangeEnabled,
                    startDate: $startDate,
                    endDate: $endDate,
                    availableTags: viewModel.availableTags
                ) {
                    Task {
                        await performSearch()
                    }
                }
            }
            .sheet(item: $selectedDocument) { document in
                if let url = viewModel.documentStorage.getDocumentURL(documentId: document.id) {
                    if document.isPDF && (document.pageCount ?? 1) > 1 {
                        PDFViewerEnhanced(url: url, title: document.name)
                    } else {
                        PDFViewerView(url: url, title: document.name)
                    }
                }
            }
            .onChange(of: searchText) { _, newValue in
                Task {
                    await performSearch()
                }
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Search in documents...", text: $searchText)
                .textFieldStyle(.plain)
                .focused($searchFieldFocused)
                .submitLabel(.search)
                .onSubmit {
                    Task {
                        await performSearch()
                    }
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    viewModel.clearSearch()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var quickFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Category filter
                if let category = selectedCategory {
                    Button(action: {
                        selectedCategory = nil
                        Task { await performSearch() }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: category.icon)
                                .font(.caption)
                            Text(category.displayName)
                                .font(.caption)
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption2)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: category.color).opacity(0.2))
                        .foregroundStyle(Color(hex: category.color))
                        .cornerRadius(16)
                    }
                    .buttonStyle(.plain)
                }
                
                // Tag filters
                ForEach(Array(selectedTags), id: \.self) { tag in
                    Button(action: {
                        selectedTags.remove(tag)
                        Task { await performSearch() }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "tag.fill")
                                .font(.caption)
                            Text(tag)
                                .font(.caption)
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption2)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppColors.primary.opacity(0.2))
                        .foregroundStyle(AppColors.primary)
                        .cornerRadius(16)
                    }
                    .buttonStyle(.plain)
                }
                
                // Date range filter
                if dateRangeEnabled {
                    Button(action: {
                        dateRangeEnabled = false
                        Task { await performSearch() }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption)
                            Text(formatDateRange())
                                .font(.caption)
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption2)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.2))
                        .foregroundStyle(.orange)
                        .cornerRadius(16)
                    }
                    .buttonStyle(.plain)
                }
                
                // Clear all filters
                if hasActiveFilters {
                    Button(action: clearAllFilters) {
                        Text("Clear All")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("Search Your Documents")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Find documents by searching their content, names, tags, or notes")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 40)
            
            // Recent searches
            if !viewModel.recentSearches.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Searches")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(viewModel.recentSearches, id: \.self) { query in
                        Button(action: {
                            searchText = query
                            Task { await performSearch() }
                        }) {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundStyle(.secondary)
                                Text(query)
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 32)
            }
            
            Spacer()
        }
        .padding(.top, 40)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Searching documents...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No Results Found")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Try adjusting your search terms or filters")
                .foregroundStyle(.secondary)
            
            Button(action: clearAllFilters) {
                Label("Clear Filters", systemImage: "xmark.circle")
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var searchResultsList: some View {
        List {
            ForEach(viewModel.searchResults) { result in
                SearchResultRow(
                    result: result,
                    searchQuery: searchText,
                    itemName: viewModel.itemName(for: result.document.itemId)
                ) {
                    selectedDocument = result.document
                }
            }
        }
    }
    
    private var hasActiveFilters: Bool {
        selectedCategory != nil || !selectedTags.isEmpty || dateRangeEnabled
    }
    
    private func performSearch() async {
        let criteria = SearchCriteria(
            textQuery: searchText.isEmpty ? nil : searchText,
            category: selectedCategory,
            tags: Array(selectedTags),
            dateRange: dateRangeEnabled ? (startDate, endDate) : nil
        )
        
        await viewModel.search(with: criteria)
    }
    
    private func clearAllFilters() {
        selectedCategory = nil
        selectedTags.removeAll()
        dateRangeEnabled = false
        searchText = ""
        viewModel.clearSearch()
    }
    
    private func formatDateRange() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
}

// MARK: - Search Result Row
struct SearchResultRow: View {
    let result: DocumentSearchResult
    let searchQuery: String
    let itemName: String?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Document info
                HStack {
                    Image(systemName: result.document.type.icon)
                        .foregroundStyle(iconColor)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(result.document.name)
                            .font(.headline)
                            .lineLimit(1)
                        
                        HStack {
                            Text(result.document.category.displayName)
                                .font(.caption)
                                .foregroundStyle(Color(hex: result.document.category.color))
                            
                            if let itemName = itemName {
                                Text("• \(itemName)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Text("• \(result.document.formattedFileSize)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Match count
                    if result.matches.count > 0 {
                        Text("\(result.matches.count)")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppColors.primary)
                            .cornerRadius(12)
                    }
                }
                
                // Snippet with highlighted matches
                if let snippet = result.snippet {
                    Text(highlightedSnippet(snippet))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                // Match locations
                if !result.matches.isEmpty {
                    HStack {
                        ForEach(matchFieldSummary(), id: \.0) { field, count in
                            Label("\(count)", systemImage: field.icon)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private var iconColor: Color {
        switch result.document.type {
        case .pdf: return .red
        case .image: return .blue
        case .text: return .green
        case .other: return .gray
        }
    }
    
    private func highlightedSnippet(_ snippet: String) -> AttributedString {
        var attributedString = AttributedString(snippet)
        
        // Highlight search terms
        let searchTerms = searchQuery.split(separator: " ").map { String($0).lowercased() }
        let lowercasedSnippet = snippet.lowercased()
        
        for term in searchTerms {
            var searchRange = lowercasedSnippet.startIndex..<lowercasedSnippet.endIndex
            
            while let range = lowercasedSnippet.range(of: term, options: [], range: searchRange) {
                if let attributedRange = Range(range, in: attributedString) {
                    attributedString[attributedRange].backgroundColor = AppColors.primary.opacity(0.3)
                    attributedString[attributedRange].foregroundColor = Color.primary
                }
                searchRange = range.upperBound..<lowercasedSnippet.endIndex
            }
        }
        
        return attributedString
    }
    
    private func matchFieldSummary() -> [(SearchMatch.SearchField, Int)] {
        let grouped = Dictionary(grouping: result.matches, by: { $0.field })
        return grouped.map { ($0.key, $0.value.count) }.sorted { $0.1 > $1.1 }
    }
}

extension SearchMatch.SearchField {
    var icon: String {
        switch self {
        case .name: return "doc.text"
        case .content: return "doc.plaintext"
        case .notes: return "note.text"
        case .tag: return "tag"
        case .subcategory: return "folder"
        }
    }
}

// MARK: - Advanced Filters Sheet
struct AdvancedFiltersSheet: View {
    @Binding var selectedCategory: Document.DocumentCategory?
    @Binding var selectedTags: Set<String>
    @Binding var dateRangeEnabled: Bool
    @Binding var startDate: Date
    @Binding var endDate: Date
    let availableTags: [String]
    let onApply: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                // Category filter
                Section("Category") {
                    ForEach(Document.DocumentCategory.allCases, id: \.self) { category in
                        Button(action: { selectedCategory = category }) {
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundStyle(Color(hex: category.color))
                                Text(category.displayName)
                                Spacer()
                                if selectedCategory == category {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(AppColors.primary)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                    
                    if selectedCategory != nil {
                        Button("Clear Category") {
                            selectedCategory = nil
                        }
                        .foregroundStyle(.red)
                    }
                }
                
                // Tag filter
                if !availableTags.isEmpty {
                    Section("Tags") {
                        ForEach(availableTags, id: \.self) { tag in
                            Button(action: {
                                if selectedTags.contains(tag) {
                                    selectedTags.remove(tag)
                                } else {
                                    selectedTags.insert(tag)
                                }
                            }) {
                                HStack {
                                    Label(tag, systemImage: "tag")
                                    Spacer()
                                    if selectedTags.contains(tag) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(AppColors.primary)
                                    }
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                        
                        if !selectedTags.isEmpty {
                            Button("Clear Tags") {
                                selectedTags.removeAll()
                            }
                            .foregroundStyle(.red)
                        }
                    }
                }
                
                // Date range filter
                Section("Date Range") {
                    Toggle("Filter by Date", isOn: $dateRangeEnabled)
                    
                    if dateRangeEnabled {
                        DatePicker("From", selection: $startDate, displayedComponents: .date)
                        DatePicker("To", selection: $endDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Advanced Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        onApply()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - View Model
@MainActor
final class DocumentSearchViewModel: ObservableObject {
    @Published var searchResults: [DocumentSearchResult] = []
    @Published var isSearching = false
    @Published var availableTags: [String] = []
    @Published var recentSearches: [String] = []
    
    let documentRepository: any DocumentRepository
    let documentStorage: DocumentStorageProtocol
    private let itemRepository: any ItemRepository
    private let searchService: DocumentSearchService
    private var items: [Item] = []
    private var searchTask: Task<Void, Never>?
    
    init(documentRepository: any DocumentRepository,
         documentStorage: DocumentStorageProtocol,
         itemRepository: any ItemRepository) {
        self.documentRepository = documentRepository
        self.documentStorage = documentStorage
        self.itemRepository = itemRepository
        self.searchService = DocumentSearchService(
            documentRepository: documentRepository,
            documentStorage: documentStorage
        )
    }
    
    func loadInitialData() async {
        do {
            // Load all tags
            let documents = try await documentRepository.fetchAll()
            let allTags = Set(documents.flatMap { $0.tags })
            availableTags = Array(allTags).sorted()
            
            // Load items for name lookup
            items = try await itemRepository.fetchAll()
            
            // Load recent searches from UserDefaults
            recentSearches = UserDefaults.standard.stringArray(forKey: "documentRecentSearches") ?? []
        } catch {
            print("Failed to load initial data: \(error)")
        }
    }
    
    func search(with criteria: SearchCriteria) async {
        // Cancel previous search
        searchTask?.cancel()
        
        guard criteria.textQuery != nil || criteria.category != nil || 
              !criteria.tags.isEmpty || criteria.dateRange != nil else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        searchTask = Task {
            do {
                let results = try await searchService.advancedSearch(criteria: criteria)
                
                if !Task.isCancelled {
                    searchResults = results
                    
                    // Save to recent searches if text query
                    if let query = criteria.textQuery, !query.isEmpty {
                        addToRecentSearches(query)
                    }
                }
            } catch {
                print("Search failed: \(error)")
                if !Task.isCancelled {
                    searchResults = []
                }
            }
            
            if !Task.isCancelled {
                isSearching = false
            }
        }
    }
    
    func clearSearch() {
        searchTask?.cancel()
        searchResults = []
        isSearching = false
    }
    
    func itemName(for itemId: UUID?) -> String? {
        guard let itemId = itemId else { return nil }
        return items.first { $0.id == itemId }?.name
    }
    
    private func addToRecentSearches(_ query: String) {
        var searches = recentSearches
        
        // Remove if already exists
        searches.removeAll { $0 == query }
        
        // Add to beginning
        searches.insert(query, at: 0)
        
        // Keep only last 10
        if searches.count > 10 {
            searches = Array(searches.prefix(10))
        }
        
        recentSearches = searches
        UserDefaults.standard.set(searches, forKey: "documentRecentSearches")
    }
}