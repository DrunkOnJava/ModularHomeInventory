import XCTest
@testable import Core

final class ItemTests: XCTestCase {
    
    func testItemCreation() {
        // Given
        let item = Item(
            name: "Test Item",
            brand: "Test Brand",
            category: .electronics,
            condition: .excellent
        )
        
        // Then
        XCTAssertEqual(item.name, "Test Item")
        XCTAssertEqual(item.brand, "Test Brand")
        XCTAssertEqual(item.category, .electronics)
        XCTAssertEqual(item.condition, .excellent)
        XCTAssertEqual(item.quantity, 1)
        XCTAssertNotNil(item.id)
    }
    
    func testItemEquality() {
        // Given
        let id = UUID()
        let date = Date()
        
        let item1 = Item(
            id: id,
            name: "Test",
            createdAt: date,
            updatedAt: date
        )
        
        let item2 = Item(
            id: id,
            name: "Test",
            createdAt: date,
            updatedAt: date
        )
        
        // Then
        XCTAssertEqual(item1, item2)
    }
}