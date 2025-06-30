//
//  WorkingSnapshotTests.swift
//  HomeInventoryModularTests
//
//  Simple working snapshot tests
//

import XCTest
import SnapshotTesting
import SwiftUI
@testable import SharedUI

final class WorkingSnapshotTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Enable recording mode to generate snapshots
        isRecording = false
    }
    
    func testSearchBar() {
        let searchBar = SearchBar(text: .constant(""), placeholder: "Search items...")
        let hostingController = UIHostingController(rootView: searchBar)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 375, height: 60)
        
        assertSnapshot(matching: hostingController, as: .image)
    }
    
    func testSearchBarWithText() {
        let searchBar = SearchBar(text: .constant("MacBook Pro"), placeholder: "Search items...")
        let hostingController = UIHostingController(rootView: searchBar)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 375, height: 60)
        
        assertSnapshot(matching: hostingController, as: .image)
    }
    
    func testPrimaryButton() {
        let button = PrimaryButton(title: "Add Item", action: {})
        let hostingController = UIHostingController(rootView: button)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 200, height: 50)
        
        assertSnapshot(matching: hostingController, as: .image)
    }
    
    func testPrimaryButtonLoading() {
        let button = PrimaryButton(title: "Saving...", isLoading: true, action: {})
        let hostingController = UIHostingController(rootView: button)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 200, height: 50)
        
        assertSnapshot(matching: hostingController, as: .image)
    }
    
    func testLoadingOverlay() {
        let overlay = LoadingOverlay(isLoading: .constant(true), message: "Processing...")
        let hostingController = UIHostingController(rootView: overlay)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        
        assertSnapshot(matching: hostingController, as: .image)
    }
}