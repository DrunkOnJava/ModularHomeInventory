import Foundation
import NaturalLanguage

/// Service for parsing and processing natural language search queries
/// Swift 5.9 - No Swift 6 features
public final class NaturalLanguageSearchService {
    public init() {}
    
    // MARK: - Public API
    
    /// Parse natural language query into structured search components
    public func parseQuery(_ query: String) -> NaturalLanguageQuery {
        let tokens = tokenize(query)
        let taggedTokens = tagTokens(tokens)
        
        var components = NaturalLanguageQuery()
        
        // Extract components from tagged tokens
        components.colors = extractColors(from: taggedTokens)
        components.items = extractItems(from: taggedTokens)
        components.locations = extractLocations(from: taggedTokens)
        components.timeReferences = extractTimeReferences(from: taggedTokens)
        components.priceRanges = extractPriceRanges(from: taggedTokens)
        components.brands = extractBrands(from: taggedTokens)
        components.categories = extractCategories(from: taggedTokens)
        components.conditions = extractConditions(from: taggedTokens)
        components.actions = extractActions(from: taggedTokens)
        components.attributes = extractAttributes(from: taggedTokens)
        
        // Keep original query for fallback
        components.originalQuery = query
        
        return components
    }
    
    /// Convert natural language query to search criteria
    public func convertToSearchCriteria(_ nlQuery: NaturalLanguageQuery) -> ItemSearchCriteria {
        var criteria = ItemSearchCriteria()
        
        // Build search text from items and attributes
        let searchTerms = nlQuery.items + nlQuery.attributes + nlQuery.colors
        if !searchTerms.isEmpty {
            criteria.searchText = searchTerms.joined(separator: " ")
        }
        
        // Map categories
        if !nlQuery.categories.isEmpty {
            criteria.categories = nlQuery.categories.compactMap { categoryName in
                ItemCategory.allCases.first { $0.displayName.lowercased() == categoryName.lowercased() }
            }
        }
        
        // Map locations
        if !nlQuery.locations.isEmpty {
            criteria.locationNames = nlQuery.locations
        }
        
        // Map brands
        if !nlQuery.brands.isEmpty {
            criteria.brands = nlQuery.brands
        }
        
        // Map time references to date ranges
        if let timeRef = nlQuery.timeReferences.first {
            let dateRange = convertTimeReference(timeRef)
            criteria.purchaseDateStart = dateRange.start
            criteria.purchaseDateEnd = dateRange.end
        }
        
        // Map price ranges
        if let priceRange = nlQuery.priceRanges.first {
            criteria.minPrice = priceRange.min
            criteria.maxPrice = priceRange.max
        }
        
        // Map conditions
        if !nlQuery.conditions.isEmpty {
            criteria.conditions = nlQuery.conditions.compactMap { conditionName in
                ItemCondition.allCases.first { $0.rawValue.lowercased() == conditionName.lowercased() }
            }
        }
        
        // Handle special actions
        for action in nlQuery.actions {
            switch action.lowercased() {
            case "warranty", "under warranty":
                criteria.underWarranty = true
            case "recently added", "new":
                criteria.recentlyAdded = true
            default:
                break
            }
        }
        
        return criteria
    }
    
    // MARK: - Tokenization
    
    private func tokenize(_ query: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = query
        
        var tokens: [String] = []
        tokenizer.enumerateTokens(in: query.startIndex..<query.endIndex) { range, _ in
            tokens.append(String(query[range]))
            return true
        }
        
        return tokens
    }
    
    // MARK: - Token Tagging
    
    private func tagTokens(_ tokens: [String]) -> [(token: String, tag: NLTag?)] {
        let tagger = NLTagger(tagSchemes: [.lexicalClass, .nameType])
        let text = tokens.joined(separator: " ")
        tagger.string = text
        
        var taggedTokens: [(String, NLTag?)] = []
        var currentIndex = text.startIndex
        
        for token in tokens {
            if let range = text.range(of: token, range: currentIndex..<text.endIndex) {
                let tags = tagger.tags(in: range, unit: .word, scheme: .lexicalClass)
                if let tag = tags.first?.0 {
                    taggedTokens.append((token, tag))
                } else {
                    taggedTokens.append((token, nil))
                }
                currentIndex = range.upperBound
            } else {
                taggedTokens.append((token, nil))
            }
        }
        
        return taggedTokens
    }
    
    // MARK: - Component Extraction
    
    private func extractColors(from tokens: [(String, NLTag?)]) -> [String] {
        let colorKeywords = [
            "red", "blue", "green", "yellow", "orange", "purple", "pink",
            "black", "white", "gray", "grey", "brown", "beige", "tan",
            "gold", "silver", "bronze", "copper", "navy", "turquoise",
            "maroon", "coral", "teal", "olive", "crimson", "indigo"
        ]
        
        return tokens
            .map { $0.0.lowercased() }
            .filter { colorKeywords.contains($0) }
    }
    
