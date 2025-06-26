//
//  AppLaunchOptimizer.swift
//  Core
//
//  Apple Configuration:
//  Bundle Identifier: com.homeinventory.app
//  Display Name: Home Inventory
//  Version: 1.0.5
//  Build: 5
//  Deployment Target: iOS 17.0
//  Supported Devices: iPhone & iPad
//  Team ID: 2VXBQV4XC9
//
//  Makefile Configuration:
//  Default Simulator: iPhone 16 Pro Max (DD192264-DFAA-4582-B2FE-D6FC444C9DDF)
//  iPad Simulator: iPad Pro 13-inch (M4) (CE6D038C-840B-4BDB-AA63-D61FA0755C4A)
//  App Bundle ID: com.homeinventory.app
//  Build Path: build/Build/Products/Debug-iphonesimulator/
//
//  Google Sign-In Configuration:
//  Client ID: 316432172622-6huvbn752v0ep68jkfdftrh8fgpesikg.apps.googleusercontent.com
//  URL Scheme: com.googleusercontent.apps.316432172622-6huvbn752v0ep68jkfdftrh8fgpesikg
//  OAuth Scope: https://www.googleapis.com/auth/gmail.readonly
//  Config Files: GoogleSignIn-Info.plist (project root), GoogleServices.plist (Gmail module)
//
//  Key Commands:
//  Build and run: make build run
//  Fast build (skip module prebuild): make build-fast run
//  iPad build and run: make build-ipad run-ipad
//  Clean build: make clean build run
//  Run tests: make test
//
//  Project Structure:
//  Main Target: HomeInventoryModular
//  Test Targets: HomeInventoryModularTests, HomeInventoryModularUITests
//  Swift Version: 5.9 (DO NOT upgrade to Swift 6)
//  Minimum iOS Version: 17.0
//
//  Architecture: Modular SPM packages with local package dependencies
//  Repository: https://github.com/DrunkOnJava/ModularHomeInventory.git
//  Module: Core
//  Dependencies: Foundation, UIKit
//  Testing: CoreTests/AppLaunchOptimizerTests.swift
//
//  Description: Service for optimizing app launch performance through deferred work and caching
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation
import UIKit
import os.log

/// Service for optimizing app launch performance
public class AppLaunchOptimizer {
    
    // MARK: - Types
    
    /// Launch phase tracking
    public enum LaunchPhase: String, CaseIterable, Codable {
        case preMain = "pre-main"
        case appDelegate = "app-delegate"
        case sceneDelegate = "scene-delegate"
        case initialViewController = "initial-view"
        case firstFrame = "first-frame"
        case interactive = "interactive"
        
        var targetDuration: TimeInterval {
            switch self {
            case .preMain:
                return 0.400 // 400ms
            case .appDelegate:
                return 0.100 // 100ms
            case .sceneDelegate:
                return 0.050 // 50ms
            case .initialViewController:
                return 0.150 // 150ms
            case .firstFrame:
                return 0.200 // 200ms
            case .interactive:
                return 0.100 // 100ms
            }
        }
    }
    
    /// Launch metrics
    public struct LaunchMetrics {
        public let phase: LaunchPhase
        public let startTime: CFAbsoluteTime
        public let endTime: CFAbsoluteTime
        public let duration: TimeInterval
        public let isWithinTarget: Bool
        
        var durationMilliseconds: Int {
            Int(duration * 1000)
        }
    }
    
    /// Launch configuration
    public struct LaunchConfiguration {
        public var deferNonCriticalWork: Bool = true
        public var preloadCriticalData: Bool = true
        public var optimizeImageLoading: Bool = true
        public var useLaunchScreenCache: Bool = true
        public var enableMetricsCollection: Bool = true
        
        public init() {}
    }
    
    // MARK: - Properties
    
    public static let shared = AppLaunchOptimizer()
    
    private let logger = Logger(subsystem: "com.homeinventory.app", category: "launch")
    private var configuration = LaunchConfiguration()
    private var launchMetrics: [LaunchPhase: LaunchMetrics] = [:]
    private var phaseStartTimes: [LaunchPhase: CFAbsoluteTime] = [:]
    private let metricsQueue = DispatchQueue(label: "com.homeinventory.launch.metrics")
    
    // Deferred work
    private var deferredWorkItems: [() -> Void] = []
    private let deferredWorkQueue = DispatchQueue(label: "com.homeinventory.launch.deferred", qos: .utility)
    
    // Critical data preloading
    private var preloadTasks: [String: () async throws -> Void] = [:]
    
    // MARK: - Public Methods
    
    /// Configure launch optimization
    public func configure(_ configuration: LaunchConfiguration) {
        self.configuration = configuration
    }
    
    /// Mark the start of a launch phase
    public func startPhase(_ phase: LaunchPhase) {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        metricsQueue.async {
            self.phaseStartTimes[phase] = startTime
            self.logger.info("Launch phase '\(phase.rawValue)' started")
        }
    }
    
    /// Mark the end of a launch phase
    public func endPhase(_ phase: LaunchPhase) {
        let endTime = CFAbsoluteTimeGetCurrent()
        
        metricsQueue.async {
            guard let startTime = self.phaseStartTimes[phase] else {
                self.logger.warning("End called for phase '\(phase.rawValue)' without start")
                return
            }
            
            let duration = endTime - startTime
            let isWithinTarget = duration <= phase.targetDuration
            
            let metrics = LaunchMetrics(
                phase: phase,
                startTime: startTime,
                endTime: endTime,
                duration: duration,
                isWithinTarget: isWithinTarget
            )
            
            self.launchMetrics[phase] = metrics
            
            if isWithinTarget {
                self.logger.info("✅ Launch phase '\(phase.rawValue)' completed in \(metrics.durationMilliseconds)ms (target: \(Int(phase.targetDuration * 1000))ms)")
            } else {
                self.logger.warning("⚠️ Launch phase '\(phase.rawValue)' took \(metrics.durationMilliseconds)ms (target: \(Int(phase.targetDuration * 1000))ms)")
            }
            
            // Check if all phases complete
            if phase == .interactive {
                self.reportLaunchComplete()
            }
        }
    }
    
