import XCTest
@testable import Core
@testable import Items
@testable import TestUtilities

/// Tests for date/time edge cases and boundary conditions
final class DateBoundaryTests: XCTestCase {
    
    var itemService: ItemService!
    var warrantyService: WarrantyService!
    var analyticsService: AnalyticsService!
    var database: TestDatabase!
    
    override func setUp() async throws {
        try await super.setUp()
        database = try await TestDatabase.shared
        itemService = ItemService(database: database)
        warrantyService = WarrantyService()
        analyticsService = AnalyticsService()
        
        // Clear database
        try await database.deleteAll()
    }
    
    override func tearDown() async throws {
        try await database.deleteAll()
        try await super.tearDown()
    }
    
    // MARK: - Date Boundary Tests
    
    func testExtremeDataValues() async throws {
        let extremeDates = [
            // Far past
            Date(timeIntervalSince1970: 0), // Unix epoch
            Date(timeIntervalSince1970: -86400 * 365 * 50), // 50 years before epoch
            
            // Far future
            Date(timeIntervalSince1970: 86400 * 365 * 50), // 50 years after epoch
            Date(timeIntervalSince1970: TimeInterval(Int32.max)), // Max 32-bit timestamp
            
            // Special values
            Date.distantPast,
            Date.distantFuture,
            
            // Boundary dates
            Date(timeIntervalSince1970: -1), // Just before epoch
            Date(timeIntervalSince1970: 1), // Just after epoch
        ]
        
        for date in extremeDates {
            let item = TestDataBuilder.createItem(
                name: "Item created at \(date)",
                purchaseDate: date,
                createdAt: date
            )
            
            do {
                let created = try await itemService.create(item)
                let fetched = try await itemService.getItem(id: created.id)!
                
                // Dates should be preserved or clamped to reasonable range
                if date == Date.distantPast {
                    XCTAssertEqual(fetched.purchaseDate, Date(timeIntervalSince1970: 0))
                } else if date == Date.distantFuture {
                    // Should be clamped to reasonable future (e.g., 100 years)
                    let maxFuture = Date().addingTimeInterval(100 * 365 * 86400)
                    XCTAssertLessThanOrEqual(fetched.purchaseDate!, maxFuture)
                } else {
                    XCTAssertEqual(fetched.purchaseDate?.timeIntervalSince1970,
                                 date.timeIntervalSince1970,
                                 accuracy: 1.0)
                }
            } catch {
                // Some extreme dates might be rejected
                XCTAssertTrue(error is ValidationError)
            }
        }
    }
    
    func testTimeZoneTransitions() async throws {
        // Test daylight saving time transitions
        let timeZones = [
            TimeZone(identifier: "America/New_York")!,
            TimeZone(identifier: "Europe/London")!,
            TimeZone(identifier: "Asia/Tokyo")!, // No DST
            TimeZone(identifier: "Australia/Sydney")!
        ]
        
        for timeZone in timeZones {
            // Find DST transition dates
            let calendar = Calendar(identifier: .gregorian)
            var dateComponents = calendar.dateComponents([.year], from: Date())
            dateComponents.year = 2024
            
            // Spring forward (around March for Northern Hemisphere)
            dateComponents.month = 3
            dateComponents.day = 10
            dateComponents.hour = 2
            dateComponents.minute = 30
            dateComponents.timeZone = timeZone
            
            if let springForward = calendar.date(from: dateComponents) {
                let item = TestDataBuilder.createItem(
                    name: "DST Spring Forward Item",
                    purchaseDate: springForward
                )
                
                let created = try await itemService.create(item)
                let fetched = try await itemService.getItem(id: created.id)!
                
                // Verify date handling during DST transition
                XCTAssertNotNil(fetched.purchaseDate)
            }
            
            // Fall back (around November for Northern Hemisphere)
            dateComponents.month = 11
            dateComponents.day = 3
            dateComponents.hour = 1
            dateComponents.minute = 30
            
            if let fallBack = calendar.date(from: dateComponents) {
                // Test ambiguous hour (occurs twice)
                let item1 = TestDataBuilder.createItem(
                    name: "DST Fall Back Item 1",
                    purchaseDate: fallBack
                )
                
                let item2 = TestDataBuilder.createItem(
                    name: "DST Fall Back Item 2",
                    purchaseDate: fallBack.addingTimeInterval(3600) // 1 hour later
                )
                
                let created1 = try await itemService.create(item1)
                let created2 = try await itemService.create(item2)
                
                // Both should be created successfully
                XCTAssertNotEqual(created1.id, created2.id)
            }
        }
    }
    
