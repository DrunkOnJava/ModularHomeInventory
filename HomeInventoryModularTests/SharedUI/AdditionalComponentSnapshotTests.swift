//
//  AdditionalComponentSnapshotTests.swift
//  HomeInventoryModularTests
//
//  Snapshot tests for additional SharedUI components
//

import XCTest
import SnapshotTesting
import SwiftUI
@testable import SharedUI
@testable import Core

final class AdditionalComponentSnapshotTests: XCTestCase {
    
    // MARK: - OfflineIndicator Tests
    
    func testOfflineIndicator_Default() {
        withSnapshotTesting(record: .all) {
            let view = OfflineIndicator()
                .frame(width: 390, height: 100)
                .padding()
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        }
    }
    
    func testOfflineIndicator_WithMessage() {
        withSnapshotTesting(record: .all) {
            let view = OfflineIndicator(message: "No internet connection. Your changes will sync when you're back online.")
                .frame(width: 390, height: 100)
                .padding()
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        }
    }
    
    func testOfflineIndicator_Syncing() {
        withSnapshotTesting(record: .all) {
            let view = OfflineIndicator(
                isOffline: false,
                isSyncing: true,
                message: "Syncing your data..."
            )
            .frame(width: 390, height: 100)
            .padding()
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        }
    }
    
    // MARK: - TagInputView Tests
    
    func testTagInputView_Empty() {
        withSnapshotTesting(record: .all) {
            let view = TagInputView(
                tags: .constant([]),
                placeholder: "Add tags..."
            )
            .frame(width: 350, height: 150)
            .padding()
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        }
    }
    
    func testTagInputView_WithTags() {
        withSnapshotTesting(record: .all) {
            let view = TagInputView(
                tags: .constant(["electronics", "apple", "laptop", "work", "2024"]),
                placeholder: "Add tags..."
            )
            .frame(width: 350, height: 150)
            .padding()
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        }
    }
    
    func testTagInputView_ManyTags() {
        withSnapshotTesting(record: .all) {
            let view = TagInputView(
                tags: .constant([
                    "electronics", "apple", "laptop", "work", "2024",
                    "macbook", "pro", "16-inch", "m2-max", "space-gray",
                    "development", "design", "portable", "premium"
                ]),
                placeholder: "Add tags..."
            )
            .frame(width: 350, height: 200)
            .padding()
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        }
    }
    
    func testTagInputView_WithSuggestions() {
        withSnapshotTesting(record: .all) {
            let view = TagInputView(
                tags: .constant(["electronics", "apple"]),
                placeholder: "Add tags...",
                suggestions: ["laptop", "desktop", "tablet", "phone", "watch", "accessories"]
            )
            .frame(width: 350, height: 250)
            .padding()
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        }
    }
    
    // MARK: - EnhancedSearchBar Tests
    
    func testEnhancedSearchBar_Default() {
        withSnapshotTesting(record: .all) {
            let view = EnhancedSearchBar(
                text: .constant(""),
                placeholder: "Search items..."
            )
            .frame(height: 60)
            .padding()
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        }
    }
    
    func testEnhancedSearchBar_WithText() {
        withSnapshotTesting(record: .all) {
            let view = EnhancedSearchBar(
                text: .constant("MacBook Pro"),
                placeholder: "Search items..."
            )
            .frame(height: 60)
            .padding()
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        }
    }
    
    func testEnhancedSearchBar_WithFilters() {
        withSnapshotTesting(record: .all) {
            let view = EnhancedSearchBar(
                text: .constant(""),
                placeholder: "Search items...",
                showFilters: true,
                activeFilterCount: 3
            )
            .frame(height: 60)
            .padding()
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        }
    }
    
    func testEnhancedSearchBar_WithVoice() {
        withSnapshotTesting(record: .all) {
            let view = EnhancedSearchBar(
                text: .constant(""),
                placeholder: "Search items...",
                showVoiceSearch: true
            )
            .frame(height: 60)
            .padding()
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        }
    }
    
    // MARK: - FeatureUnavailableView Tests
    
    func testFeatureUnavailableView_RequiresPremium() {
        withSnapshotTesting(record: .all) {
            let view = FeatureUnavailableView(
                feature: "Advanced Analytics",
                reason: .requiresPremium,
                upgradeAction: {}
            )
            .frame(width: 390, height: 600)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testFeatureUnavailableView_ComingSoon() {
        withSnapshotTesting(record: .all) {
            let view = FeatureUnavailableView(
                feature: "AI-Powered Insights",
                reason: .comingSoon
            )
            .frame(width: 390, height: 600)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testFeatureUnavailableView_RequiresSetup() {
        withSnapshotTesting(record: .all) {
            let view = FeatureUnavailableView(
                feature: "Family Sharing",
                reason: .requiresSetup,
                setupAction: {}
            )
            .frame(width: 390, height: 600)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    // MARK: - VoiceSearchButton Tests
    
    func testVoiceSearchButton_Default() {
        withSnapshotTesting(record: .all) {
            let view = VoiceSearchButton(
                onVoiceSearch: { _ in }
            )
            .frame(width: 100, height: 100)
            .padding()
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        }
    }
    
    func testVoiceSearchButton_Recording() {
        withSnapshotTesting(record: .all) {
            let view = VoiceSearchButton(
                onVoiceSearch: { _ in },
                isRecording: true
            )
            .frame(width: 100, height: 100)
            .padding()
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        }
    }
    
    // MARK: - SyncStatusView Tests
    
    func testSyncStatusView_Synced() {
        withSnapshotTesting(record: .all) {
            let view = SyncStatusView(
                syncStatus: .synced,
                lastSyncDate: Date()
            )
            .frame(width: 390, height: 150)
            .padding()
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        }
    }
    
    func testSyncStatusView_Syncing() {
        withSnapshotTesting(record: .all) {
            let view = SyncStatusView(
                syncStatus: .syncing,
                progress: 0.65,
                itemsToSync: 25
            )
            .frame(width: 390, height: 150)
            .padding()
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        }
    }
    
    func testSyncStatusView_Error() {
        withSnapshotTesting(record: .all) {
            let view = SyncStatusView(
                syncStatus: .error("Failed to connect to server"),
                lastSyncDate: Date().addingTimeInterval(-3600)
            )
            .frame(width: 390, height: 150)
            .padding()
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        }
    }
    
    func testSyncStatusView_Offline() {
        withSnapshotTesting(record: .all) {
            let view = SyncStatusView(
                syncStatus: .offline,
                lastSyncDate: Date().addingTimeInterval(-86400),
                pendingChanges: 12
            )
            .frame(width: 390, height: 150)
            .padding()
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        }
    }
}