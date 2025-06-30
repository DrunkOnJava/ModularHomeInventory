//
//  OnboardingViewSnapshotTests.swift
//  HomeInventoryModularTests
//
//  Snapshot tests for OnboardingView component
//

import XCTest
import SnapshotTesting
import SwiftUI
@testable import Onboarding
@testable import Core
@testable import SharedUI

final class OnboardingViewSnapshotTests: XCTestCase {
    
    // MARK: - Tests
    
    func testOnboarding_Welcome() {
        withSnapshotTesting(record: .all) {
            let view = OnboardingView(
                onComplete: { _ in },
                currentPage: 0
            )
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testOnboarding_Features() {
        withSnapshotTesting(record: .all) {
            let view = OnboardingView(
                onComplete: { _ in },
                currentPage: 1
            )
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testOnboarding_Scanning() {
        withSnapshotTesting(record: .all) {
            let view = OnboardingView(
                onComplete: { _ in },
                currentPage: 2
            )
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testOnboarding_Organization() {
        withSnapshotTesting(record: .all) {
            let view = OnboardingView(
                onComplete: { _ in },
                currentPage: 3
            )
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testOnboarding_Security() {
        withSnapshotTesting(record: .all) {
            let view = OnboardingView(
                onComplete: { _ in },
                currentPage: 4
            )
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testOnboarding_GetStarted() {
        withSnapshotTesting(record: .all) {
            let view = OnboardingView(
                onComplete: { _ in },
                currentPage: 5
            )
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testOnboarding_iPad() {
        withSnapshotTesting(record: .all) {
            let view = OnboardingView(
                onComplete: { _ in },
                currentPage: 0
            )
            .frame(width: 1024, height: 1366)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPadPro12_9))
        }
    }
    
    func testOnboarding_iPadLandscape() {
        withSnapshotTesting(record: .all) {
            let view = OnboardingView(
                onComplete: { _ in },
                currentPage: 0
            )
            .frame(width: 1366, height: 1024)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(size: CGSize(width: 1366, height: 1024)))
        }
    }
    
    func testOnboarding_DarkMode() {
        withSnapshotTesting(record: .all) {
            let view = OnboardingView(
                onComplete: { _ in },
                currentPage: 0
            )
            .frame(width: 390, height: 844)
            .preferredColorScheme(.dark)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testOnboarding_CompactHeight() {
        withSnapshotTesting(record: .all) {
            let view = OnboardingView(
                onComplete: { _ in },
                currentPage: 0
            )
            .frame(width: 844, height: 390) // Landscape iPhone
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(size: CGSize(width: 844, height: 390)))
        }
    }
    
    func testOnboarding_Accessibility() {
        withSnapshotTesting(record: .all) {
            let view = OnboardingView(
                onComplete: { _ in },
                currentPage: 0
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