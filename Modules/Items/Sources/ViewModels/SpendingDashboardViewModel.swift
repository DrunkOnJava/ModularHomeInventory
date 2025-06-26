//
//  SpendingDashboardViewModel.swift
//  Items Module
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
//  Dependencies: Core, Combine
//  Testing: ItemsTests/SpendingDashboardViewModelTests.swift
//
//  Description: View model for spending dashboard analytics and data management
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation
import Core
import Combine

/// View model for the spending dashboard
/// Swift 5.9 - No Swift 6 features
@MainActor
final class SpendingDashboardViewModel: ObservableObject {
    // Dependencies
    let itemRepository: any ItemRepository
    let receiptRepository: (any ReceiptRepository)?
    let budgetRepository: (any BudgetRepository)?
    let warrantyRepository: any WarrantyRepository
    
    // Published properties
    @Published var totalSpent: Decimal = 0
    @Published var itemCount: Int = 0
    @Published var averagePrice: Decimal = 0
    @Published var categoryCount: Int = 0
    @Published var spendingData: [SpendingDataPoint] = []
    @Published var topCategories: [CategorySpendingData] = []
    @Published var recentPurchases: [Item] = []
    @Published var topRetailers: [RetailerSpendingData] = []
    @Published var isLoading = false
    @Published var spendingTrend: Double = 0
    
    let currency = "USD"
    
    var hasEnoughDataForInsights: Bool {
        itemCount > 0 && (topCategories.count > 0 || topRetailers.count > 0)
    }
    
    init(itemRepository: any ItemRepository, receiptRepository: (any ReceiptRepository)? = nil, budgetRepository: (any BudgetRepository)? = nil, warrantyRepository: any WarrantyRepository) {
        self.itemRepository = itemRepository
        self.receiptRepository = receiptRepository
        self.budgetRepository = budgetRepository
        self.warrantyRepository = warrantyRepository
    }
    
    func loadData(for timeRange: SpendingDashboardView.TimeRange) async {
        isLoading = true
        
        do {
            // Load all items
            let allItems = try await itemRepository.fetchAll()
            
            // Filter items by time range
            let filteredItems = filterItems(allItems, by: timeRange)
            
            // Calculate statistics
            calculateStatistics(from: filteredItems)
            
            // Generate spending data points for chart
            generateSpendingData(from: filteredItems, timeRange: timeRange)
            
            // Calculate category breakdown
            calculateCategoryBreakdown(from: filteredItems)
            
            // Get recent purchases
            updateRecentPurchases(from: filteredItems)
            
            // Calculate top retailers (using brand as proxy for now)
            calculateTopRetailers(from: filteredItems)
            
            // Calculate spending trend if possible
            await calculateSpendingTrend(currentItems: filteredItems, timeRange: timeRange)
            
        } catch {
            print("Error loading spending data: \(error)")
        }
        
        isLoading = false
    }
    
    func getItems(for category: ItemCategory) -> [Item] {
        // This would be better with a proper filtered fetch from repository
        return recentPurchases.filter { $0.category == category }
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
    
    private func calculateStatistics(from items: [Item]) {
        itemCount = items.count
        
        totalSpent = items.reduce(0) { sum, item in
            sum + (item.purchasePrice ?? 0)
        }
        
        averagePrice = itemCount > 0 ? totalSpent / Decimal(itemCount) : 0
        
        let categories = Set(items.map { $0.category })
        categoryCount = categories.count
    }
    
    private func generateSpendingData(from items: [Item], timeRange: SpendingDashboardView.TimeRange) {
        let calendar = Calendar.current
        var dataPoints: [Date: Decimal] = [:]
        
        // Group items by time period
        for item in items {
            guard let purchaseDate = item.purchaseDate,
                  let price = item.purchasePrice else { continue }
            
            let periodDate: Date
            switch timeRange {
            case .week:
                // Group by day
                periodDate = calendar.startOfDay(for: purchaseDate)
            case .month:
                // Group by week
                let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: purchaseDate)
                periodDate = calendar.date(from: components) ?? purchaseDate
            case .quarter, .year:
                // Group by month
                let components = calendar.dateComponents([.year, .month], from: purchaseDate)
                periodDate = calendar.date(from: components) ?? purchaseDate
            case .all:
                // Group by year
                let components = calendar.dateComponents([.year], from: purchaseDate)
                periodDate = calendar.date(from: components) ?? purchaseDate
            }
            
            dataPoints[periodDate, default: 0] += price
        }
        
        // Convert to array and sort
        spendingData = dataPoints.map { SpendingDataPoint(date: $0.key, amount: $0.value) }
            .sorted { $0.date < $1.date }
    }
    
