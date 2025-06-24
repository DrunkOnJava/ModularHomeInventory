import Foundation

/// Service for looking up product information from barcodes
/// Uses multiple free sources with fallback
public protocol BarcodeLookupService {
    func lookupProduct(barcode: String) async throws -> BarcodeProduct?
}

/// Product information from barcode lookup
public struct BarcodeProduct: Codable, Equatable {
    public let barcode: String
    public let name: String
    public let brand: String?
    public let category: String?
    public let description: String?
    public let imageURL: String?
    public let source: String
    public let additionalImages: [String]?
    
    public init(
        barcode: String,
        name: String,
        brand: String? = nil,
        category: String? = nil,
        description: String? = nil,
        imageURL: String? = nil,
        source: String,
        additionalImages: [String]? = nil
    ) {
        self.barcode = barcode
        self.name = name
        self.brand = brand
        self.category = category
        self.description = description
        self.imageURL = imageURL
        self.source = source
        self.additionalImages = additionalImages
    }
}

/// Default implementation using multiple free sources
public final class DefaultBarcodeLookupService: BarcodeLookupService {
    private let cache = BarcodeCache.shared
    private let providers: [BarcodeProvider] = [
        CachedBarcodeProvider(),
        OpenFoodFactsProvider(),      // Free, unlimited
        UPCItemDBProvider(),          // Free tier: 100/day
        BarcodespiderProvider(),      // Free tier: 1000/month
        BarcodeMonsterProvider(),     // Free with registration
        DatakickProvider()            // Community driven, free
    ]
    
    public init() {}
    
    public func lookupProduct(barcode: String) async throws -> BarcodeProduct? {
        // Clean the barcode (remove spaces, validate format)
        let cleanedBarcode = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Validate barcode format
        guard isValidBarcode(cleanedBarcode) else {
            throw BarcodeLookupError.invalidBarcode
        }
        
        // Try each provider in order
        for provider in providers {
            do {
                if let product = try await provider.lookup(cleanedBarcode) {
                    // Cache successful lookups
                    await cache.store(product)
                    return product
                }
            } catch {
                // Log but continue to next provider
                print("[\(type(of: provider))] Lookup failed: \(error.localizedDescription)")
            }
        }
        
        return nil
    }
    
    private func isValidBarcode(_ barcode: String) -> Bool {
        // Basic validation for common barcode formats
        let barcodeRegex = "^[0-9]{8,14}$" // UPC-A, UPC-E, EAN-8, EAN-13
        return barcode.range(of: barcodeRegex, options: .regularExpression) != nil
    }
}

// MARK: - Error Types
public enum BarcodeLookupError: LocalizedError {
    case invalidBarcode
    case rateLimitExceeded
    case networkError
    case parseError
    
    public var errorDescription: String? {
        switch self {
        case .invalidBarcode:
            return "Invalid barcode format"
        case .rateLimitExceeded:
            return "API rate limit exceeded"
        case .networkError:
            return "Network connection error"
        case .parseError:
            return "Failed to parse response"
        }
    }
}

// MARK: - Provider Protocol
protocol BarcodeProvider {
    var name: String { get }
    func lookup(_ barcode: String) async throws -> BarcodeProduct?
}

// MARK: - Cache Provider
class CachedBarcodeProvider: BarcodeProvider {
    let name = "Local Cache"
    
    func lookup(_ barcode: String) async throws -> BarcodeProduct? {
        return await BarcodeCache.shared.retrieve(barcode: barcode)
    }
}

// MARK: - Open Food Facts Provider (FREE, Unlimited)
class OpenFoodFactsProvider: BarcodeProvider {
    let name = "Open Food Facts"
    private let baseURL = "https://world.openfoodfacts.org/api/v2/product/"
    
    func lookup(_ barcode: String) async throws -> BarcodeProduct? {
        guard let url = URL(string: "\(baseURL)\(barcode).json") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.setValue("HomeInventory/1.0", forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return nil
        }
        
        let result = try JSONDecoder().decode(OpenFoodFactsResponse.self, from: data)
        
        guard result.status == 1, let product = result.product else {
            return nil
        }
        
        // Build image array
        var images: [String] = []
        if let frontImage = product.image_front_url {
            images.append(frontImage)
        }
        if let nutritionImage = product.image_nutrition_url {
            images.append(nutritionImage)
        }
        if let ingredientsImage = product.image_ingredients_url {
            images.append(ingredientsImage)
        }
        
        return BarcodeProduct(
            barcode: barcode,
            name: product.product_name ?? "Unknown Product",
            brand: product.brands,
            category: product.categories?.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces),
            description: product.generic_name,
            imageURL: product.image_url ?? product.image_front_url,
            source: name,
            additionalImages: images.isEmpty ? nil : images
        )
    }
}

// MARK: - UPCItemDB Provider (FREE: 100/day)
class UPCItemDBProvider: BarcodeProvider {
    let name = "UPCitemDB"
    private let baseURL = "https://api.upcitemdb.com/prod/trial/lookup"
    private let dailyLimit = 100
    
    func lookup(_ barcode: String) async throws -> BarcodeProduct? {
        // Check if we've hit daily limit (implement tracking)
        guard await checkDailyLimit() else {
            throw BarcodeLookupError.rateLimitExceeded
        }
        
        guard let url = URL(string: baseURL) else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add barcode as query parameter
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        components?.queryItems = [URLQueryItem(name: "upc", value: barcode)]
        
        guard let finalURL = components?.url else { return nil }
        request.url = finalURL
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return nil
        }
        
        let result = try JSONDecoder().decode(UPCItemDBResponse.self, from: data)
        
        guard let item = result.items?.first else {
            return nil
        }
        