    private func extractItems(from tokens: [(String, NLTag?)]) -> [String] {
        var items: [String] = []
        
        // Look for nouns that could be items
        for i in 0..<tokens.count {
            let (token, tag) = tokens[i]
            
            if tag == .noun {
                // Check if it's preceded by an adjective
                if i > 0 && tokens[i-1].1 == .adjective {
                    items.append("\(tokens[i-1].0) \(token)")
                } else {
                    items.append(token)
                }
            }
        }
        
        return items
    }
    
    private func extractLocations(from tokens: [(String, NLTag?)]) -> [String] {
        let locationKeywords = [
            "bedroom", "kitchen", "bathroom", "living room", "dining room",
            "garage", "basement", "attic", "office", "closet", "pantry",
            "shed", "storage", "laundry", "hallway", "foyer", "porch",
            "deck", "patio", "yard", "garden"
        ]
        
        var locations: [String] = []
        var i = 0
        
        while i < tokens.count {
            let token = tokens[i].0.lowercased()
            
            // Check for two-word locations
            if i < tokens.count - 1 {
                let twoWords = "\(token) \(tokens[i+1].0.lowercased())"
                if locationKeywords.contains(twoWords) {
                    locations.append(twoWords)
                    i += 2
                    continue
                }
            }
            
            // Check single word locations
            if locationKeywords.contains(token) {
                locations.append(token)
            }
            
            i += 1
        }
        
        return locations
    }
    
    private func extractTimeReferences(from tokens: [(String, NLTag?)]) -> [String] {
        var timeRefs: [String] = []
        let tokenStrings = tokens.map { $0.0.lowercased() }
        
        // Common time patterns
        let timePatterns = [
            ["last", "week"],
            ["last", "month"],
            ["last", "year"],
            ["this", "week"],
            ["this", "month"],
            ["this", "year"],
            ["past", "week"],
            ["past", "month"],
            ["past", "year"],
            ["yesterday"],
            ["today"],
            ["recently"]
        ]
        
        for pattern in timePatterns {
            if pattern.count == 1 {
                if tokenStrings.contains(pattern[0]) {
                    timeRefs.append(pattern[0])
                }
            } else if pattern.count == 2 {
                for i in 0..<tokenStrings.count-1 {
                    if tokenStrings[i] == pattern[0] && tokenStrings[i+1] == pattern[1] {
                        timeRefs.append("\(pattern[0]) \(pattern[1])")
                    }
                }
            }
        }
        
        // Look for specific months
        let months = [
            "january", "february", "march", "april", "may", "june",
            "july", "august", "september", "october", "november", "december"
        ]
        
        for month in months {
            if tokenStrings.contains(month) {
                timeRefs.append(month)
            }
        }
        
        return timeRefs
    }
    
    private func extractPriceRanges(from tokens: [(String, NLTag?)]) -> [PriceRange] {
        var priceRanges: [PriceRange] = []
        let tokenStrings = tokens.map { $0.0 }
        
        for i in 0..<tokenStrings.count {
            let token = tokenStrings[i]
            
            // Look for currency symbols or price indicators
            if token.hasPrefix("$") || (i > 0 && tokenStrings[i-1] == "$") {
                if let price = extractPrice(from: token) {
                    // Check for range indicators
                    if i > 0 && (tokenStrings[i-1].lowercased() == "under" || tokenStrings[i-1].lowercased() == "below") {
                        priceRanges.append(PriceRange(min: nil, max: price))
                    } else if i > 0 && (tokenStrings[i-1].lowercased() == "over" || tokenStrings[i-1].lowercased() == "above") {
                        priceRanges.append(PriceRange(min: price, max: nil))
                    } else if i < tokenStrings.count - 2 && tokenStrings[i+1].lowercased() == "to" {
                        if let maxPrice = extractPrice(from: tokenStrings[i+2]) {
                            priceRanges.append(PriceRange(min: price, max: maxPrice))
                        }
                    } else {
                        // Exact price becomes a small range
                        priceRanges.append(PriceRange(min: price * 0.9, max: price * 1.1))
                    }
                }
            }
        }
        
        return priceRanges
    }
    
    private func extractPrice(from token: String) -> Double? {
        let cleanedToken = token.replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
        return Double(cleanedToken)
    }
    
    private func extractBrands(from tokens: [(String, NLTag?)]) -> [String] {
        // Common brand detection patterns
        var brands: [String] = []
        
        for i in 0..<tokens.count {
            let (token, tag) = tokens[i]
            
            // Proper nouns are often brands
            if tag == .personalName || tag == .organizationName {
                brands.append(token)
            }
            
            // Check for capitalized words that might be brands
            if token.first?.isUppercase == true && tag == .noun {
                // Verify it's not at the beginning of a sentence
                if i > 0 || tokens.count == 1 {
                    brands.append(token)
                }
            }
        }
        
        return brands
    }
    
