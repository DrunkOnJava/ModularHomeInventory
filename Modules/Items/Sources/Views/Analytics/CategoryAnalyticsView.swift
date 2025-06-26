//
//  CategoryAnalyticsView.swift
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
//  Dependencies: SwiftUI, Core, SharedUI, Charts
//  Testing: Modules/Items/Tests/ItemsTests/CategoryAnalyticsViewTests.swift
//
//  Description: Analytics view displaying category-based insights and charts for inventory analysis
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core
import SharedUI
import Charts

/// Category Analytics view showing spending breakdown by category
/// Swift 5.9 - No Swift 6 features
struct CategoryAnalyticsView: View {
    @StateObject private var viewModel: CategoryAnalyticsViewModel
    @State private var selectedTimeRange: SpendingDashboardView.TimeRange = .month
    @State private var selectedCategory: ItemCategory?
    @State private var showingCategoryDetail = false
    @State private var chartType: ChartType = .pie
    
    enum ChartType: String, CaseIterable {
        case pie = "Pie Chart"
        case bar = "Bar Chart"
        case trend = "Trend"
        
        var icon: String {
            switch self {
            case .pie: return "chart.pie"
            case .bar: return "chart.bar"
            case .trend: return "chart.line.uptrend.xyaxis"
            }
        }
    }
    
    init(viewModel: CategoryAnalyticsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Time range selector
                timeRangePicker
                
                // Chart type selector
                chartTypePicker
                
                // Main chart
                mainChartCard
                
                // Category list with details
                categoryListCard
                
                // Insights card
                insightsCard
            }
            .padding(AppSpacing.md)
        }
        .background(AppColors.background)
        .navigationTitle("Category Analytics")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            Task {
                await viewModel.loadData(for: selectedTimeRange)
            }
        }
        .sheet(isPresented: $showingCategoryDetail) {
            if let category = selectedCategory {
                CategoryDetailView(
                    category: category,
                    timeRange: selectedTimeRange,
                    viewModel: viewModel
                )
            }
        }
    }
    
    // MARK: - Components
    
    private var timeRangePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(SpendingDashboardView.TimeRange.allCases, id: \.self) { range in
                    Button(action: {
                        selectedTimeRange = range
                        Task {
                            await viewModel.loadData(for: range)
                        }
                    }) {
                        Text(range.displayName)
                            .textStyle(.bodyMedium)
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.sm)
                            .background(selectedTimeRange == range ? AppColors.primary : AppColors.surface)
                            .foregroundStyle(selectedTimeRange == range ? .white : AppColors.textPrimary)
                            .cornerRadius(AppCornerRadius.medium)
                    }
                }
            }
        }
    }
    
    private var chartTypePicker: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(ChartType.allCases, id: \.self) { type in
                Button(action: { chartType = type }) {
                    VStack(spacing: AppSpacing.xs) {
                        Image(systemName: type.icon)
                            .font(.title2)
                        Text(type.rawValue)
                            .textStyle(.labelSmall)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm)
                    .background(chartType == type ? AppColors.primary : AppColors.surface)
                    .foregroundStyle(chartType == type ? .white : AppColors.textPrimary)
                    .cornerRadius(AppCornerRadius.medium)
                }
            }
        }
    }
    
    private var mainChartCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Spending by Category")
                .textStyle(.headlineMedium)
                .foregroundStyle(AppColors.textPrimary)
            
            switch chartType {
            case .pie:
                pieChart
            case .bar:
                barChart
            case .trend:
                trendChart
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.large)
    }
    
    @ViewBuilder
    private var pieChart: some View {
        if !viewModel.categoryData.isEmpty {
            Chart(viewModel.categoryData) { data in
                SectorMark(
                    angle: .value("Amount", data.totalSpent),
                    innerRadius: .ratio(0.618),
                    angularInset: 1.5
                )
                .foregroundStyle(by: .value("Category", data.category.displayName))
                .cornerRadius(5)
            }
            .frame(height: 300)
        } else {
            EmptyChartView()
        }
    }
    
    @ViewBuilder
    private var barChart: some View {
        if !viewModel.categoryData.isEmpty {
            Chart(viewModel.categoryData) { data in
                BarMark(
                    x: .value("Category", data.category.displayName),
                    y: .value("Amount", data.totalSpent)
                )
                .foregroundStyle(AppColors.primary)
                .cornerRadius(5)
            }
            .frame(height: 300)
        } else {
            EmptyChartView()
        }
    }
    
    @ViewBuilder
    private var trendChart: some View {
        if !viewModel.trendData.isEmpty {
            Chart {
                ForEach(viewModel.trendData) { trend in
                    ForEach(trend.dataPoints) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Amount", point.amount)
                        )
                        .foregroundStyle(by: .value("Category", trend.category.displayName))
                        .symbol(by: .value("Category", trend.category.displayName))
                    }
                }
            }
            .frame(height: 300)
        } else {
            EmptyChartView()
        }
    }
    
    private var categoryListCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Category Breakdown")
                    .textStyle(.headlineMedium)
                    .foregroundStyle(AppColors.textPrimary)
                
                Spacer()
                
                Text("\(viewModel.categoryData.count) categories")
                    .textStyle(.labelMedium)
                    .foregroundStyle(AppColors.textSecondary)
            }
            
            VStack(spacing: AppSpacing.sm) {
                ForEach(viewModel.categoryData) { data in
                    CategoryListRow(
                        data: data,
                        totalSpent: viewModel.totalSpent,
                        rank: viewModel.getRank(for: data.category)
                    ) {
                        selectedCategory = data.category
                        showingCategoryDetail = true
                    }
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.large)
    }
    
    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Insights")
                .textStyle(.headlineMedium)
                .foregroundStyle(AppColors.textPrimary)
            
            VStack(spacing: AppSpacing.md) {
                InsightRow(
                    icon: "arrow.up.circle.fill",
                    title: "Top Category",
                    value: viewModel.topCategory?.displayName ?? "N/A",
                    subtitle: viewModel.topCategoryPercentage,
                    color: .green
                )
                
                InsightRow(
                    icon: "chart.line.uptrend.xyaxis.circle.fill",
                    title: "Fastest Growing",
                    value: viewModel.fastestGrowingCategory?.displayName ?? "N/A",
                    subtitle: viewModel.growthPercentage,
                    color: .orange
                )
                
                InsightRow(
                    icon: "cart.circle.fill",
                    title: "Most Items",
                    value: viewModel.categoryWithMostItems?.displayName ?? "N/A",
                    subtitle: "\(viewModel.mostItemsCount) items",
                    color: .blue
                )
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.large)
    }
}

