//
//  AppLaunchOptimizerTests.swift
//  CoreTests
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import XCTest
@testable import Core

final class AppLaunchOptimizerTests: XCTestCase {
    
    var sut: AppLaunchOptimizer!
    
    override func setUp() {
        super.setUp()
        // Create fresh instance for each test
        sut = AppLaunchOptimizer()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testSharedInstance() {
        let shared1 = AppLaunchOptimizer.shared
        let shared2 = AppLaunchOptimizer.shared
        XCTAssertTrue(shared1 === shared2)
    }
    
    // MARK: - Phase Tracking Tests
    
    func testStartPhase() {
        // When
        sut.startPhase(.appDelegate)
        
        // Then
        XCTAssertTrue(sut.getMetrics().metrics.keys.contains("app-delegate-start"))
    }
    
    func testEndPhase() {
        // Given
        sut.startPhase(.sceneDelegate)
        
        // When
        sut.endPhase(.sceneDelegate)
        
        // Then
        let metrics = sut.getMetrics()
        XCTAssertTrue(metrics.metrics.keys.contains("scene-delegate-start"))
        XCTAssertTrue(metrics.metrics.keys.contains("scene-delegate-end"))
        XCTAssertTrue(metrics.metrics.keys.contains("scene-delegate-duration"))
    }
    
    func testPhaseDuration() {
        // Given
        sut.startPhase(.initialViewController)
        let delay = 0.1
        
        // When
        Thread.sleep(forTimeInterval: delay)
        sut.endPhase(.initialViewController)
        
        // Then
        let metrics = sut.getMetrics()
        if let duration = metrics.metrics["initial-view-duration"] {
            XCTAssertGreaterThanOrEqual(duration, delay)
            XCTAssertLessThan(duration, delay + 0.1) // Allow some margin
        } else {
            XCTFail("Duration not recorded")
        }
    }
    
    // MARK: - Deferred Work Tests
    
    func testDeferWork() {
        // Given
        let expectation = expectation(description: "Deferred work executed")
        var workExecuted = false
        
        // When
        sut.deferWork {
            workExecuted = true
            expectation.fulfill()
        }
        
        // Execute deferred work
        sut.executeDeferredWork()
        
        // Then
        waitForExpectations(timeout: 1.0)
        XCTAssertTrue(workExecuted)
    }
    
    func testMultipleDeferredWork() {
        // Given
        var executionOrder: [Int] = []
        let expectation = expectation(description: "All work executed")
        expectation.expectedFulfillmentCount = 3
        
        // When
        sut.deferWork {
            executionOrder.append(1)
            expectation.fulfill()
        }
        
        sut.deferWork {
            executionOrder.append(2)
            expectation.fulfill()
        }
        
        sut.deferWork {
            executionOrder.append(3)
            expectation.fulfill()
        }
        
        // Execute all deferred work
        sut.executeDeferredWork()
        
        // Then
        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(executionOrder, [1, 2, 3])
    }
    
    // MARK: - Preloading Tests
    
    func testPreloadCriticalData() async {
        // When
        await sut.preloadCriticalData()
        
        // Then - Should complete without error
        XCTAssertTrue(true)
    }
    
    // MARK: - Metrics Tests
    
    func testGetMetrics() {
        // Given
        sut.startPhase(.preMain)
        sut.endPhase(.preMain)
        sut.startPhase(.appDelegate)
        
        // When
        let metrics = sut.getMetrics()
        
        // Then
        XCTAssertFalse(metrics.metrics.isEmpty)
        XCTAssertTrue(metrics.metrics.keys.contains("pre-main-start"))
        XCTAssertTrue(metrics.metrics.keys.contains("pre-main-end"))
        XCTAssertTrue(metrics.metrics.keys.contains("app-delegate-start"))
    }
    
    func testTotalLaunchTime() {
        // Given
        sut.startPhase(.preMain)
        Thread.sleep(forTimeInterval: 0.05)
        sut.endPhase(.preMain)
        
        sut.startPhase(.appDelegate)
        Thread.sleep(forTimeInterval: 0.05)
        sut.endPhase(.appDelegate)
        
        // When
        let metrics = sut.getMetrics()
        
        // Then
        if let totalTime = metrics.totalLaunchTime {
            XCTAssertGreaterThanOrEqual(totalTime, 0.1)
            XCTAssertLessThan(totalTime, 0.2) // Allow margin
        } else {
            XCTFail("Total launch time not calculated")
        }
    }
    
    // MARK: - Report Generation Tests
    
    func testGenerateReport() {
        // Given
        sut.startPhase(.preMain)
        sut.endPhase(.preMain)
        sut.startPhase(.appDelegate)
        sut.endPhase(.appDelegate)
        
        // When
        let report = sut.generateReport()
        
        // Then
        XCTAssertFalse(report.isEmpty)
        XCTAssertTrue(report.contains("Launch Performance Report"))
        XCTAssertTrue(report.contains("pre-main"))
        XCTAssertTrue(report.contains("app-delegate"))
    }
    
    // MARK: - Phase Target Tests
    
    func testPhaseTargets() {
        XCTAssertEqual(AppLaunchOptimizer.LaunchPhase.preMain.target, 0.4)
        XCTAssertEqual(AppLaunchOptimizer.LaunchPhase.appDelegate.target, 0.05)
        XCTAssertEqual(AppLaunchOptimizer.LaunchPhase.sceneDelegate.target, 0.05)
        XCTAssertEqual(AppLaunchOptimizer.LaunchPhase.initialViewController.target, 0.1)
        XCTAssertEqual(AppLaunchOptimizer.LaunchPhase.firstFrame.target, 0.05)
        XCTAssertEqual(AppLaunchOptimizer.LaunchPhase.interactive.target, 0.05)
    }
    
    // MARK: - Edge Case Tests
    
    func testEndPhaseWithoutStart() {
        // When - End phase without starting it
        sut.endPhase(.firstFrame)
        
        // Then - Should not crash
        let metrics = sut.getMetrics()
        XCTAssertFalse(metrics.metrics.keys.contains("first-frame-duration"))
    }
    
    func testStartSamePhaseMultipleTimes() {
        // Given
        sut.startPhase(.interactive)
        let firstStartTime = sut.getMetrics().metrics["interactive-start"]
        
        Thread.sleep(forTimeInterval: 0.1)
        
        // When - Start same phase again
        sut.startPhase(.interactive)
        let secondStartTime = sut.getMetrics().metrics["interactive-start"]
        
        // Then - Should use first start time
        XCTAssertEqual(firstStartTime, secondStartTime)
    }
}