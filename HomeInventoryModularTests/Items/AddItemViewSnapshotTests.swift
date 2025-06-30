//
//  AddItemViewSnapshotTests.swift
//  HomeInventoryModularTests
//
//  Snapshot tests for AddItemView component
//

import XCTest
import SnapshotTesting
import SwiftUI
@testable import Items
@testable import Core
@testable import SharedUI

final class AddItemViewSnapshotTests: XCTestCase {
    
    // MARK: - Tests
    
    func testAddItemView_Empty() {
        withSnapshotTesting(record: .all) {
            let view = NavigationView {
                AddItemView(isPresented: .constant(true))
            }
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testAddItemView_PartiallyFilled() {
        withSnapshotTesting(record: .all) {
            let view = NavigationView {
                AddItemView(
                    isPresented: .constant(true),
                    prefilledData: AddItemView.PrefilledData(
                        name: "iPhone 15 Pro",
                        brand: "Apple",
                        category: .electronics,
                        barcode: "194253945741"
                    )
                )
            }
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testAddItemView_WithTemplate() {
        withSnapshotTesting(record: .all) {
            let view = NavigationView {
                AddItemView(
                    isPresented: .constant(true),
                    selectedTemplate: ItemTemplate(
                        id: UUID(),
                        name: "Laptop",
                        category: .electronics,
                        suggestedFields: ["RAM", "Storage", "Processor"],
                        defaultTags: ["electronics", "computer"],
                        icon: "laptopcomputer"
                    )
                )
            }
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testAddItemView_CategorySelected() {
        withSnapshotTesting(record: .all) {
            let view = NavigationView {
                AddItemView(
                    isPresented: .constant(true),
                    prefilledData: AddItemView.PrefilledData(
                        category: .appliances
                    )
                )
            }
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testAddItemView_ScrolledDown() {
        withSnapshotTesting(record: .all) {
            let view = NavigationView {
                AddItemView(
                    isPresented: .constant(true),
                    prefilledData: AddItemView.PrefilledData(
                        name: "Test Item",
                        brand: "Test Brand",
                        model: "Model X",
                        serialNumber: "SN123456",
                        purchasePrice: 999.99,
                        notes: "This is a test item with all fields filled"
                    )
                )
            }
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testAddItemView_iPad() {
        withSnapshotTesting(record: .all) {
            let view = NavigationView {
                AddItemView(isPresented: .constant(true))
            }
            .frame(width: 1024, height: 1366)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPadPro12_9))
        }
    }
    
    func testAddItemView_DarkMode() {
        withSnapshotTesting(record: .all) {
            let view = NavigationView {
                AddItemView(isPresented: .constant(true))
            }
            .frame(width: 390, height: 844)
            .preferredColorScheme(.dark)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testAddItemView_ValidationErrors() {
        withSnapshotTesting(record: .all) {
            // This would show validation errors when saving without required fields
            let view = NavigationView {
                AddItemView(
                    isPresented: .constant(true),
                    showValidationErrors: true
                )
            }
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
}