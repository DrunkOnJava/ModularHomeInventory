//
//  PremiumUpgradeViewSnapshotTests.swift
//  HomeInventoryModularTests
//
//  Snapshot tests for PremiumUpgradeView component
//

import XCTest
import SnapshotTesting
import SwiftUI
@testable import Premium
@testable import Core
@testable import SharedUI

final class PremiumUpgradeViewSnapshotTests: XCTestCase {
    
    // MARK: - Mock Data
    
    private var mockPremiumFeatures: [PremiumFeature] {
        [
            PremiumFeature(
                id: UUID(),
                title: "Unlimited Items",
                description: "Add unlimited items to your inventory",
                icon: "infinity",
                isFree: false
            ),
            PremiumFeature(
                id: UUID(),
                title: "Advanced Analytics",
                description: "Deep insights into your spending and value trends",
                icon: "chart.line.uptrend.xyaxis",
                isFree: false
            ),
            PremiumFeature(
                id: UUID(),
                title: "Multi-Device Sync",
                description: "Sync across all your devices in real-time",
                icon: "icloud.and.arrow.up.and.arrow.down",
                isFree: false
            ),
            PremiumFeature(
                id: UUID(),
                title: "Priority Support",
                description: "Get help from our team within 24 hours",
                icon: "person.crop.circle.badge.checkmark",
                isFree: false
            ),
            PremiumFeature(
                id: UUID(),
                title: "Export to Excel/CSV",
                description: "Export your data in multiple formats",
                icon: "square.and.arrow.up",
                isFree: false
            ),
            PremiumFeature(
                id: UUID(),
                title: "Family Sharing",
                description: "Share your inventory with up to 5 family members",
                icon: "person.3",
                isFree: false
            )
        ]
    }
    
    private var mockSubscriptionOptions: [SubscriptionOption] {
        [
            SubscriptionOption(
                id: UUID(),
                type: .monthly,
                price: 4.99,
                currency: "USD",
                title: "Monthly",
                description: "Billed monthly",
                productId: "com.homeinventory.premium.monthly",
                isMostPopular: false
            ),
            SubscriptionOption(
                id: UUID(),
                type: .yearly,
                price: 39.99,
                currency: "USD",
                title: "Annual",
                description: "Save 33% - Billed yearly",
                productId: "com.homeinventory.premium.yearly",
                isMostPopular: true,
                savings: "Save $19.89"
            ),
            SubscriptionOption(
                id: UUID(),
                type: .lifetime,
                price: 99.99,
                currency: "USD",
                title: "Lifetime",
                description: "One-time purchase",
                productId: "com.homeinventory.premium.lifetime",
                isMostPopular: false
            )
        ]
    }
    
    // MARK: - Tests
    
    func testPremiumUpgrade_Default() {
        withSnapshotTesting(record: .all) {
            let view = PremiumUpgradeView(
                isPresented: .constant(true),
                features: mockPremiumFeatures,
                subscriptionOptions: mockSubscriptionOptions
            )
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testPremiumUpgrade_MonthlySelected() {
        withSnapshotTesting(record: .all) {
            let view = PremiumUpgradeView(
                isPresented: .constant(true),
                features: mockPremiumFeatures,
                subscriptionOptions: mockSubscriptionOptions,
                selectedOption: mockSubscriptionOptions[0]
            )
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testPremiumUpgrade_YearlySelected() {
        withSnapshotTesting(record: .all) {
            let view = PremiumUpgradeView(
                isPresented: .constant(true),
                features: mockPremiumFeatures,
                subscriptionOptions: mockSubscriptionOptions,
                selectedOption: mockSubscriptionOptions[1]
            )
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testPremiumUpgrade_LifetimeSelected() {
        withSnapshotTesting(record: .all) {
            let view = PremiumUpgradeView(
                isPresented: .constant(true),
                features: mockPremiumFeatures,
                subscriptionOptions: mockSubscriptionOptions,
                selectedOption: mockSubscriptionOptions[2]
            )
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testPremiumUpgrade_Loading() {
        withSnapshotTesting(record: .all) {
            let view = PremiumUpgradeView(
                isPresented: .constant(true),
                features: mockPremiumFeatures,
                subscriptionOptions: mockSubscriptionOptions,
                isLoading: true
            )
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testPremiumUpgrade_RestorePurchases() {
        withSnapshotTesting(record: .all) {
            let view = PremiumUpgradeView(
                isPresented: .constant(true),
                features: mockPremiumFeatures,
                subscriptionOptions: mockSubscriptionOptions,
                showRestoreButton: true
            )
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testPremiumUpgrade_WithTrial() {
        withSnapshotTesting(record: .all) {
            var options = mockSubscriptionOptions
            options[0].trialDays = 7
            options[0].description = "7-day free trial, then $4.99/month"
            
            let view = PremiumUpgradeView(
                isPresented: .constant(true),
                features: mockPremiumFeatures,
                subscriptionOptions: options
            )
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testPremiumUpgrade_iPad() {
        withSnapshotTesting(record: .all) {
            let view = PremiumUpgradeView(
                isPresented: .constant(true),
                features: mockPremiumFeatures,
                subscriptionOptions: mockSubscriptionOptions
            )
            .frame(width: 1024, height: 1366)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPadPro12_9))
        }
    }
    
    func testPremiumUpgrade_DarkMode() {
        withSnapshotTesting(record: .all) {
            let view = PremiumUpgradeView(
                isPresented: .constant(true),
                features: mockPremiumFeatures,
                subscriptionOptions: mockSubscriptionOptions
            )
            .frame(width: 390, height: 844)
            .preferredColorScheme(.dark)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testPremiumUpgrade_CompactHeight() {
        withSnapshotTesting(record: .all) {
            let view = PremiumUpgradeView(
                isPresented: .constant(true),
                features: mockPremiumFeatures,
                subscriptionOptions: mockSubscriptionOptions
            )
            .frame(width: 844, height: 390) // Landscape
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(size: CGSize(width: 844, height: 390)))
        }
    }
}