        return BarcodeProduct(
            barcode: barcode,
            name: item.title ?? "Unknown Product",
            brand: item.brand,
            category: item.category,
            description: item.description,
            imageURL: item.images?.first,
            source: name,
            additionalImages: item.images
        )
    }
    
    private func checkDailyLimit() async -> Bool {
        // TODO: Implement daily limit tracking
        return true
    }
}

// MARK: - Barcodespider Provider (FREE: 1000/month)
class BarcodespiderProvider: BarcodeProvider {
    let name = "Barcodespider"
    private let baseURL = "https://www.barcodespider.com/api/v1/lookup"
    
    func lookup(_ barcode: String) async throws -> BarcodeProduct? {
        // Note: Requires registration for API key
        // This is a placeholder implementation
        return nil
    }
}

// MARK: - BarcodeMonster Provider (FREE with registration)
class BarcodeMonsterProvider: BarcodeProvider {
    let name = "BarcodeMonster"
    
    func lookup(_ barcode: String) async throws -> BarcodeProduct? {
        // Note: Requires registration
        // Free tier available
        return nil
    }
}

// MARK: - Datakick Provider (Community driven, FREE)
class DatakickProvider: BarcodeProvider {
    let name = "Datakick"
    private let baseURL = "https://www.datakick.org/api/items/"
    
    func lookup(_ barcode: String) async throws -> BarcodeProduct? {
        guard let url = URL(string: "\(baseURL)\(barcode)") else {
            return nil
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return nil
        }
        
        let item = try JSONDecoder().decode(DatakickItem.self, from: data)
        
        return BarcodeProduct(
            barcode: barcode,
            name: item.name ?? "Unknown Product",
            brand: item.brand_name,
            category: nil,
            description: item.description,
            imageURL: item.images?.first?.url,
            source: name
        )
    }
}

// MARK: - Local Cache
actor BarcodeCache {
    static let shared = BarcodeCache()
    
    private var memoryCache: [String: BarcodeProduct] = [:]
    private var diskCache: [String: BarcodeProduct] = [:]
    private let cacheFile: URL
    private let maxMemoryCacheSize = 100
    
    private init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.cacheFile = documentsPath.appendingPathComponent("barcode_cache.json")
        Task {
            await loadCache()
        }
    }
    
    func store(_ product: BarcodeProduct) async {
        // Add to memory cache
        memoryCache[product.barcode] = product
        
        // Trim memory cache if needed
        if memoryCache.count > maxMemoryCacheSize {
            // Remove oldest entries (simple FIFO for now)
            let keysToRemove = memoryCache.keys.prefix(20)
            keysToRemove.forEach { memoryCache.removeValue(forKey: $0) }
        }
        
        // Add to disk cache
        diskCache[product.barcode] = product
        await saveCache()
    }
    
    func retrieve(barcode: String) async -> BarcodeProduct? {
        // Check memory cache first
        if let product = memoryCache[barcode] {
            return product
        }
        
        // Check disk cache
        if let product = diskCache[barcode] {
            // Promote to memory cache
            memoryCache[barcode] = product
            return product
        }
        
        return nil
    }
    
    func clearCache() async {
        memoryCache.removeAll()
        diskCache.removeAll()
        try? FileManager.default.removeItem(at: cacheFile)
    }
    
    private func loadCache() async {
        guard FileManager.default.fileExists(atPath: cacheFile.path) else { return }
        
        do {
            let data = try Data(contentsOf: cacheFile)
            diskCache = try JSONDecoder().decode([String: BarcodeProduct].self, from: data)
            print("Loaded \(diskCache.count) cached barcodes")
        } catch {
            print("Failed to load barcode cache: \(error)")
        }
    }
    
    private func saveCache() async {
        do {
            let data = try JSONEncoder().encode(diskCache)
            try data.write(to: cacheFile)
        } catch {
            print("Failed to save barcode cache: \(error)")
        }
    }
}

// MARK: - API Response Models

// Open Food Facts
struct OpenFoodFactsResponse: Codable {
    let status: Int
    let product: OpenFoodFactsProduct?
}

struct OpenFoodFactsProduct: Codable {
    let product_name: String?
    let brands: String?
    let categories: String?
    let generic_name: String?
    let image_url: String?
    let image_front_url: String?
    let image_nutrition_url: String?
    let image_ingredients_url: String?
}

// UPCItemDB
struct UPCItemDBResponse: Codable {
    let code: String?
    let total: Int?
    let items: [UPCItemDBItem]?
}

struct UPCItemDBItem: Codable {
    let ean: String?
    let title: String?
    let description: String?
    let brand: String?
    let category: String?
    let images: [String]?
}

// Datakick
struct DatakickItem: Codable {
    let gtin14: String?
    let name: String?
    let brand_name: String?
    let description: String?
    let images: [DatakickImage]?
}

struct DatakickImage: Codable {
    let url: String?
}

// MARK: - Rate Limit Tracking
actor RateLimitTracker {
    static let shared = RateLimitTracker()
    
    private var dailyUsage: [String: (date: Date, count: Int)] = [:]
    
    func canMakeRequest(for provider: String, dailyLimit: Int) async -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let usage = dailyUsage[provider] {
            if Calendar.current.isDate(usage.date, inSameDayAs: today) {
                return usage.count < dailyLimit
            }
        }
        
        return true
    }
    
    func recordRequest(for provider: String) async {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let usage = dailyUsage[provider],
           Calendar.current.isDate(usage.date, inSameDayAs: today) {
            dailyUsage[provider] = (today, usage.count + 1)
        } else {
            dailyUsage[provider] = (today, 1)
        }
    }
}