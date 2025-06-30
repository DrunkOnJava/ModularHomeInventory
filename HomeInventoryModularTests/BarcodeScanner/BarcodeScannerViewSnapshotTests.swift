//
//  BarcodeScannerViewSnapshotTests.swift
//  HomeInventoryModularTests
//
//  Snapshot tests for BarcodeScannerView component
//

import XCTest
import SnapshotTesting
import SwiftUI
@testable import BarcodeScanner
@testable import Core
@testable import SharedUI

final class BarcodeScannerViewSnapshotTests: XCTestCase {
    
    // MARK: - Mock Data
    
    private var mockScanHistory: [BarcodeScanResult] {
        [
            BarcodeScanResult(
                id: UUID(),
                barcode: "9780140449136",
                type: .ean13,
                productInfo: ProductInfo(
                    name: "The Odyssey",
                    brand: "Penguin Classics",
                    category: "Books",
                    description: "Homer's epic poem",
                    imageUrl: nil
                ),
                timestamp: Date().addingTimeInterval(-3600),
                isOffline: false
            ),
            BarcodeScanResult(
                id: UUID(),
                barcode: "194253082194",
                type: .ean13,
                productInfo: ProductInfo(
                    name: "MacBook Pro 16-inch",
                    brand: "Apple",
                    category: "Electronics",
                    description: "M2 Max, 32GB RAM, 1TB SSD",
                    imageUrl: nil
                ),
                timestamp: Date().addingTimeInterval(-7200),
                isOffline: false
            ),
            BarcodeScanResult(
                id: UUID(),
                barcode: "012345678905",
                type: .upca,
                productInfo: nil, // Product not found
                timestamp: Date().addingTimeInterval(-86400),
                isOffline: true
            )
        ]
    }
    
    // MARK: - Tests
    
    func testBarcodeScanner_Ready() {
        withSnapshotTesting(record: .all) {
            let view = BarcodeScannerView(
                onScanComplete: { _ in },
                showHistory: true
            )
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testBarcodeScanner_Scanning() {
        withSnapshotTesting(record: .all) {
            let view = BarcodeScannerView(
                onScanComplete: { _ in },
                isScanning: true,
                showHistory: true
            )
            .overlay(
                // Simulate scanning overlay
                VStack {
                    Spacer()
                    Text("Scanning...")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                        .padding(.bottom, 100)
                }
            )
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testBarcodeScanner_ProductFound() {
        withSnapshotTesting(record: .all) {
            let view = BarcodeScannerView(
                onScanComplete: { _ in },
                lastScanResult: mockScanHistory[1],
                showHistory: true
            )
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testBarcodeScanner_ProductNotFound() {
        withSnapshotTesting(record: .all) {
            let view = BarcodeScannerView(
                onScanComplete: { _ in },
                lastScanResult: mockScanHistory[2],
                showHistory: true
            )
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testBarcodeScanner_WithHistory() {
        withSnapshotTesting(record: .all) {
            let view = BarcodeScannerView(
                onScanComplete: { _ in },
                scanHistory: mockScanHistory,
                showHistory: true
            )
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testBarcodeScanner_BatchMode() {
        withSnapshotTesting(record: .all) {
            let view = BatchScannerView(
                onBatchComplete: { _ in },
                scannedItems: [
                    mockScanHistory[0],
                    mockScanHistory[1]
                ]
            )
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testBarcodeScanner_OfflineQueue() {
        withSnapshotTesting(record: .all) {
            let view = OfflineScanQueueView(
                offlineScans: mockScanHistory.filter { $0.isOffline }
            )
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testBarcodeScanner_iPad() {
        withSnapshotTesting(record: .all) {
            let view = BarcodeScannerView(
                onScanComplete: { _ in },
                showHistory: true
            )
            .frame(width: 1024, height: 1366)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPadPro12_9))
        }
    }
    
    func testBarcodeScanner_DarkMode() {
        withSnapshotTesting(record: .all) {
            let view = BarcodeScannerView(
                onScanComplete: { _ in },
                showHistory: true
            )
            .frame(width: 390, height: 844)
            .preferredColorScheme(.dark)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testBarcodeScanner_CameraPermissionDenied() {
        withSnapshotTesting(record: .all) {
            let view = BarcodeScannerView(
                onScanComplete: { _ in },
                cameraPermissionDenied: true
            )
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
}