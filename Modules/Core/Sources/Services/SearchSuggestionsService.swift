import Foundation

/// Service for providing search suggestions and auto-complete
/// Swift 5.9 - No Swift 6 features
public final class SearchSuggestionsService {
    private let itemRepository: any ItemRepository
    private let locationRepository: any LocationRepository
    private let categoryRepository: any CategoryRepository
    private let searchHistoryRepository: any SearchHistoryRepository
    
    public init(
        itemRepository: any ItemRepository,
        locationRepository: any LocationRepository,
        categoryRepository: any CategoryRepository,
        searchHistoryRepository: any SearchHistoryRepository
    ) {
        self.itemRepository = itemRepository
        self.locationRepository = locationRepository
        self.categoryRepository = categoryRepository
        self.searchHistoryRepository = searchHistoryRepository
    }
    
    /// Get suggestions for a partial query
    public func getSuggestions(for query: String, limit: Int = 10) async -> [SearchSuggestion] {
        guard !query.isEmpty else { return [] }
        
        let lowercasedQuery = query.lowercased()
        var suggestions: [SearchSuggestion] = []
        
        // Get suggestions from different sources concurrently
        async let itemSuggestions = getItemSuggestions(for: lowercasedQuery)
        async let categorySuggestions = getCategorySuggestions(for: lowercasedQuery)
        async let locationSuggestions = getLocationSuggestions(for: lowercasedQuery)
        async let historySuggestions = getHistorySuggestions(for: lowercasedQuery)
        async let attributeSuggestions = getAttributeSuggestions(for: lowercasedQuery)
        
        // Combine all suggestions
        let allSuggestions = await itemSuggestions + categorySuggestions + locationSuggestions + historySuggestions + attributeSuggestions
        
        // Remove duplicates and sort by relevance
        let uniqueSuggestions = Array(Set(allSuggestions))
            .sorted { first, second in
                // Exact matches first
                let firstExact = first.text.lowercased().hasPrefix(lowercasedQuery)
                let secondExact = second.text.lowercased().hasPrefix(lowercasedQuery)
                if firstExact != secondExact {
                    return firstExact
                }
                
                // Then by relevance score
                if first.relevanceScore != second.relevanceScore {
                    return first.relevanceScore > second.relevanceScore
                }
                
                // Finally by text length (shorter first)
                return first.text.count < second.text.count
            }
        
        return Array(uniqueSuggestions.prefix(limit))
    }
    
    // MARK: - Private Methods
    
    private func getItemSuggestions(for query: String) async -> [SearchSuggestion] {
        do {
            let items = try await itemRepository.fetchAll()
            var suggestions: [SearchSuggestion] = []
            
            for item in items {
                // Check item name
                if item.name.lowercased().contains(query) {
                    let score = item.name.lowercased().hasPrefix(query) ? 1.0 : 0.8
                    suggestions.append(SearchSuggestion(
                        text: item.name,
                        type: .itemName,
                        relevanceScore: score,
                        metadata: ["itemId": item.id.uuidString]
                    ))
                }
                
                // Check brand
                if let brand = item.brand, brand.lowercased().contains(query) {
                    let score = brand.lowercased().hasPrefix(query) ? 0.9 : 0.7
                    suggestions.append(SearchSuggestion(
                        text: brand,
                        type: .brand,
                        relevanceScore: score
                    ))
                }
                
                // Check model
                if let model = item.model, model.lowercased().contains(query) {
                    let score = model.lowercased().hasPrefix(query) ? 0.8 : 0.6
                    suggestions.append(SearchSuggestion(
                        text: model,
                        type: .model,
                        relevanceScore: score
                    ))
                }
            }
            
            return suggestions
        } catch {
            return []
        }
    }
    
    private func getCategorySuggestions(for query: String) async -> [SearchSuggestion] {
        do {
            let categories = try await categoryRepository.fetchAll()
            return categories
                .filter { $0.name.lowercased().contains(query) }
                .map { category in
                    let score = category.name.lowercased().hasPrefix(query) ? 0.85 : 0.65
                    return SearchSuggestion(
                        text: category.name,
                        type: .category,
                        relevanceScore: score,
                        metadata: ["categoryId": category.id.uuidString]
                    )
                }
        } catch {
            return []
        }
    }
    