// MARK: - Supporting Views

private struct CategoryListRow: View {
    let data: CategorySpendingData
    let totalSpent: Decimal
    let rank: Int
    let action: () -> Void
    
    private var percentage: Double {
        guard totalSpent > 0 else { return 0 }
        return Double(truncating: (data.totalSpent / totalSpent * 100) as NSNumber)
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                // Rank badge
                Text("#\(rank)")
                    .textStyle(.labelMedium)
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(rank <= 3 ? AppColors.primary : AppColors.textTertiary)
                    .clipShape(Circle())
                
                // Category info
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack {
                        Image(systemName: data.category.icon)
                            .foregroundStyle(AppColors.primary)
                        Text(data.category.displayName)
                            .textStyle(.bodyMedium)
                            .foregroundStyle(AppColors.textPrimary)
                    }
                    
                    HStack {
                        Text("\(data.itemCount) items")
                            .textStyle(.labelSmall)
                            .foregroundStyle(AppColors.textSecondary)
                        
                        Text("•")
                            .foregroundStyle(AppColors.textTertiary)
                        
                        Text("\(Int(percentage))% of total")
                            .textStyle(.labelSmall)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                
                Spacer()
                
                // Amount
                VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                    Text(data.totalSpent, format: .currency(code: "USD"))
                        .textStyle(.bodyLarge)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    if let avgPrice = data.averagePrice {
                        Text("avg \(avgPrice.formatted(.currency(code: "USD")))")
                            .textStyle(.labelSmall)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }
            .padding(.vertical, AppSpacing.xs)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct InsightRow: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.1))
                .cornerRadius(AppCornerRadius.small)
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .textStyle(.labelMedium)
                    .foregroundStyle(AppColors.textSecondary)
                Text(value)
                    .textStyle(.bodyLarge)
                    .foregroundStyle(AppColors.textPrimary)
            }
            
            Spacer()
            
            Text(subtitle)
                .textStyle(.bodyMedium)
                .foregroundStyle(color)
        }
    }
}

