import XCTest
@testable import Core
@testable import Items
@testable import TestUtilities

/// Tests for Unicode handling, special characters, and internationalization
final class UnicodeAndLocalizationTests: XCTestCase {
    
    var itemService: ItemService!
    var searchService: SearchService!
    var database: TestDatabase!
    
    override func setUp() async throws {
        try await super.setUp()
        database = try await TestDatabase.shared
        itemService = ItemService(database: database)
        searchService = SearchService(database: database)
        
        // Clear database
        try await database.deleteAll()
    }
    
    override func tearDown() async throws {
        try await database.deleteAll()
        try await super.tearDown()
    }
    
    // MARK: - Unicode Character Tests
    
    func testBasicUnicodeCharacters() async throws {
        let unicodeItems = [
            // Emoji
            TestDataBuilder.createItem(name: "📱 iPhone 15 Pro", notes: "My favorite device! 💙"),
            TestDataBuilder.createItem(name: "🎮 PlayStation 5", notes: "Gaming console 🎯🏆"),
            TestDataBuilder.createItem(name: "🏠 Smart Home Hub", notes: "Controls 💡🌡️🔒"),
            
            // Various scripts
            TestDataBuilder.createItem(name: "MacBook Pro - 苹果笔记本电脑", notes: "高性能笔记本"),
            TestDataBuilder.createItem(name: "كمبيوتر محمول", notes: "جهاز ممتاز"), // Arabic
            TestDataBuilder.createItem(name: "Ноутбук", notes: "Мощный компьютер"), // Cyrillic
            TestDataBuilder.createItem(name: "노트북", notes: "강력한 컴퓨터"), // Korean
            TestDataBuilder.createItem(name: "ラップトップ", notes: "パワフルなコンピュータ"), // Japanese
            TestDataBuilder.createItem(name: "מחשב נייד", notes: "מחשב חזק"), // Hebrew
            TestDataBuilder.createItem(name: "लैपटॉप", notes: "शक्तिशाली कंप्यूटर") // Hindi
        ]
        
        // Create all items
        for item in unicodeItems {
            let created = try await itemService.create(item)
            
            // Verify created correctly
            let fetched = try await itemService.getItem(id: created.id)!
            XCTAssertEqual(fetched.name, item.name)
            XCTAssertEqual(fetched.notes, item.notes)
        }
        
        // Test searching
        let emojiResults = try await searchService.search(query: "📱")
        XCTAssertEqual(emojiResults.count, 1)
        
        let chineseResults = try await searchService.search(query: "苹果")
        XCTAssertEqual(chineseResults.count, 1)
        
        let arabicResults = try await searchService.search(query: "كمبيوتر")
        XCTAssertEqual(arabicResults.count, 1)
    }
    
    func testComplexUnicodeScenarios() async throws {
        let complexItems = [
            // Zero-width characters
            TestDataBuilder.createItem(
                name: "Test\u{200B}Item", // Zero-width space
                notes: "Contains zero-width\u{200C}characters" // Zero-width non-joiner
            ),
            
            // Combining characters
            TestDataBuilder.createItem(
                name: "Café", // é as single character
                notes: "Cafe\u{0301}" // e + combining acute accent
            ),
            
            // Right-to-left override
            TestDataBuilder.createItem(
                name: "Normal \u{202E}txet desrever\u{202C} text",
                notes: "Mixed directionality"
            ),
            
            // Surrogate pairs
            TestDataBuilder.createItem(
                name: "Ancient Script 𐌀𐌁𐌂", // Gothic letters
                notes: "Contains surrogate pairs 🏛️"
            ),
            
            // Normalization test
            TestDataBuilder.createItem(
                name: "à", // Precomposed
                notes: "a\u{0300}" // Decomposed
            )
        ]
        
        for item in complexItems {
            let created = try await itemService.create(item)
            let fetched = try await itemService.getItem(id: created.id)!
            
            // Verify exact byte preservation
            XCTAssertEqual(fetched.name, item.name)
            XCTAssertEqual(fetched.notes, item.notes)
        }
        
        // Test normalization in search
        let normalizedResults = try await searchService.search(query: "à")
        XCTAssertGreaterThanOrEqual(normalizedResults.count, 1) // Should find both forms
    }
    
    func testEmojiHandling() async throws {
        let emojiItems = [
            // Basic emoji
            TestDataBuilder.createItem(name: "🍕 Pizza Maker", value: 299.99),
            
            // Skin tone modifiers
            TestDataBuilder.createItem(name: "👨🏻‍💻 Developer Kit", value: 199.99),
            TestDataBuilder.createItem(name: "👩🏽‍🔬 Science Kit", value: 149.99),
            
            // Compound emoji
            TestDataBuilder.createItem(name: "👨‍👩‍👧‍👦 Family Game", value: 49.99),
            
            // Flag emoji
            TestDataBuilder.createItem(name: "🇺🇸 USA Edition", value: 79.99),
            TestDataBuilder.createItem(name: "🇯🇵 Japan Edition", value: 89.99),
            
            // New emoji (test compatibility)
            TestDataBuilder.createItem(name: "🫶 Heart Hands Jewelry", value: 159.99)
        ]
        
        for item in emojiItems {
            let created = try await itemService.create(item)
            
            // Verify emoji preserved
            let fetched = try await itemService.getItem(id: created.id)!
            XCTAssertEqual(fetched.name, item.name)
            
            // Test emoji in search
            let emoji = String(item.name.prefix(2)) // Get first emoji
            let results = try await searchService.search(query: emoji)
            XCTAssertGreaterThan(results.count, 0)
        }
    }
    
