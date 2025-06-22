import XCTest
import SwiftUI
@testable import SharedUI

final class ColorsTests: XCTestCase {
    
    func testHexColorInitialization() {
        // Given
        let hexColor = Color(hex: "#4A90E2")
        
        // Then
        XCTAssertNotNil(hexColor)
    }
    
    func testAppColorsExist() {
        // Then
        XCTAssertNotNil(AppColors.primary)
        XCTAssertNotNil(AppColors.success)
        XCTAssertNotNil(AppColors.warning)
        XCTAssertNotNil(AppColors.error)
        XCTAssertNotNil(AppColors.background)
        XCTAssertNotNil(AppColors.textPrimary)
    }
}