    func testLeapYearAndLeapSeconds() async throws {
        let calendar = Calendar(identifier: .gregorian)
        
        // Leap year tests
        let leapYearDates = [
            // Feb 29 in leap years
            createDate(year: 2020, month: 2, day: 29),
            createDate(year: 2024, month: 2, day: 29),
            
            // Century leap year
            createDate(year: 2000, month: 2, day: 29),
            
            // Day before and after leap day
            createDate(year: 2020, month: 2, day: 28),
            createDate(year: 2020, month: 3, day: 1)
        ]
        
        for date in leapYearDates.compactMap({ $0 }) {
            let item = TestDataBuilder.createItem(
                name: "Leap Year Item",
                purchaseDate: date
            )
            
            let created = try await itemService.create(item)
            
            // Test warranty expiration across leap years
            let warranty = try await warrantyService.create(
                for: created,
                startDate: date,
                duration: .years(1)
            )
            
            let expirationDate = warranty.expirationDate
            
            // Verify correct handling of leap years
            let components = calendar.dateComponents([.year, .month, .day], 
                                                   from: date, 
                                                   to: expirationDate)
            XCTAssertEqual(components.year, 1)
        }
        
        // Test invalid leap day in non-leap year
        if let invalidDate = createDate(year: 2021, month: 2, day: 29) {
            // This should be adjusted to Feb 28 or March 1
            let item = TestDataBuilder.createItem(
                name: "Invalid Leap Day",
                purchaseDate: invalidDate
            )
            
            let created = try await itemService.create(item)
            let components = calendar.dateComponents([.month, .day], 
                                                   from: created.purchaseDate!)
            XCTAssertTrue(components.month == 2 && components.day == 28 ||
                         components.month == 3 && components.day == 1)
        }
    }
    
    // MARK: - Time Calculation Tests
    
    func testDurationCalculations() async throws {
        let testCases: [(start: Date, end: Date, expectedDays: Int)] = [
            // Simple case
            (Date(), Date().addingTimeInterval(86400), 1),
            
            // Across DST transition
            (createDate(year: 2024, month: 3, day: 9)!,
             createDate(year: 2024, month: 3, day: 11)!, 2),
            
            // Across year boundary
            (createDate(year: 2023, month: 12, day: 31)!,
             createDate(year: 2024, month: 1, day: 1)!, 1),
            
            // Negative duration
            (Date(), Date().addingTimeInterval(-86400), -1),
            
            // Same date
            (Date(), Date(), 0)
        ]
        
        for (start, end, expectedDays) in testCases {
            let duration = warrantyService.calculateDuration(from: start, to: end)
            XCTAssertEqual(duration.days, expectedDays, accuracy: 1)
        }
    }
    
    func testRecurringEventScheduling() async throws {
        let startDate = createDate(year: 2024, month: 1, day: 31)! // Jan 31
        
        // Test monthly recurrence with different strategies
        let recurrenceStrategies = [
            RecurrenceStrategy.sameDay, // Jan 31, Feb 28/29, Mar 31...
            RecurrenceStrategy.endOfMonth, // Last day of each month
            RecurrenceStrategy.closestValid // Jan 31, Feb 28, Mar 31...
        ]
        
        for strategy in recurrenceStrategies {
            let occurrences = warrantyService.calculateRecurringDates(
                from: startDate,
                recurrence: .monthly,
                count: 12,
                strategy: strategy
            )
            
            XCTAssertEqual(occurrences.count, 12)
            
            // Verify February handling
            let febDate = occurrences[1]
            let febComponents = Calendar.current.dateComponents([.month, .day], from: febDate)
            
            switch strategy {
            case .sameDay, .closestValid:
                // Should be Feb 28 or 29 depending on leap year
                XCTAssertEqual(febComponents.month, 2)
                XCTAssertTrue(febComponents.day == 28 || febComponents.day == 29)
                
            case .endOfMonth:
                // Should be last day of February
                XCTAssertEqual(febComponents.month, 2)
                let lastDay = Calendar.current.range(of: .day, in: .month, for: febDate)!.upperBound - 1
                XCTAssertEqual(febComponents.day, lastDay)
            }
        }
    }
    
