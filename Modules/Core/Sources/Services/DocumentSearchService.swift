import Foundation
import Vision
import CoreSpotlight
import MobileCoreServices

/// Service for searching within document content
/// Swift 5.9 - No Swift 6 features
public final class DocumentSearchService {
    private let documentRepository: any DocumentRepository
    private let documentStorage: DocumentStorageProtocol
    private let pdfService = PDFService()
    
    public init(documentRepository: any DocumentRepository, documentStorage: DocumentStorageProtocol) {
        self.documentRepository = documentRepository
        self.documentStorage = documentStorage
    }
    
    /// Search for documents containing the query text
    public func searchDocuments(query: String, in documents: [Document]? = nil) async throws -> [DocumentSearchResult] {
        let searchableDocuments: [Document]
        if let documents = documents {
            searchableDocuments = documents
        } else {
            searchableDocuments = try await documentRepository.fetchAll()
        }
        var results: [DocumentSearchResult] = []
        
        let normalizedQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else { return [] }
        
        for document in searchableDocuments {
            var matches: [SearchMatch] = []
            var relevanceScore: Double = 0
            
            // Search in document metadata
            if let metadataMatches = searchInMetadata(document: document, query: normalizedQuery) {
                matches.append(contentsOf: metadataMatches)
                relevanceScore += Double(metadataMatches.count) * 2.0 // Higher weight for metadata matches
            }
            
            // Search in searchable text (if available)
            if let searchableText = document.searchableText {
                if let textMatches = searchInText(text: searchableText, query: normalizedQuery, documentId: document.id) {
                    matches.append(contentsOf: textMatches)
                    relevanceScore += Double(textMatches.count)
                }
            } else if document.isPDF {
                // Extract text from PDF if not cached
                if let documentURL = documentStorage.getDocumentURL(documentId: document.id),
                   let data = try? Data(contentsOf: documentURL),
                   let extractedText = await pdfService.extractText(from: data) {
                    
                    // Update document with searchable text for future searches
                    var updatedDocument = document
                    updatedDocument.searchableText = extractedText
                    try? await documentRepository.save(updatedDocument)
                    
                    if let textMatches = searchInText(text: extractedText, query: normalizedQuery, documentId: document.id) {
                        matches.append(contentsOf: textMatches)
                        relevanceScore += Double(textMatches.count)
                    }
                }
            }
            
            // Add to results if matches found
            if !matches.isEmpty {
                results.append(DocumentSearchResult(
                    document: document,
                    matches: matches,
                    relevanceScore: relevanceScore,
                    snippet: generateSnippet(from: matches)
                ))
            }
        }
        
        // Sort by relevance score
        return results.sorted { $0.relevanceScore > $1.relevanceScore }
    }
    
    /// Search documents by category
    public func searchByCategory(_ category: Document.DocumentCategory) async throws -> [Document] {
        let allDocuments = try await documentRepository.fetchAll()
        return allDocuments.filter { $0.category == category }
    }
    
    /// Search documents by tags
    public func searchByTags(_ tags: [String]) async throws -> [Document] {
        let allDocuments = try await documentRepository.fetchAll()
        let normalizedTags = Set(tags.map { $0.lowercased() })
        
        return allDocuments.filter { document in
            let documentTags = Set(document.tags.map { $0.lowercased() })
            return !normalizedTags.intersection(documentTags).isEmpty
        }
    }
    
    /// Search documents by date range
    public func searchByDateRange(from startDate: Date, to endDate: Date) async throws -> [Document] {
        let allDocuments = try await documentRepository.fetchAll()
        return allDocuments.filter { document in
            document.createdAt >= startDate && document.createdAt <= endDate
        }
    }
    
    /// Advanced search with multiple criteria
    public func advancedSearch(criteria: SearchCriteria) async throws -> [DocumentSearchResult] {
        var filteredDocuments = try await documentRepository.fetchAll()
        
        // Apply filters
        if let category = criteria.category {
            filteredDocuments = filteredDocuments.filter { $0.category == category }
        }
        
        if let itemId = criteria.itemId {
            filteredDocuments = filteredDocuments.filter { $0.itemId == itemId }
        }
        
        if !criteria.tags.isEmpty {
            let normalizedTags = Set(criteria.tags.map { $0.lowercased() })
            filteredDocuments = filteredDocuments.filter { document in
                let documentTags = Set(document.tags.map { $0.lowercased() })
                return !normalizedTags.intersection(documentTags).isEmpty
            }
        }
        
        if let dateRange = criteria.dateRange {
            filteredDocuments = filteredDocuments.filter { document in
                document.createdAt >= dateRange.start && document.createdAt <= dateRange.end
            }
        }
        
        if let fileSizeRange = criteria.fileSizeRange {
            filteredDocuments = filteredDocuments.filter { document in
                document.fileSize >= fileSizeRange.min && document.fileSize <= fileSizeRange.max
            }
        }
        
        // Apply text search if query provided
        if let query = criteria.textQuery, !query.isEmpty {
            return try await searchDocuments(query: query, in: filteredDocuments)
        } else {
            // Return all filtered documents as results
            return filteredDocuments.map { document in
                DocumentSearchResult(
                    document: document,
                    matches: [],
                    relevanceScore: 1.0,
                    snippet: nil
                )
            }
        }
    }
    
