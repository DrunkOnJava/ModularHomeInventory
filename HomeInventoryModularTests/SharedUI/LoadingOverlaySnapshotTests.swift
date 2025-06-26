import XCTest
import SnapshotTesting
import SwiftUI
@testable import SharedUI

final class LoadingOverlaySnapshotTests: SnapshotTestCase {
    
    func testLoadingOverlay_Default() {
        let view = Color.gray.opacity(0.1)
            .frame(width: 300, height: 200)
            .overlay(
                LoadingOverlay(isLoading: .constant(true))
            )
        
        assertSnapshot(matching: view, as: .image)
    }
    
    func testLoadingOverlay_WithMessage() {
        let view = Color.gray.opacity(0.1)
            .frame(width: 300, height: 200)
            .overlay(
                LoadingOverlay(
                    isLoading: .constant(true),
                    message: "Scanning barcode..."
                )
            )
        
        assertSnapshot(matching: view, as: .image)
    }
    
    func testLoadingOverlay_Hidden() {
        let view = Color.gray.opacity(0.1)
            .frame(width: 300, height: 200)
            .overlay(
                LoadingOverlay(isLoading: .constant(false))
            )
        
        assertSnapshot(matching: view, as: .image)
    }
    
    func testLoadingOverlay_BothModes() {
        let view = Color.gray.opacity(0.1)
            .frame(width: 300, height: 200)
            .overlay(
                LoadingOverlay(
                    isLoading: .constant(true),
                    message: "Loading..."
                )
            )
        
        assertSnapshotInBothModes(matching: view)
    }
}