//
//  StoreDetailView.swift
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
//  Dependencies: SwiftUI, Core, SharedUI, Charts
//  Testing: ItemsTests/Analytics/StoreDetailViewTests.swift
//
//  Description: Detailed analytics view for individual retailers displaying spending patterns,
//  purchase frequency, category breakdowns, and purchase history with interactive charts
//  and comprehensive store performance metrics.
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core
import SharedUI
import Charts

/// Detailed view for a specific store's analytics
/// Swift 5.9 - No Swift 6 features
struct StoreDetailView: View {
    let analytics: Core.RetailerAnalytics
    let itemRepository: any ItemRepository
    
    @State private var items: [Item] = []
    @State private var selectedCategory: ItemCategory?
    @State private var isLoadingItems = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Store Header
                    StoreHeaderCard(analytics: analytics)
                    
                    // Purchase Frequency
                    PurchaseFrequencyCard(frequency: analytics.purchaseFrequency)
                    
                    // Monthly Spending Chart
                    if !analytics.monthlySpending.isEmpty {
                        MonthlySpendingChart(monthlyData: analytics.monthlySpending)
                    }
                    
                    // Category Breakdown
                    if !analytics.topCategories.isEmpty {
                        CategoryBreakdownSection(
                            categories: analytics.topCategories,
                            selectedCategory: $selectedCategory
                        )
                    }
                    
                    // Recent Items
                    if !items.isEmpty {
                        RecentItemsSection(
                            items: Array(items.prefix(10)),
                            storeName: analytics.storeName
                        )
                    }
                    
                    // Store Stats
                    StoreStatsGrid(analytics: analytics)
                }
                .padding(.vertical)
            }
            .navigationTitle(analytics.storeName)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadStoreItems()
            }
        }
    }
    
    private func loadStoreItems() async {
        isLoadingItems = true
        defer { isLoadingItems = false }
        
        do {
            let allItems = try await itemRepository.fetchAll()
            items = allItems
                .filter { $0.storeName == analytics.storeName }
                .sorted { ($0.purchaseDate ?? Date.distantPast) > ($1.purchaseDate ?? Date.distantPast) }
        } catch {
            print("Error loading items: \(error)")
        }
    }
}

// MARK: - Store Header Card
struct StoreHeaderCard: View {
    let analytics: Core.RetailerAnalytics
    