    /// Index documents for Spotlight search
    public func indexDocumentsForSpotlight() async throws {
        let documents = try await documentRepository.fetchAll()
        var searchableItems: [CSSearchableItem] = []
        
        for document in documents {
            let attributeSet = CSSearchableItemAttributeSet(contentType: UTType.data)
            attributeSet.title = document.name
            attributeSet.contentDescription = document.notes
            attributeSet.keywords = document.tags
            attributeSet.contentCreationDate = document.createdAt
            attributeSet.contentModificationDate = document.updatedAt
            
            if let searchableText = document.searchableText {
                attributeSet.textContent = searchableText
            }
            
            let item = CSSearchableItem(
                uniqueIdentifier: "document-\(document.id.uuidString)",
                domainIdentifier: "com.homeinventory.documents",
                attributeSet: attributeSet
            )
            
            searchableItems.append(item)
        }
        
        // Index items in Spotlight
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            CSSearchableIndex.default().indexSearchableItems(searchableItems) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func searchInMetadata(document: Document, query: String) -> [SearchMatch]? {
        var matches: [SearchMatch] = []
        
        // Search in name
        if let range = document.name.lowercased().range(of: query) {
            matches.append(SearchMatch(
                field: .name,
                text: document.name,
                range: NSRange(range, in: document.name),
                context: document.name
            ))
        }
        
        // Search in notes
        if let notes = document.notes,
           let range = notes.lowercased().range(of: query) {
            let context = extractContext(from: notes, around: range)
            matches.append(SearchMatch(
                field: .notes,
                text: notes,
                range: NSRange(range, in: notes),
                context: context
            ))
        }
        
        // Search in tags
        for tag in document.tags {
            if let range = tag.lowercased().range(of: query) {
                matches.append(SearchMatch(
                    field: .tag,
                    text: tag,
                    range: NSRange(range, in: tag),
                    context: tag
                ))
            }
        }
        
        // Search in subcategory
        if let subcategory = document.subcategory,
           let range = subcategory.lowercased().range(of: query) {
            matches.append(SearchMatch(
                field: .subcategory,
                text: subcategory,
                range: NSRange(range, in: subcategory),
                context: subcategory
            ))
        }
        
        return matches.isEmpty ? nil : matches
    }
    
    private func searchInText(text: String, query: String, documentId: UUID) -> [SearchMatch]? {
        let lowercasedText = text.lowercased()
        var matches: [SearchMatch] = []
        var searchRange = lowercasedText.startIndex..<lowercasedText.endIndex
        
        while let range = lowercasedText.range(of: query, options: [], range: searchRange) {
            let context = extractContext(from: text, around: range, in: lowercasedText)
            matches.append(SearchMatch(
                field: .content,
                text: text,
                range: NSRange(range, in: text),
                context: context
            ))
            
            searchRange = range.upperBound..<lowercasedText.endIndex
            
            // Limit matches per document
            if matches.count >= 10 {
                break
            }
        }
        
        return matches.isEmpty ? nil : matches
    }
    
    private func extractContext(from text: String, around range: Range<String.Index>, in lowercasedText: String? = nil) -> String {
        let contextLength = 50
        let startOffset = max(0, text.distance(from: text.startIndex, to: range.lowerBound) - contextLength)
        let endOffset = min(text.count, text.distance(from: text.startIndex, to: range.upperBound) + contextLength)
        
        let startIndex = text.index(text.startIndex, offsetBy: startOffset)
        let endIndex = text.index(text.startIndex, offsetBy: endOffset)
        
        var context = String(text[startIndex..<endIndex])
        
        // Add ellipsis if truncated
        if startOffset > 0 {
            context = "..." + context
        }
        if endOffset < text.count {
            context = context + "..."
        }
        
        return context.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func generateSnippet(from matches: [SearchMatch]) -> String? {
        guard let firstMatch = matches.first else { return nil }
        return firstMatch.context
    }
}

// MARK: - Supporting Types

/// Document search result
public struct DocumentSearchResult: Identifiable {
    public let id = UUID()
    public let document: Document
    public let matches: [SearchMatch]
    public let relevanceScore: Double
    public let snippet: String?
}

/// Search match within a document
public struct SearchMatch {
    public let field: SearchField
    public let text: String
    public let range: NSRange
    public let context: String
    
    public enum SearchField {
        case name
        case content
        case notes
        case tag
        case subcategory
    }
}

/// Advanced search criteria
public struct SearchCriteria {
    public var textQuery: String?
    public var category: Document.DocumentCategory?
    public var tags: [String] = []
    public var itemId: UUID?
    public var dateRange: (start: Date, end: Date)?
    public var fileSizeRange: (min: Int64, max: Int64)?
    
    public init(
        textQuery: String? = nil,
        category: Document.DocumentCategory? = nil,
        tags: [String] = [],
        itemId: UUID? = nil,
        dateRange: (start: Date, end: Date)? = nil,
        fileSizeRange: (min: Int64, max: Int64)? = nil
    ) {
        self.textQuery = textQuery
        self.category = category
        self.tags = tags
        self.itemId = itemId
        self.dateRange = dateRange
        self.fileSizeRange = fileSizeRange
    }
}