    private func extractCategories(from tokens: [(String, NLTag?)]) -> [String] {
        let categoryKeywords = ItemCategory.allCases.map { $0.displayName.lowercased() }
        
        return tokens
            .map { $0.0.lowercased() }
            .filter { categoryKeywords.contains($0) }
    }
    
    private func extractConditions(from tokens: [(String, NLTag?)]) -> [String] {
        let conditionKeywords = ["new", "excellent", "good", "fair", "poor", "used", "mint", "pristine"]
        
        return tokens
            .map { $0.0.lowercased() }
            .filter { conditionKeywords.contains($0) }
    }
    
    private func extractActions(from tokens: [(String, NLTag?)]) -> [String] {
        let actionKeywords = [
            "bought", "purchased", "added", "warranty", "favorited",
            "favorite", "starred", "recent", "recently", "new"
        ]
        
        return tokens
            .map { $0.0.lowercased() }
            .filter { actionKeywords.contains($0) }
    }
    
    private func extractAttributes(from tokens: [(String, NLTag?)]) -> [String] {
        var attributes: [String] = []
        
        // Look for adjectives that aren't already categorized
        let usedWords = Set(
            extractColors(from: tokens) +
            extractConditions(from: tokens)
        )
        
        for (token, tag) in tokens {
            if tag == .adjective && !usedWords.contains(token.lowercased()) {
                attributes.append(token)
            }
        }
        
        return attributes
    }
    
    // MARK: - Time Reference Conversion
    
    private func convertTimeReference(_ reference: String) -> (start: Date?, end: Date?) {
        let calendar = Calendar.current
        let now = Date()
        
        switch reference.lowercased() {
        case "today":
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start)
            return (start, end)
            
        case "yesterday":
            let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
            let start = calendar.startOfDay(for: yesterday)
            let end = calendar.startOfDay(for: now)
            return (start, end)
            
        case "this week":
            let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start
            return (start, now)
            
        case "last week":
            let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: now)!
            let interval = calendar.dateInterval(of: .weekOfYear, for: lastWeek)
            return (interval?.start, interval?.end)
            
        case "this month":
            let start = calendar.dateInterval(of: .month, for: now)?.start
            return (start, now)
            
        case "last month":
            let lastMonth = calendar.date(byAdding: .month, value: -1, to: now)!
            let interval = calendar.dateInterval(of: .month, for: lastMonth)
            return (interval?.start, interval?.end)
            
        case "this year":
            let start = calendar.dateInterval(of: .year, for: now)?.start
            return (start, now)
            
        case "last year":
            let lastYear = calendar.date(byAdding: .year, value: -1, to: now)!
            let interval = calendar.dateInterval(of: .year, for: lastYear)
            return (interval?.start, interval?.end)
            
        case "recently", "recent":
            let start = calendar.date(byAdding: .day, value: -30, to: now)
            return (start, now)
            
        default:
            // Check if it's a month name
            let months = [
                "january": 1, "february": 2, "march": 3, "april": 4,
                "may": 5, "june": 6, "july": 7, "august": 8,
                "september": 9, "october": 10, "november": 11, "december": 12
            ]
            
            if let monthNumber = months[reference.lowercased()] {
                let year = calendar.component(.year, from: now)
                let components = DateComponents(year: year, month: monthNumber)
                if let date = calendar.date(from: components) {
                    let interval = calendar.dateInterval(of: .month, for: date)
                    return (interval?.start, interval?.end)
                }
            }
            
            return (nil, nil)
        }
    }
}

// MARK: - Data Models

/// Structured representation of a natural language query
public struct NaturalLanguageQuery {
    public var originalQuery: String = ""
    public var items: [String] = []
    public var colors: [String] = []
    public var locations: [String] = []
    public var timeReferences: [String] = []
    public var priceRanges: [PriceRange] = []
    public var brands: [String] = []
    public var categories: [String] = []
    public var conditions: [String] = []
    public var actions: [String] = []
    public var attributes: [String] = []
    
    public init() {}
}

/// Price range for queries
public struct PriceRange {
    public let min: Double?
    public let max: Double?
    
    public init(min: Double?, max: Double?) {
        self.min = min
        self.max = max
    }
}

/// Extended search criteria for items
public struct ItemSearchCriteria: Codable, Equatable {
    public var searchText: String?
    public var categories: [ItemCategory] = []
    public var locationNames: [String] = []
    public var brands: [String] = []
    public var purchaseDateStart: Date?
    public var purchaseDateEnd: Date?
    public var minPrice: Double?
    public var maxPrice: Double?
    public var conditions: [ItemCondition] = []
    public var underWarranty: Bool?
    public var recentlyAdded: Bool?
    public var useFuzzySearch: Bool?
    public var fuzzyThreshold: Double?
    
    public init() {}
}