private struct EmptyChartView: View {
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "chart.pie")
                .font(.system(size: 60))
                .foregroundStyle(AppColors.textTertiary)
            Text("No data available")
                .textStyle(.bodyMedium)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Category Detail View

private struct CategoryDetailView: View {
    let category: ItemCategory
    let timeRange: SpendingDashboardView.TimeRange
    let viewModel: CategoryAnalyticsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Category stats
                    categoryStatsCard
                    
                    // Monthly trend
                    monthlyTrendCard
                    
                    // Items list
                    itemsListCard
                }
                .padding(AppSpacing.md)
            }
            .background(AppColors.background)
            .navigationTitle(category.displayName)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var categoryStatsCard: some View {
        let data = viewModel.getCategoryData(for: category)
        
        return VStack(spacing: AppSpacing.lg) {
            HStack {
                Image(systemName: category.icon)
                    .font(.system(size: 48))
                    .foregroundStyle(AppColors.primary)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                    if let totalSpent = data?.totalSpent {
                        Text(totalSpent, format: .currency(code: "USD"))
                            .textStyle(.headlineLarge)
                            .foregroundStyle(AppColors.textPrimary)
                    } else {
                        Text("$0.00")
                            .textStyle(.headlineLarge)
                            .foregroundStyle(AppColors.textPrimary)
                    }
                    
                    Text("\(data?.itemCount ?? 0) items")
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            
            HStack(spacing: AppSpacing.lg) {
                StatBox(
                    label: "Avg. Price",
                    value: (data?.averagePrice ?? 0).formatted(.currency(code: "USD"))
                )
                
                StatBox(
                    label: "% of Total",
                    value: "\(viewModel.getPercentage(for: category))%"
                )
                
                StatBox(
                    label: "Rank",
                    value: "#\(viewModel.getRank(for: category))"
                )
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.large)
    }
    
    private var monthlyTrendCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Monthly Trend")
                .textStyle(.headlineMedium)
                .foregroundStyle(AppColors.textPrimary)
            
            if let trendData = viewModel.getTrendData(for: category),
               !trendData.dataPoints.isEmpty {
                Chart(trendData.dataPoints) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Amount", point.amount)
                    )
                    .foregroundStyle(AppColors.primary)
                    
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Amount", point.amount)
                    )
                    .foregroundStyle(AppColors.primary.opacity(0.1))
                }
                .frame(height: 200)
            } else {
                EmptyChartView()
                    .frame(height: 200)
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.large)
    }
    
    private var itemsListCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Recent Items")
                .textStyle(.headlineMedium)
                .foregroundStyle(AppColors.textPrimary)
            
            VStack(spacing: AppSpacing.sm) {
                ForEach(Array(viewModel.getItems(for: category).prefix(10))) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text(item.name)
                                .textStyle(.bodyMedium)
                                .foregroundStyle(AppColors.textPrimary)
                            
                            if let date = item.purchaseDate {
                                Text(date, style: .date)
                                    .textStyle(.labelSmall)
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                        
                        Spacer()
                        
                        if let price = item.purchasePrice {
                            Text(price, format: .currency(code: "USD"))
                                .textStyle(.bodyMedium)
                                .foregroundStyle(AppColors.textPrimary)
                        }
                    }
                    .padding(.vertical, AppSpacing.xs)
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.large)
    }
}

private struct StatBox: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Text(label)
                .textStyle(.labelSmall)
                .foregroundStyle(AppColors.textSecondary)
            Text(value)
                .textStyle(.bodyLarge)
                .foregroundStyle(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }
}