    var body: some View {
        VStack(spacing: 16) {
            // Store Icon
            Image(systemName: "building.2.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.primary)
            
            // Total Spent
            VStack(spacing: 4) {
                Text("Total Spent")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("$\(analytics.totalSpent.formatted())")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
            }
            
            // Key Metrics
            HStack(spacing: 24) {
                MetricBadge(
                    value: "\(analytics.itemCount)",
                    label: "Items",
                    icon: "cube.box"
                )
                
                MetricBadge(
                    value: "$\(analytics.averageItemPrice.formatted())",
                    label: "Avg Price",
                    icon: "tag"
                )
                
                if let lastPurchase = analytics.lastPurchaseDate {
                    MetricBadge(
                        value: daysSince(lastPurchase),
                        label: "Days Ago",
                        icon: "calendar"
                    )
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    func daysSince(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        switch days {
        case 0: return "Today"
        case 1: return "Yesterday"
        default: return "\(days)"
        }
    }
}

struct MetricBadge: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Purchase Frequency Card
struct PurchaseFrequencyCard: View {
    let frequency: Core.PurchaseFrequency
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Label("Purchase Frequency", systemImage: frequency.icon)
                    .font(.headline)
                
                Text(frequency.rawValue)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(hex: frequency.color))
                
                Text(frequencyDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: frequency.icon)
                .font(.system(size: 40))
                .foregroundStyle(Color(hex: frequency.color).opacity(0.3))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    var frequencyDescription: String {
        switch frequency {
        case .daily: return "You shop here almost every day"
        case .weekly: return "You shop here about once a week"
        case .monthly: return "You shop here about once a month"
        case .occasional: return "You shop here occasionally"
        case .rare: return "You rarely shop here"
        }
    }
}

// MARK: - Monthly Spending Chart
struct MonthlySpendingChart: View {
    let monthlyData: [Core.MonthlySpending]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Monthly Spending Trend")
                .font(.headline)
                .padding(.horizontal)
            
            Chart(monthlyData) { data in
                LineMark(
                    x: .value("Month", data.month),
                    y: .value("Amount", NSDecimalNumber(decimal: data.amount).doubleValue)
                )
                .foregroundStyle(AppColors.primary)
                .lineStyle(StrokeStyle(lineWidth: 3))
                
                PointMark(
                    x: .value("Month", data.month),
                    y: .value("Amount", NSDecimalNumber(decimal: data.amount).doubleValue)
                )
                .foregroundStyle(AppColors.primary)
                .symbolSize(100)
            }
            .frame(height: 200)
            .padding(.horizontal)
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                        .font(.caption)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(Int(amount), format: .currency(code: "USD").precision(.fractionLength(0)))
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding(.vertical)
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Category Breakdown Section
struct CategoryBreakdownSection: View {
    let categories: [Core.CategorySpending]
    @Binding var selectedCategory: ItemCategory?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending by Category")
                .font(.headline)
                .padding(.horizontal)
            
            // Pie Chart
            Chart(categories) { category in
                SectorMark(
                    angle: .value("Amount", NSDecimalNumber(decimal: category.totalSpent).doubleValue),
                    innerRadius: .ratio(0.6),
                    angularInset: 2
                )
                .foregroundStyle(Color(hex: category.category.color))
                .opacity(selectedCategory == nil || selectedCategory == category.category ? 1 : 0.5)
            }
            .frame(height: 200)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .padding(.horizontal)
            
            // Category List
            VStack(spacing: 8) {
                ForEach(categories) { category in
                    StoreCategoryRow(
                        category: category,
                        isSelected: selectedCategory == category.category,
                        onTap: {
                            withAnimation {
                                if selectedCategory == category.category {
                                    selectedCategory = nil
                                } else {
                                    selectedCategory = category.category
                                }
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

struct StoreCategoryRow: View {
    let category: Core.CategorySpending
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Category Icon
                Image(systemName: category.category.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(Color(hex: category.category.color))
                    .frame(width: 30)
                
                // Category Name
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.category.rawValue)
                        .font(.system(size: 15, weight: .medium))
                    
                    Text("\(category.itemCount) items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Amount and Percentage
                VStack(alignment: .trailing, spacing: 2) {
                    Text(category.totalSpent, format: .currency(code: "USD").precision(.fractionLength(2)))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                    
                    Text("\(Int(category.percentage))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color(.systemGray5) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Recent Items Section
struct RecentItemsSection: View {
    let items: [Item]
    let storeName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Purchases")
                    .font(.headline)
                
                Spacer()
                
                Text("\(items.count) total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(items) { item in
                        RecentItemCard(item: item)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct RecentItemCard: View {
    let item: Item
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Category Icon
            Image(systemName: item.category.icon)
                .font(.system(size: 24))
                .foregroundStyle(Color(hex: item.category.color))
            
            // Item Name
            Text(item.name)
                .font(.system(size: 14, weight: .medium))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Price
            if let price = item.purchasePrice {
                Text(price, format: .currency(code: "USD").precision(.fractionLength(2)))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.primary)
            }
            
            // Date
            if let date = item.purchaseDate {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(width: 140)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Store Stats Grid
struct StoreStatsGrid: View {
    let analytics: Core.RetailerAnalytics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Store Statistics")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                if let firstDate = analytics.firstPurchaseDate {
                    StatCard(
                        title: "Customer Since",
                        value: firstDate.formatted(date: .abbreviated, time: .omitted),
                        icon: "person.crop.circle.badge.checkmark",
                        color: .green
                    )
                }
                
                if !analytics.monthlySpending.isEmpty {
                    let avgMonthly = analytics.monthlySpending
                        .map { NSDecimalNumber(decimal: $0.amount).doubleValue }
                        .reduce(0, +) / Double(analytics.monthlySpending.count)
                    
                    StatCard(
                        title: "Avg Monthly",
                        value: "$\(Int(avgMonthly))",
                        icon: "chart.line.uptrend.xyaxis",
                        color: .blue
                    )
                }
                
                if let highestCategory = analytics.topCategories.first {
                    StatCard(
                        title: "Top Category",
                        value: highestCategory.category.rawValue,
                        icon: highestCategory.category.icon,
                        color: Color(hex: highestCategory.category.color)
                    )
                }
                
                let loyaltyDays = Calendar.current.dateComponents(
                    [.day],
                    from: analytics.firstPurchaseDate ?? Date(),
                    to: Date()
                ).day ?? 0
                
                StatCard(
                    title: "Loyalty",
                    value: "\(loyaltyDays) days",
                    icon: "heart.circle.fill",
                    color: .red
                )
            }
            .padding(.horizontal)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
                Spacer()
            }
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}