    private func getLocationSuggestions(for query: String) async -> [SearchSuggestion] {
        do {
            let locations = try await locationRepository.fetchAll()
            return locations
                .filter { $0.name.lowercased().contains(query) }
                .map { location in
                    let score = location.name.lowercased().hasPrefix(query) ? 0.85 : 0.65
                    return SearchSuggestion(
                        text: location.name,
                        type: .location,
                        relevanceScore: score,
                        metadata: ["locationId": location.id.uuidString]
                    )
                }
        } catch {
            return []
        }
    }
    
    private func getHistorySuggestions(for query: String) async -> [SearchSuggestion] {
        do {
            let history = try await searchHistoryRepository.fetchRecent(limit: 50)
            return history
                .filter { $0.query.lowercased().contains(query) }
                .map { entry in
                    let score = entry.query.lowercased().hasPrefix(query) ? 0.75 : 0.55
                    // Boost score based on recency and result count
                    let recencyBoost = min(0.1, 0.1 * (1.0 - entry.timestamp.timeIntervalSinceNow / (7 * 24 * 60 * 60)))
                    let resultBoost = min(0.1, Double(entry.resultCount) / 100.0)
                    
                    return SearchSuggestion(
                        text: entry.query,
                        type: .history,
                        relevanceScore: score + recencyBoost + resultBoost,
                        metadata: ["resultCount": "\(entry.resultCount)"]
                    )
                }
        } catch {
            return []
        }
    }
    
    private func getAttributeSuggestions(for query: String) async -> [SearchSuggestion] {
        var suggestions: [SearchSuggestion] = []
        
        // Common colors
        let colors = [
            "red", "blue", "green", "yellow", "orange", "purple", "pink",
            "black", "white", "gray", "brown", "silver", "gold"
        ]
        suggestions.append(contentsOf: colors
            .filter { $0.contains(query) }
            .map { SearchSuggestion(text: $0, type: .attribute, relevanceScore: 0.6) }
        )
        
        // Common conditions
        let conditions = ["new", "like new", "good", "fair", "poor", "broken"]
        suggestions.append(contentsOf: conditions
            .filter { $0.contains(query) }
            .map { SearchSuggestion(text: $0, type: .attribute, relevanceScore: 0.5) }
        )
        
        // Time references
        let timeRefs = [
            "today", "yesterday", "this week", "last week",
            "this month", "last month", "this year", "last year"
        ]
        suggestions.append(contentsOf: timeRefs
            .filter { $0.contains(query) }
            .map { SearchSuggestion(text: $0, type: .timeReference, relevanceScore: 0.7) }
        )
        
        // Price qualifiers
        let priceQualifiers = ["under", "over", "between", "less than", "more than"]
        suggestions.append(contentsOf: priceQualifiers
            .filter { $0.contains(query) }
            .map { SearchSuggestion(text: $0, type: .priceQualifier, relevanceScore: 0.5) }
        )
        
        return suggestions
    }
}

// MARK: - Search Suggestion Model
public struct SearchSuggestion: Identifiable, Hashable {
    public let id = UUID()
    public let text: String
    public let type: SuggestionType
    public let relevanceScore: Double
    public let metadata: [String: String]
    
    public init(
        text: String,
        type: SuggestionType,
        relevanceScore: Double = 0.5,
        metadata: [String: String] = [:]
    ) {
        self.text = text
        self.type = type
        self.relevanceScore = relevanceScore
        self.metadata = metadata
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(text)
        hasher.combine(type)
    }
    
    public static func == (lhs: SearchSuggestion, rhs: SearchSuggestion) -> Bool {
        lhs.text == rhs.text && lhs.type == rhs.type
    }
}

public enum SuggestionType: String, CaseIterable {
    case itemName = "item"
    case brand = "brand"
    case model = "model"
    case category = "category"
    case location = "location"
    case history = "history"
    case attribute = "attribute"
    case timeReference = "time"
    case priceQualifier = "price"
    
    public var icon: String {
        switch self {
        case .itemName: return "cube.box"
        case .brand: return "tag"
        case .model: return "number"
        case .category: return "folder"
        case .location: return "location"
        case .history: return "clock"
        case .attribute: return "paintpalette"
        case .timeReference: return "calendar"
        case .priceQualifier: return "dollarsign.circle"
        }
    }
    
    public var color: String {
        switch self {
        case .itemName: return "#4ECDC4"
        case .brand: return "#C7CEEA"
        case .model: return "#95E1D3"
        case .category: return "#FFDAB9"
        case .location: return "#FFE66D"
        case .history: return "#A8E6CF"
        case .attribute: return "#FF6B6B"
        case .timeReference: return "#95E1D3"
        case .priceQualifier: return "#A8E6CF"
        }
    }
}