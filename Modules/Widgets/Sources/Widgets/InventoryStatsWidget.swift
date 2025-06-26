//
//  InventoryStatsWidget.swift
//  Widgets Module
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
//  Module: Widgets
//  Dependencies: WidgetKit, SwiftUI, Core
//  Testing: Modules/Widgets/Tests/WidgetsTests.swift
//
//  Description: iOS home screen widget displaying inventory statistics.
//               Shows total items, value, favorites, and recent additions with
//               category breakdowns. Updates hourly via timeline provider.
//
//  Created by Griffin Long on June 26, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import WidgetKit
import SwiftUI
import Core

/// Widget showing inventory statistics
/// Swift 5.9 - No Swift 6 features
public struct InventoryStatsWidget: Widget {
    public let kind: String = "InventoryStatsWidget"
    
    public init() {}
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: InventoryStatsProvider()
        ) { entry in
            InventoryStatsWidgetView(entry: entry)
        }
        .configurationDisplayName("Inventory Stats")
        .description("View your inventory statistics at a glance")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

/// Timeline entry for inventory stats
public struct InventoryStatsEntry: TimelineEntry {
    public let date: Date
    public let totalItems: Int
    public let totalValue: Decimal
    public let favoriteItems: Int
    public let recentlyAdded: Int
    public let categories: [(name: String, count: Int)]
    
    public init(
        date: Date,
        totalItems: Int,
        totalValue: Decimal,
        favoriteItems: Int,
        recentlyAdded: Int,
        categories: [(name: String, count: Int)]
    ) {
        self.date = date
        self.totalItems = totalItems
        self.totalValue = totalValue
        self.favoriteItems = favoriteItems
        self.recentlyAdded = recentlyAdded
        self.categories = categories
    }
}

/// Timeline provider for inventory stats
public struct InventoryStatsProvider: TimelineProvider {
    public typealias Entry = InventoryStatsEntry
    
    public init() {}
    
    public func placeholder(in context: Context) -> InventoryStatsEntry {
        InventoryStatsEntry(
            date: Date(),
            totalItems: 100,
            totalValue: 5000,
            favoriteItems: 10,
            recentlyAdded: 5,
            categories: [
                ("Electronics", 30),
                ("Furniture", 25),
                ("Books", 20)
            ]
        )
    }
    
    public func getSnapshot(in context: Context, completion: @escaping (InventoryStatsEntry) -> Void) {
        let entry = placeholder(in: context)
        completion(entry)
    }
    
    public func getTimeline(in context: Context, completion: @escaping (Timeline<InventoryStatsEntry>) -> Void) {
        Task {
            // In a real app, fetch data from repository
            let entry = placeholder(in: context)
            
            // Update every hour
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            
            completion(timeline)
        }
    }
}