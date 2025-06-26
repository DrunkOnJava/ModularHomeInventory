import XCTest
import SnapshotTesting
import SwiftUI
@testable import SharedUI

final class PrimaryButtonSnapshotTests: SnapshotTestCase {
    
    func testPrimaryButton_Default() {
        let button = PrimaryButton(title: "Save Changes") {
            // Action
        }
        .frame(width: 300)
        .padding()
        
        assertSnapshot(matching: button, as: .image)
    }
    
    func testPrimaryButton_Loading() {
        let button = PrimaryButton(title: "Save Changes", isLoading: true) {
            // Action
        }
        .frame(width: 300)
        .padding()
        
        assertSnapshot(matching: button, as: .image)
    }
    
    func testPrimaryButton_Disabled() {
        let button = PrimaryButton(title: "Save Changes") {
            // Action
        }
        .disabled(true)
        .frame(width: 300)
        .padding()
        
        assertSnapshot(matching: button, as: .image)
    }
    
    func testPrimaryButton_BothModes() {
        let button = PrimaryButton(title: "Save Changes") {
            // Action
        }
        .frame(width: 300)
        .padding()
        
        assertSnapshotInBothModes(matching: button)
    }
    
    func testPrimaryButton_LongText() {
        let button = PrimaryButton(title: "This is a very long button title that should wrap") {
            // Action
        }
        .frame(width: 300)
        .padding()
        
        assertSnapshot(matching: button, as: .image)
    }
    
    func testPrimaryButton_Accessibility() {
        let button = PrimaryButton(title: "Save") {
            // Action
        }
        .frame(width: 300)
        .padding()
        
        // Test with larger text sizes
        assertSnapshot(
            matching: button,
            as: .image(traits: .init(preferredContentSizeCategory: .accessibilityLarge))
        )
        
        assertSnapshot(
            matching: button,
            as: .image(traits: .init(preferredContentSizeCategory: .accessibilityExtraExtraLarge))
        )
    }
}