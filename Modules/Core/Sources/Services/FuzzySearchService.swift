import Foundation

/// Service for performing fuzzy string matching to find items despite typos
/// Swift 5.9 - No Swift 6 features
public final class FuzzySearchService {
    
    public init() {}
    
    /// Calculate the Levenshtein distance between two strings
    /// This measures the minimum number of single-character edits required to change one string into another
    public func levenshteinDistance(_ source: String, _ target: String) -> Int {
        let source = source.lowercased()
        let target = target.lowercased()
        
        if source.isEmpty { return target.count }
        if target.isEmpty { return source.count }
        
        let sourceCount = source.count
        let targetCount = target.count
        
        // Create a 2D array for dynamic programming
        var matrix = Array(repeating: Array(repeating: 0, count: targetCount + 1), count: sourceCount + 1)
        
        // Initialize first row and column
        for i in 0...sourceCount {
            matrix[i][0] = i
        }
        for j in 0...targetCount {
            matrix[0][j] = j
        }
        
        // Fill the matrix
        for i in 1...sourceCount {
            for j in 1...targetCount {
                let sourceIndex = source.index(source.startIndex, offsetBy: i - 1)
                let targetIndex = target.index(target.startIndex, offsetBy: j - 1)
                
                if source[sourceIndex] == target[targetIndex] {
                    matrix[i][j] = matrix[i - 1][j - 1]
                } else {
                    matrix[i][j] = min(
                        matrix[i - 1][j] + 1,      // deletion
                        matrix[i][j - 1] + 1,      // insertion
                        matrix[i - 1][j - 1] + 1   // substitution
                    )
                }
            }
        }
        
        return matrix[sourceCount][targetCount]
    }
    
    /// Calculate similarity score between 0 and 1
    /// 1 means identical, 0 means completely different
    public func similarityScore(_ source: String, _ target: String) -> Double {
        let distance = levenshteinDistance(source, target)
        let maxLength = max(source.count, target.count)
        
        if maxLength == 0 { return 1.0 }
        
        return 1.0 - (Double(distance) / Double(maxLength))
    }
    
    /// Check if a string contains a fuzzy match for the query
    public func fuzzyContains(_ text: String, query: String, threshold: Double = 0.7) -> Bool {
        // First check for exact substring match
        if text.lowercased().contains(query.lowercased()) {
            return true
        }
        
        // Split text into words and check each word
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        for word in words {
            if similarityScore(word, query) >= threshold {
                return true
            }
        }
        
        // Check if query matches the beginning of any word with fuzzy matching
        let queryWords = query.components(separatedBy: .whitespacesAndNewlines)
        for queryWord in queryWords {
            for textWord in words {
                if textWord.count >= queryWord.count {
                    let prefix = String(textWord.prefix(queryWord.count))
                    if similarityScore(prefix, queryWord) >= threshold {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    /// Find best fuzzy matches for a query in a list of items
    public func findBestMatches<T>(
        query: String,
        in items: [T],
        keyPath: KeyPath<T, String>,
        threshold: Double = 0.6,
        maxResults: Int = 10
    ) -> [(item: T, score: Double)] {
        var matches: [(item: T, score: Double)] = []
        
        for item in items {
            let text = item[keyPath: keyPath]
            
            // Calculate overall score
            var score = 0.0
            
            // Exact match gets highest score
            if text.lowercased() == query.lowercased() {
                score = 1.0
            }
            // Contains exact substring
            else if text.lowercased().contains(query.lowercased()) {
                score = 0.9
            }
            // Fuzzy match on whole string
            else {
                let wholeScore = similarityScore(text, query)
                
                // Also check word-by-word matching
                let words = text.components(separatedBy: .whitespacesAndNewlines)
                let wordScores = words.map { similarityScore($0, query) }
                let bestWordScore = wordScores.max() ?? 0
                
                // Use the better of the two scores
                score = max(wholeScore, bestWordScore * 0.95) // Slight penalty for word matches
            }
            
            if score >= threshold {
                matches.append((item: item, score: score))
            }
        }
        
        // Sort by score descending and take top results
        return Array(matches.sorted { $0.score > $1.score }.prefix(maxResults))
    }
    
    /// Suggest corrections for a misspelled query based on available terms
    public func suggestCorrections(
        for query: String,
        from availableTerms: [String],
        maxSuggestions: Int = 5
    ) -> [String] {
        let matches = findBestMatches(
            query: query,
            in: availableTerms,
            keyPath: \.self,
            threshold: 0.5,
            maxResults: maxSuggestions
        )
        
        return matches.map { $0.item }
    }
    
    /// Check if two strings are phonetically similar (basic implementation)
    public func phoneticallySimilar(_ source: String, _ target: String) -> Bool {
        let source = source.lowercased()
        let target = target.lowercased()
        
        // Simple phonetic replacements
        let phoneticReplacements = [
            ("ph", "f"),
            ("ck", "k"),
            ("ch", "k"),
            ("ght", "t"),
            ("ough", "o"),
            ("eau", "o"),
            ("qu", "kw"),
            ("x", "ks"),
            ("tion", "shun"),
            ("sion", "shun")
        ]
        
        var sourcePhonetic = source
        var targetPhonetic = target
        
        for (pattern, replacement) in phoneticReplacements {
            sourcePhonetic = sourcePhonetic.replacingOccurrences(of: pattern, with: replacement)
            targetPhonetic = targetPhonetic.replacingOccurrences(of: pattern, with: replacement)
        }
        
        // Remove vowels for consonant skeleton comparison
        let vowels = CharacterSet(charactersIn: "aeiou")
        let sourceConsonants = sourcePhonetic.components(separatedBy: vowels).joined()
        let targetConsonants = targetPhonetic.components(separatedBy: vowels).joined()
        
        // Check if consonant skeletons are similar
        return similarityScore(sourceConsonants, targetConsonants) >= 0.7
    }
}

// MARK: - Fuzzy Search Extensions
public extension Array where Element == Item {
    /// Search items with fuzzy matching
    func fuzzySearch(query: String, fuzzyService: FuzzySearchService = FuzzySearchService()) -> [Item] {
        guard !query.isEmpty else { return self }
        
        var scoredItems: [(item: Item, score: Double)] = []
        
        for item in self {
            var maxScore = 0.0
            
            // Check name
            let nameScore = fuzzyService.similarityScore(item.name, query)
            maxScore = Swift.max(maxScore, nameScore)
            
            // Check brand
            if let brand = item.brand {
                let brandScore = fuzzyService.similarityScore(brand, query)
                maxScore = Swift.max(maxScore, brandScore * 0.9) // Slight penalty for brand matches
            }
            
            // Check model
            if let model = item.model {
                let modelScore = fuzzyService.similarityScore(model, query)
                maxScore = Swift.max(maxScore, modelScore * 0.8) // More penalty for model matches
            }
            
            // Check notes
            if let notes = item.notes {
                if fuzzyService.fuzzyContains(notes, query: query, threshold: 0.7) {
                    maxScore = Swift.max(maxScore, 0.7)
                }
            }
            
            // Check tags
            for tag in item.tags {
                let tagScore = fuzzyService.similarityScore(tag, query)
                maxScore = Swift.max(maxScore, tagScore * 0.7)
            }
            
            if maxScore >= 0.5 { // Minimum threshold
                scoredItems.append((item: item, score: maxScore))
            }
        }
        
        // Sort by score and return items
        return scoredItems
            .sorted { $0.score > $1.score }
            .map { $0.item }
    }
}