    // MARK: - Analytics Date Range Tests
    
    func testAnalyticsDateRanges() async throws {
        // Create items across various dates
        let dates = [
            createDate(year: 2023, month: 1, day: 1)!,
            createDate(year: 2023, month: 6, day: 15)!,
            createDate(year: 2023, month: 12, day: 31)!,
            createDate(year: 2024, month: 1, day: 1)!,
            createDate(year: 2024, month: 2, day: 29)!, // Leap day
            createDate(year: 2024, month: 12, day: 31)!
        ]
        
        for (index, date) in dates.enumerated() {
            let item = TestDataBuilder.createItem(
                name: "Analytics Item \(index)",
                value: Double(index * 100),
                purchaseDate: date
            )
            try await itemService.create(item)
        }
        
        // Test various date range queries
        let rangeTests = [
            // Full year
            (start: createDate(year: 2023, month: 1, day: 1)!,
             end: createDate(year: 2023, month: 12, day: 31)!,
             expectedCount: 3),
            
            // Across year boundary
            (start: createDate(year: 2023, month: 12, day: 1)!,
             end: createDate(year: 2024, month: 1, day: 31)!,
             expectedCount: 2),
            
            // Single day
            (start: createDate(year: 2024, month: 2, day: 29)!,
             end: createDate(year: 2024, month: 2, day: 29)!,
             expectedCount: 1),
            
            // Invalid range (end before start)
            (start: createDate(year: 2024, month: 1, day: 1)!,
             end: createDate(year: 2023, month: 1, day: 1)!,
             expectedCount: 0)
        ]
        
        for (start, end, expectedCount) in rangeTests {
            let items = try await analyticsService.getItemsInDateRange(
                from: start,
                to: end
            )
            
            XCTAssertEqual(items.count, expectedCount)
        }
    }
    
    // MARK: - Relative Date Tests
    
    func testRelativeDateCalculations() async throws {
        let now = Date()
        
        let relativeDates = [
            ("yesterday", -1),
            ("last week", -7),
            ("last month", -30),
            ("last year", -365),
            ("tomorrow", 1),
            ("next week", 7),
            ("next month", 30),
            ("next year", 365)
        ]
        
        for (description, dayOffset) in relativeDates {
            let targetDate = now.addingTimeInterval(TimeInterval(dayOffset * 86400))
            
            let item = TestDataBuilder.createItem(
                name: "Item from \(description)",
                purchaseDate: targetDate
            )
            
            let created = try await itemService.create(item)
            
            // Test relative date search
            let results = try await searchService.search(
                query: "purchased:\(description)"
            )
            
            XCTAssertTrue(results.contains { $0.id == created.id })
        }
    }
    
    // MARK: - Time Precision Tests
    
    func testMicrosecondPrecision() async throws {
        var items: [Item] = []
        
        // Create items with microsecond differences
        for i in 0..<10 {
            let date = Date().addingTimeInterval(TimeInterval(i) * 0.000001) // 1 microsecond
            let item = TestDataBuilder.createItem(
                name: "Precision Item \(i)",
                createdAt: date
            )
            items.append(try await itemService.create(item))
        }
        
        // Verify order is preserved
        let fetched = try await itemService.getAllItems(sortBy: .createdDate, ascending: true)
        
        for i in 0..<items.count-1 {
            let item1 = fetched.first { $0.name == "Precision Item \(i)" }!
            let item2 = fetched.first { $0.name == "Precision Item \(i+1)" }!
            
            XCTAssertLessThan(item1.createdAt, item2.createdAt)
        }
    }
    
