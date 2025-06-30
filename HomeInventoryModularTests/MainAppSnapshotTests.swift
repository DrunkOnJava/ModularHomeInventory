//
//  MainAppSnapshotTests.swift
//  HomeInventoryModularTests
//
//  Snapshot tests for main app screens and tab views
//

import XCTest
import SnapshotTesting
import SwiftUI
@testable import Items
@testable import BarcodeScanner
@testable import Receipts
@testable import AppSettings
@testable import Core
@testable import SharedUI

final class MainAppSnapshotTests: XCTestCase {
    
    // MARK: - Mock Data
    
    private var mockAppState: AppState {
        AppState(
            isAuthenticated: true,
            selectedTab: .items,
            hasCompletedOnboarding: true,
            isPremium: false,
            unreadNotifications: 3,
            pendingSyncCount: 0
        )
    }
    
    // MARK: - Tests
    
    func testMainTabView_ItemsTab() {
        withSnapshotTesting(record: .all) {
            let view = MainTabView(
                appState: mockAppState,
                selectedTab: .constant(.items)
            )
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testMainTabView_ScanTab() {
        withSnapshotTesting(record: .all) {
            let view = MainTabView(
                appState: mockAppState,
                selectedTab: .constant(.scan)
            )
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testMainTabView_ReceiptsTab() {
        withSnapshotTesting(record: .all) {
            let view = MainTabView(
                appState: mockAppState,
                selectedTab: .constant(.receipts)
            )
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testMainTabView_SettingsTab() {
        withSnapshotTesting(record: .all) {
            let view = MainTabView(
                appState: mockAppState,
                selectedTab: .constant(.settings)
            )
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testMainTabView_WithBadges() {
        withSnapshotTesting(record: .all) {
            var state = mockAppState
            state.unreadNotifications = 5
            state.pendingSyncCount = 12
            
            let view = MainTabView(
                appState: state,
                selectedTab: .constant(.items)
            )
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testContentView_Authenticated() {
        withSnapshotTesting(record: .all) {
            let view = ContentView()
                .environmentObject(mockAppState)
                .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testContentView_NotAuthenticated() {
        withSnapshotTesting(record: .all) {
            var state = mockAppState
            state.isAuthenticated = false
            
            let view = ContentView()
                .environmentObject(state)
                .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testContentView_FirstLaunch() {
        withSnapshotTesting(record: .all) {
            var state = mockAppState
            state.hasCompletedOnboarding = false
            state.isAuthenticated = false
            
            let view = ContentView()
                .environmentObject(state)
                .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testMainTabView_iPad() {
        withSnapshotTesting(record: .all) {
            let view = MainTabView(
                appState: mockAppState,
                selectedTab: .constant(.items)
            )
            .frame(width: 1024, height: 1366)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPadPro12_9))
        }
    }
    
    func testMainTabView_iPadSplitView() {
        withSnapshotTesting(record: .all) {
            let view = MainTabView(
                appState: mockAppState,
                selectedTab: .constant(.items),
                showingSidebar: true
            )
            .frame(width: 1366, height: 1024) // Landscape
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(size: CGSize(width: 1366, height: 1024)))
        }
    }
    
    func testMainTabView_DarkMode() {
        withSnapshotTesting(record: .all) {
            let view = MainTabView(
                appState: mockAppState,
                selectedTab: .constant(.items)
            )
            .frame(width: 390, height: 844)
            .preferredColorScheme(.dark)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testMainTabView_CompactTab() {
        withSnapshotTesting(record: .all) {
            let view = MainTabView(
                appState: mockAppState,
                selectedTab: .constant(.items)
            )
            .frame(width: 320, height: 568) // iPhone SE
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhoneSe))
        }
    }
    
    func testMainTabView_Accessibility() {
        withSnapshotTesting(record: .all) {
            let view = MainTabView(
                appState: mockAppState,
                selectedTab: .constant(.items)
            )
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(
                of: hostingController,
                as: .image(on: .iPhone13Pro, traits: .init(preferredContentSizeCategory: .accessibilityLarge))
            )
        }
    }
}