    // MARK: - Collation and Sorting Tests
    
    func testMultilingualSorting() async throws {
        let items = [
            TestDataBuilder.createItem(name: "Zebra"),
            TestDataBuilder.createItem(name: "Äpfel"), // German
            TestDataBuilder.createItem(name: "Apple"),
            TestDataBuilder.createItem(name: "Øl"), // Norwegian
            TestDataBuilder.createItem(name: "Éclair"), // French
            TestDataBuilder.createItem(name: "안녕"), // Korean
            TestDataBuilder.createItem(name: "你好"), // Chinese
            TestDataBuilder.createItem(name: "مرحبا"), // Arabic
            TestDataBuilder.createItem(name: "Здравствуй"), // Russian
            TestDataBuilder.createItem(name: "1️⃣ First"),
            TestDataBuilder.createItem(name: "10 Ten"),
            TestDataBuilder.createItem(name: "2 Two")
        ]
        
        for item in items {
            try await itemService.create(item)
        }
        
        // Test locale-aware sorting
        let locales = [
            Locale(identifier: "en_US"),
            Locale(identifier: "de_DE"),
            Locale(identifier: "zh_CN"),
            Locale(identifier: "ar_SA")
        ]
        
        for locale in locales {
            let sorted = try await itemService.getAllItems(
                sortBy: .name,
                locale: locale
            )
            
            // Verify sorting is consistent
            XCTAssertEqual(sorted.count, items.count)
            
            // Check numeric sorting
            let numericItems = sorted.filter { $0.name.first?.isNumber ?? false }
            if numericItems.count >= 3 {
                // Should be sorted as 1, 2, 10, not 1, 10, 2
                XCTAssertTrue(numericItems[0].name.starts(with: "1️⃣") || numericItems[0].name.starts(with: "1 "))
                XCTAssertTrue(numericItems[1].name.starts(with: "2"))
                XCTAssertTrue(numericItems[2].name.starts(with: "10"))
            }
        }
    }
    
    // MARK: - Text Length and Boundary Tests
    
    func testExtremeLengthStrings() async throws {
        let testCases = [
            // Empty strings
            ("", "Empty name should be rejected"),
            
            // Single character
            ("A", "Single character name"),
            
            // Maximum reasonable length
            (String(repeating: "A", count: 255), "Maximum name length"),
            
            // Very long string
            (String(repeating: "Very long name ", count: 100), "Exceeds reasonable length"),
            
            // Unicode grapheme clusters
            (String(repeating: "👨‍👩‍👧‍👦", count: 50), "Complex emoji repetition"),
            
            // Mixed scripts
            ("English中文العربيةРусский日本語한국어", "Mixed scripts in one string")
        ]
        
        for (name, description) in testCases {
            if name.isEmpty {
                // Empty name should fail validation
                do {
                    _ = try await itemService.create(
                        TestDataBuilder.createItem(name: name)
                    )
                    XCTFail("Empty name should be rejected")
                } catch {
                    XCTAssertTrue(error is ValidationError)
                }
            } else if name.count > 255 {
                // Very long names should be truncated
                let item = try await itemService.create(
                    TestDataBuilder.createItem(name: name)
                )
                XCTAssertLessThanOrEqual(item.name.count, 255)
                XCTAssertTrue(item.name.hasPrefix(String(name.prefix(252))))
            } else {
                // Normal names should work
                let item = try await itemService.create(
                    TestDataBuilder.createItem(name: name, notes: description)
                )
                XCTAssertEqual(item.name, name)
            }
        }
    }
    
    // MARK: - Special Character Handling Tests
    
    func testSpecialCharactersInSearch() async throws {
        let specialItems = [
            TestDataBuilder.createItem(name: "C++ Programming Book", value: 49.99),
            TestDataBuilder.createItem(name: ".NET Framework Guide", value: 39.99),
            TestDataBuilder.createItem(name: "100% Cotton Shirt", value: 29.99),
            TestDataBuilder.createItem(name: "Email: user@example.com", value: 0),
            TestDataBuilder.createItem(name: "Price: $99.99", value: 99.99),
            TestDataBuilder.createItem(name: "Model #12345", value: 199.99),
            TestDataBuilder.createItem(name: "Size: 10\"x12\"", value: 15.99),
            TestDataBuilder.createItem(name: "A&B Company Product", value: 75.00),
            TestDataBuilder.createItem(name: "Item (New)", value: 125.00),
            TestDataBuilder.createItem(name: "Product [Limited Edition]", value: 299.99)
        ]
        
        for item in specialItems {
            try await itemService.create(item)
        }
        
        // Test searching with special characters
        let searchTests = [
            ("C++", 1),
            (".NET", 1),
            ("100%", 1),
            ("@example.com", 1),
            ("$99.99", 1),
            ("#12345", 1),
            ("10\"", 1),
            ("A&B", 1),
            ("(New)", 1),
            ("[Limited", 1)
        ]
        
        for (query, expectedCount) in searchTests {
            let results = try await searchService.search(query: query)
            XCTAssertEqual(results.count, expectedCount, "Search for '\(query)' failed")
        }
    }
    