    /// Defer non-critical work until after launch
    public func deferWork(_ work: @escaping () -> Void) {
        guard configuration.deferNonCriticalWork else {
            work()
            return
        }
        
        deferredWorkItems.append(work)
    }
    
    /// Execute deferred work after launch completes
    public func executeDeferredWork() {
        guard configuration.deferNonCriticalWork else { return }
        
        let workItems = deferredWorkItems
        deferredWorkItems.removeAll()
        
        deferredWorkQueue.async {
            self.logger.info("Executing \(workItems.count) deferred work items")
            
            for work in workItems {
                work()
            }
        }
    }
    
    /// Register critical data to preload
    public func registerPreloadTask(_ identifier: String, task: @escaping () async throws -> Void) {
        preloadTasks[identifier] = task
    }
    
    /// Preload critical data
    public func preloadCriticalData() async {
        guard configuration.preloadCriticalData else { return }
        
        logger.info("Preloading \(self.preloadTasks.count) critical data tasks")
        
        await withTaskGroup(of: Void.self) { group in
            for (identifier, task) in preloadTasks {
                group.addTask {
                    do {
                        try await task()
                        self.logger.info("✅ Preloaded '\(identifier)'")
                    } catch {
                        self.logger.error("❌ Failed to preload '\(identifier)': \(error)")
                    }
                }
            }
        }
    }
    
    /// Optimize image loading for launch
    public func optimizeLaunchImages() {
        guard configuration.optimizeImageLoading else { return }
        
        // Preload launch screen images
        DispatchQueue.global(qos: .userInitiated).async {
            let launchImages = [
                "LaunchScreen",
                "launch-logo",
                "launch-background"
            ]
            
            for imageName in launchImages {
                _ = UIImage(named: imageName)
            }
        }
    }
    
    /// Get launch performance report
    public func getLaunchReport() -> LaunchReport {
        var totalDuration: TimeInterval = 0
        var phaseReports: [PhaseReport] = []
        
        for phase in LaunchPhase.allCases {
            if let metrics = launchMetrics[phase] {
                totalDuration += metrics.duration
                
                phaseReports.append(PhaseReport(
                    phase: phase,
                    duration: metrics.duration,
                    targetDuration: phase.targetDuration,
                    isWithinTarget: metrics.isWithinTarget
                ))
            }
        }
        
        return LaunchReport(
            totalDuration: totalDuration,
            phases: phaseReports,
            timestamp: Date()
        )
    }
    
    // MARK: - Private Methods
    
    private func reportLaunchComplete() {
        let report = getLaunchReport()
        
        logger.info("🚀 App launch completed in \(Int(report.totalDuration * 1000))ms")
        
        // Save metrics for analysis
        saveLaunchMetrics(report)
        
        // Execute deferred work
        executeDeferredWork()
        
        // Clean up
        metricsQueue.async {
            self.phaseStartTimes.removeAll()
        }
    }
    
    private func saveLaunchMetrics(_ report: LaunchReport) {
        guard configuration.enableMetricsCollection else { return }
        
        // Save to UserDefaults for simple persistence
        var history = getLaunchHistory()
        history.append(report)
        
        // Keep only last 10 launches
        if history.count > 10 {
            history = Array(history.suffix(10))
        }
        
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: "launch_metrics_history")
        }
    }
    
    private func getLaunchHistory() -> [LaunchReport] {
        guard let data = UserDefaults.standard.data(forKey: "launch_metrics_history"),
              let history = try? JSONDecoder().decode([LaunchReport].self, from: data) else {
            return []
        }
        return history
    }
}

// MARK: - Launch Report Types

public struct LaunchReport: Codable {
    public let totalDuration: TimeInterval
    public let phases: [PhaseReport]
    public let timestamp: Date
    
    public var totalDurationMilliseconds: Int {
        Int(totalDuration * 1000)
    }
    
    public var isOptimal: Bool {
        totalDuration < 1.0 // Under 1 second
    }
}

public struct PhaseReport: Codable, Sendable {
    public let phase: AppLaunchOptimizer.LaunchPhase
    public let duration: TimeInterval
    public let targetDuration: TimeInterval
    public let isWithinTarget: Bool
    
    public var durationMilliseconds: Int {
        Int(duration * 1000)
    }
    
    public var targetDurationMilliseconds: Int {
        Int(targetDuration * 1000)
    }
}

// MARK: - Launch Optimization Helpers

public extension UIViewController {
    /// Defer view setup until after launch
    func deferViewSetup(_ setup: @escaping () -> Void) {
        if UIApplication.shared.applicationState == .background {
            setup()
        } else {
            AppLaunchOptimizer.shared.deferWork(setup)
        }
    }
}

public extension UIImage {
    /// Asynchronously decode image for faster rendering
    func asyncDecode(completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let cgImage = self.cgImage else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            let width = cgImage.width
            let height = cgImage.height
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bytesPerPixel = 4
            let bytesPerRow = bytesPerPixel * width
            let bitsPerComponent = 8
            
            guard let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: bitsPerComponent,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            
            guard let decodedImage = context.makeImage() else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            let uiImage = UIImage(cgImage: decodedImage, scale: self.scale, orientation: self.imageOrientation)
            
            DispatchQueue.main.async {
                completion(uiImage)
            }
        }
    }
}