    // MARK: - Calendar System Tests
    
    func testNonGregorianCalendars() async throws {
        let calendars = [
            Calendar(identifier: .islamic),
            Calendar(identifier: .hebrew),
            Calendar(identifier: .chinese),
            Calendar(identifier: .japanese)
        ]
        
        for calendar in calendars {
            // Create date in specific calendar
            var components = DateComponents()
            components.year = 1445 // Islamic year
            components.month = 1
            components.day = 1
            
            if let date = calendar.date(from: components) {
                let item = TestDataBuilder.createItem(
                    name: "Item in \(calendar.identifier)",
                    purchaseDate: date
                )
                
                let created = try await itemService.create(item)
                
                // Verify date is stored correctly (converted to Gregorian)
                XCTAssertNotNil(created.purchaseDate)
                
                // Convert back to original calendar
                let retrievedComponents = calendar.dateComponents(
                    [.year, .month, .day],
                    from: created.purchaseDate!
                )
                
                // Should maintain the same date in the original calendar
                XCTAssertEqual(retrievedComponents.year, components.year)
                XCTAssertEqual(retrievedComponents.month, components.month)
                XCTAssertEqual(retrievedComponents.day, components.day)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createDate(year: Int, month: Int, day: Int, 
                           hour: Int = 12, minute: Int = 0, second: Int = 0) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        components.timeZone = TimeZone.current
        
        return Calendar.current.date(from: components)
    }
}

// MARK: - Supporting Types

enum RecurrenceStrategy {
    case sameDay
    case endOfMonth
    case closestValid
}

extension WarrantyService {
    func calculateDuration(from start: Date, to end: Date) -> (days: Int, hours: Int) {
        let components = Calendar.current.dateComponents(
            [.day, .hour],
            from: start,
            to: end
        )
        return (components.day ?? 0, components.hour ?? 0)
    }
    
    func calculateRecurringDates(from start: Date, 
                               recurrence: RecurrenceType,
                               count: Int,
                               strategy: RecurrenceStrategy) -> [Date] {
        var dates: [Date] = []
        var currentDate = start
        
        for _ in 0..<count {
            dates.append(currentDate)
            
            switch recurrence {
            case .monthly:
                currentDate = nextMonthlyOccurrence(from: currentDate, strategy: strategy)
            case .yearly:
                currentDate = Calendar.current.date(byAdding: .year, value: 1, to: currentDate)!
            default:
                currentDate = Calendar.current.date(byAdding: .day, value: 30, to: currentDate)!
            }
        }
        
        return dates
    }
    
    private func nextMonthlyOccurrence(from date: Date, strategy: RecurrenceStrategy) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        
        // Move to next month
        components.month! += 1
        
        switch strategy {
        case .sameDay:
            // Try to keep same day, adjust if invalid
            if let nextDate = calendar.date(from: components) {
                return nextDate
            } else {
                // Invalid date (e.g., Feb 31), use last valid day
                components.day = 1
                components.month! += 1
                let firstOfNextMonth = calendar.date(from: components)!
                return calendar.date(byAdding: .day, value: -1, to: firstOfNextMonth)!
            }
            
        case .endOfMonth:
            // Always use last day of month
            components.day = 1
            components.month! += 1
            let firstOfNextMonth = calendar.date(from: components)!
            return calendar.date(byAdding: .day, value: -1, to: firstOfNextMonth)!
            
        case .closestValid:
            // Use same day if valid, otherwise closest valid day
            let originalDay = components.day!
            
            if let nextDate = calendar.date(from: components) {
                return nextDate
            } else {
                // Find last valid day of month
                components.day = 1
                components.month! += 1
                let firstOfNextMonth = calendar.date(from: components)!
                let lastDay = calendar.date(byAdding: .day, value: -1, to: firstOfNextMonth)!
                
                components = calendar.dateComponents([.year, .month, .day], from: lastDay)
                components.day = min(originalDay, components.day!)
                
                return calendar.date(from: components)!
            }
        }
    }
}

enum RecurrenceType {
    case daily
    case weekly
    case monthly
    case yearly
}