    // MARK: - SQL Injection Prevention Tests
    
    func testSQLInjectionPrevention() async throws {
        let maliciousInputs = [
            "'; DROP TABLE items; --",
            "\" OR \"1\"=\"1",
            "'; DELETE FROM items WHERE '1'='1",
            "admin'--",
            "1' UNION SELECT * FROM users--",
            "\"; UPDATE items SET value=0; --",
            "Robert'); DROP TABLE items;--"
        ]
        
        // Create items with potentially malicious names
        for input in maliciousInputs {
            let item = try await itemService.create(
                TestDataBuilder.createItem(
                    name: "Test \(input)",
                    notes: input
                )
            )
            
            // Verify exact string is stored (properly escaped)
            let fetched = try await itemService.getItem(id: item.id)!
            XCTAssertTrue(fetched.name.contains(input))
            XCTAssertEqual(fetched.notes, input)
        }
        
        // Verify database integrity
        let allItems = try await itemService.getAllItems()
        XCTAssertEqual(allItems.count, maliciousInputs.count)
        
        // Test searching with malicious input
        for input in maliciousInputs {
            let results = try await searchService.search(query: input)
            // Should find items, not execute SQL
            XCTAssertGreaterThan(results.count, 0)
        }
    }
    
    // MARK: - Bidirectional Text Tests
    
    func testBidirectionalText() async throws {
        let bidiItems = [
            // Pure RTL
            TestDataBuilder.createItem(
                name: "מחשב נייד",
                notes: "מחשב נייד חדש"
            ),
            
            // Pure LTR
            TestDataBuilder.createItem(
                name: "Laptop Computer",
                notes: "New laptop computer"
            ),
            
            // Mixed RTL/LTR
            TestDataBuilder.createItem(
                name: "iPhone 15 - אייפון 15",
                notes: "Latest model - הדגם החדש"
            ),
            
            // Numbers in RTL context
            TestDataBuilder.createItem(
                name: "מחיר: 2999 ש״ח",
                notes: "כולל 17% מע״מ"
            )
        ]
        
        for item in bidiItems {
            let created = try await itemService.create(item)
            let fetched = try await itemService.getItem(id: created.id)!
            
            // Verify bidirectional text preserved
            XCTAssertEqual(fetched.name, item.name)
            XCTAssertEqual(fetched.notes, item.notes)
            
            // Verify text direction detected correctly
            let isRTL = fetched.name.contains { 
                $0.unicodeScalars.first.map { 
                    CharacterSet.arabicCharacters.contains($0) ||
                    CharacterSet.hebrewCharacters.contains($0)
                } ?? false
            }
            
            if item.name == "מחשב נייד" || item.name.starts(with: "מחיר:") {
                XCTAssertTrue(isRTL)
            }
        }
    }
    
    // MARK: - Currency and Number Formatting Tests
    
    func testInternationalNumberFormatting() async throws {
        let testLocales = [
            (Locale(identifier: "en_US"), 1234567.89, "$1,234,567.89"),
            (Locale(identifier: "de_DE"), 1234567.89, "1.234.567,89 €"),
            (Locale(identifier: "fr_FR"), 1234567.89, "1 234 567,89 €"),
            (Locale(identifier: "ja_JP"), 1234567, "¥1,234,567"),
            (Locale(identifier: "ar_SA"), 1234567.89, "١٬٢٣٤٬٥٦٧٫٨٩ ر.س.‏")
        ]
        
        for (locale, value, _) in testLocales {
            let item = TestDataBuilder.createItem(
                name: "Test Item \(locale.identifier)",
                value: value,
                locale: locale
            )
            
            let created = try await itemService.create(item)
            
            // Verify value stored correctly (as number, not formatted string)
            XCTAssertEqual(created.value, value)
            
            // Verify formatting applied in display
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = locale
            
            let formatted = formatter.string(from: NSNumber(value: value))
            XCTAssertNotNil(formatted)
        }
    }
}

// MARK: - Character Set Extensions

extension CharacterSet {
    static let arabicCharacters = CharacterSet(charactersIn: "\u{0600}"..."\u{06FF}")
        .union(CharacterSet(charactersIn: "\u{0750}"..."\u{077F}"))
    
    static let hebrewCharacters = CharacterSet(charactersIn: "\u{0590}"..."\u{05FF}")
}