    private func calculateCategoryBreakdown(from items: [Item]) {
        var categoryData: [ItemCategory: (count: Int, total: Decimal)] = [:]
        
        for item in items {
            guard let price = item.purchasePrice else { continue }
            let current = categoryData[item.category, default: (0, 0)]
            categoryData[item.category] = (current.count + 1, current.total + price)
        }
        
        topCategories = categoryData.map { category, data in
            CategorySpendingData(
                id: UUID(),
                category: category,
                itemCount: data.count,
                totalSpent: data.total
            )
        }
        .sorted { $0.totalSpent > $1.totalSpent }
    }
    
    private func updateRecentPurchases(from items: [Item]) {
        recentPurchases = items
            .filter { $0.purchaseDate != nil && $0.purchasePrice != nil }
            .sorted { ($0.purchaseDate ?? Date.distantPast) > ($1.purchaseDate ?? Date.distantPast) }
    }
    
    private func calculateTopRetailers(from items: [Item]) {
        var retailerData: [String: (count: Int, total: Decimal)] = [:]
        
        for item in items {
            guard let price = item.purchasePrice else { continue }
            // Using brand as proxy for retailer - in real app would have retailer field
            let retailer = item.brand ?? "Unknown"
            let current = retailerData[retailer, default: (0, 0)]
            retailerData[retailer] = (current.count + 1, current.total + price)
        }
        
        topRetailers = retailerData.map { name, data in
            RetailerSpendingData(
                id: UUID(),
                name: name,
                itemCount: data.count,
                totalSpent: data.total
            )
        }
        .sorted { $0.totalSpent > $1.totalSpent }
    }
    
    private func calculateSpendingTrend(currentItems: [Item], timeRange: SpendingDashboardView.TimeRange) async {
        // Calculate spending trend by comparing with previous period
        let currentTotal = currentItems.reduce(Decimal.zero) { sum, item in
            sum + (item.purchasePrice ?? 0)
        }
        
        // Get previous period items
        do {
            let allItems = try await itemRepository.fetchAll()
            let previousItems = filterItemsForPreviousPeriod(allItems, currentTimeRange: timeRange)
            let previousTotal = previousItems.reduce(Decimal.zero) { sum, item in
                sum + (item.purchasePrice ?? 0)
            }
            
            // Calculate percentage change
            if previousTotal > 0 {
                let change = ((currentTotal - previousTotal) / previousTotal) * 100
                spendingTrend = Double(truncating: change as NSNumber)
            } else if currentTotal > 0 {
                spendingTrend = 100 // 100% increase if no previous spending
            } else {
                spendingTrend = 0
            }
        } catch {
            spendingTrend = 0
        }
    }
    
    private func filterItemsForPreviousPeriod(_ items: [Item], currentTimeRange: SpendingDashboardView.TimeRange) -> [Item] {
        let calendar = Calendar.current
        let now = Date()
        var startDate: Date
        var endDate: Date
        
        switch currentTimeRange {
        case .week:
            endDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            startDate = calendar.date(byAdding: .day, value: -14, to: now) ?? now
        case .month:
            endDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            startDate = calendar.date(byAdding: .month, value: -2, to: now) ?? now
        case .quarter:
            endDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
            startDate = calendar.date(byAdding: .month, value: -6, to: now) ?? now
        case .year:
            endDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            startDate = calendar.date(byAdding: .year, value: -2, to: now) ?? now
        case .all:
            return [] // No trend for all time
        }
        
        return items.filter { item in
            guard let purchaseDate = item.purchaseDate else { return false }
            return purchaseDate >= startDate && purchaseDate < endDate
        }
    }
}

// MARK: - Data Models

struct SpendingDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Decimal
}

struct CategorySpendingData: Identifiable {
    let id: UUID
    let category: ItemCategory
    let itemCount: Int
    let totalSpent: Decimal
}

struct RetailerSpendingData: Identifiable {
    let id: UUID
    let name: String
    let itemCount: Int
    let totalSpent: Decimal
}