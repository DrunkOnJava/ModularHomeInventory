//
//  CategoryAnalyticsViewModel.swift
//  HomeInventoryModular
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
//  Module: Items
//  Dependencies: Foundation, Core, Combine
//  Testing: Modules/Items/Tests/ItemsTests/CategoryAnalyticsViewModelTests.swift
//
//  Description: View model for category analytics providing data processing and business logic
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation
import Core
import Combine

/// View model for category analytics
/// Swift 5.9 - No Swift 6 features
@MainActor
final class CategoryAnalyticsViewModel: ObservableObject {
    // Dependencies
    private let itemRepository: any ItemRepository
    
    // Published properties
    @Published var categoryData: [CategorySpendingData] = []
    @Published var trendData: [CategoryTrendData] = []
    @Published var totalSpent: Decimal = 0
    @Published var topCategory: ItemCategory?
    @Published var topCategoryPercentage = ""
    @Published var fastestGrowingCategory: ItemCategory?
    @Published var growthPercentage = ""
    @Published var categoryWithMostItems: ItemCategory?
    @Published var mostItemsCount = 0
    @Published var isLoading = false
    
    private var allItems: [Item] = []
    
    init(itemRepository: any ItemRepository) {
        self.itemRepository = itemRepository
    }
    
    func loadData(for timeRange: SpendingDashboardView.TimeRange) async {
        isLoading = true
        
        do {
            // Load all items
            allItems = try await itemRepository.fetchAll()
            
            // Filter items by time range
            let filteredItems = filterItems(allItems, by: timeRange)
            
            // Calculate category data
            calculateCategoryData(from: filteredItems)
            
            // Generate trend data
            generateTrendData(from: filteredItems, timeRange: timeRange)
            
            // Calculate insights
            calculateInsights()
            
        } catch {
            print("Error loading category analytics: \(error)")
        }
        
        isLoading = false
    }
    
    func getCategoryData(for category: ItemCategory) -> CategorySpendingData? {
        categoryData.first { $0.category == category }
    }
    
    func getTrendData(for category: ItemCategory) -> CategoryTrendData? {
        trendData.first { $0.category == category }
    }
    
    func getItems(for category: ItemCategory) -> [Item] {
        allItems.filter { $0.category == category && $0.purchasePrice != nil }
            .sorted { ($0.purchaseDate ?? Date.distantPast) > ($1.purchaseDate ?? Date.distantPast) }
    }
    
    func getRank(for category: ItemCategory) -> Int {
        guard let index = categoryData.firstIndex(where: { $0.category == category }) else { return 0 }
        return index + 1
    }
    
    func getPercentage(for category: ItemCategory) -> Int {
        guard totalSpent > 0,
              let data = getCategoryData(for: category) else { return 0 }
        return Int(Double(truncating: (data.totalSpent / totalSpent * 100) as NSNumber))
    }
    
    // MARK: - Private Methods
    
    private func filterItems(_ items: [Item], by timeRange: SpendingDashboardView.TimeRange) -> [Item] {
        let calendar = Calendar.current
        let now = Date()
        
        let startDate: Date
        switch timeRange {
        case .week:
            startDate = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .quarter:
            startDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        case .all:
            return items.filter { $0.purchasePrice != nil }
        }
        
        return items.filter { item in
            guard let purchaseDate = item.purchaseDate,
                  item.purchasePrice != nil else { return false }
            return purchaseDate >= startDate
        }
    }
    
    private func calculateCategoryData(from items: [Item]) {
        var categoryDataDict: [ItemCategory: (count: Int, total: Decimal)] = [:]
        
        for item in items {
            guard let price = item.purchasePrice else { continue }
            let current = categoryDataDict[item.category, default: (0, 0)]
            categoryDataDict[item.category] = (current.count + 1, current.total + price)
        }
        
        categoryData = categoryDataDict.map { category, data in
            CategorySpendingData(
                id: UUID(),
                category: category,
                itemCount: data.count,
                totalSpent: data.total
            )
        }
        .sorted { $0.totalSpent > $1.totalSpent }
        
        totalSpent = categoryData.reduce(0) { $0 + $1.totalSpent }
    }
    
    private func generateTrendData(from items: [Item], timeRange: SpendingDashboardView.TimeRange) {
        let calendar = Calendar.current
        var categoryTrends: [ItemCategory: [Date: Decimal]] = [:]
        
        for item in items {
            guard let purchaseDate = item.purchaseDate,
                  let price = item.purchasePrice else { continue }
            
            let periodDate: Date
            switch timeRange {
            case .week:
                periodDate = calendar.startOfDay(for: purchaseDate)
            case .month:
                let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: purchaseDate)
                periodDate = calendar.date(from: components) ?? purchaseDate
            case .quarter, .year:
                let components = calendar.dateComponents([.year, .month], from: purchaseDate)
                periodDate = calendar.date(from: components) ?? purchaseDate
            case .all:
                let components = calendar.dateComponents([.year], from: purchaseDate)
                periodDate = calendar.date(from: components) ?? purchaseDate
            }
            
            categoryTrends[item.category, default: [:]][periodDate, default: 0] += price
        }
        
        trendData = categoryTrends.map { category, dateData in
            let dataPoints = dateData.map { SpendingDataPoint(date: $0.key, amount: $0.value) }
                .sorted { $0.date < $1.date }
            return CategoryTrendData(category: category, dataPoints: dataPoints)
        }
    }
    
    private func calculateInsights() {
        // Top category
        if let topData = categoryData.first {
            topCategory = topData.category
            topCategoryPercentage = "\(getPercentage(for: topData.category))% of total"
        }
        
        // Category with most items
        if let mostItems = categoryData.max(by: { $0.itemCount < $1.itemCount }) {
            categoryWithMostItems = mostItems.category
            mostItemsCount = mostItems.itemCount
        }
        
        // Fastest growing (simplified - would need historical data for real growth calculation)
        // For now, use the category with highest average price as proxy
        if let highestAvg = categoryData.max(by: { 
            let avg1 = $0.itemCount > 0 ? $0.totalSpent / Decimal($0.itemCount) : 0
            let avg2 = $1.itemCount > 0 ? $1.totalSpent / Decimal($1.itemCount) : 0
            return avg1 < avg2
        }) {
            fastestGrowingCategory = highestAvg.category
            growthPercentage = "+15%" // Mock growth rate
        }
    }
}

// MARK: - Extended Data Models

extension CategorySpendingData {
    var averagePrice: Decimal? {
        guard itemCount > 0 else { return nil }
        return totalSpent / Decimal(itemCount)
    }
}

struct CategoryTrendData: Identifiable {
    let id = UUID()
    let category: ItemCategory
    let dataPoints: [SpendingDataPoint]
}