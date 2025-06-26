//
//  TimeBasedAnalyticsView.swift
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
//  Testing: ItemsTests/Analytics/TimeBasedAnalyticsViewTests.swift
//
//  Description: Comprehensive time-based analytics dashboard displaying spending trends, seasonal
//  patterns, acquisition rates, and temporal insights with interactive charts, heatmaps, and
//  detailed breakdowns for understanding purchasing behavior over time.
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core
import SharedUI
import Charts

/// Main view for time-based analytics and trends
/// Swift 5.9 - No Swift 6 features
struct TimeBasedAnalyticsView: View {
    @StateObject private var viewModel: TimeBasedAnalyticsViewModel
    @State private var selectedPeriod: Core.AnalyticsPeriod = .month
    @State private var showingDatePicker = false
    @State private var customStartDate = Date()
    @State private var selectedTab = 0
    
    init(itemRepository: any ItemRepository) {
        self._viewModel = StateObject(wrappedValue: TimeBasedAnalyticsViewModel(
            itemRepository: itemRepository
        ))
    }
    
    var body: some View {
        ScrollView {
                VStack(spacing: 24) {
                    // Period Selector
                    PeriodSelector(
                        selectedPeriod: $selectedPeriod,
                        showingDatePicker: $showingDatePicker
                    )
                    .onChange(of: selectedPeriod) { _ in
                        Task {
                            await viewModel.loadAnalytics(for: selectedPeriod)
                        }
                    }
                    
                    if viewModel.isLoading {
                        ProgressView("Analyzing trends...")
                            .padding(50)
                    } else if let analytics = viewModel.currentAnalytics {
                        // Metrics Overview
                        MetricsOverviewCard(
                            metrics: analytics.metrics,
                            comparison: analytics.comparisons
                        )
                        
                        // Tab Selection
                        Picker("View", selection: $selectedTab) {
                            Text("Trends").tag(0)
                            Text("Breakdown").tag(1)
                            Text("Insights").tag(2)
                            Text("Seasonal").tag(3)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        
                        switch selectedTab {
                        case 0:
                            // Spending Trends Chart
                            SpendingTrendsChart(
                                trends: analytics.trends,
                                period: analytics.period
                            )
                            
                            // Acquisition Rate Chart
                            if let acquisitionAnalysis = viewModel.acquisitionAnalysis {
                                AcquisitionRateCard(analysis: acquisitionAnalysis)
                            }
                            
                        case 1:
                            // Category Breakdown
                            CategoryBreakdownChart(
                                categories: analytics.metrics.categoryBreakdown
                            )
                            
                            // Store Breakdown
                            if !analytics.metrics.storeBreakdown.isEmpty {
                                StoreBreakdownChart(
                                    stores: analytics.metrics.storeBreakdown
                                )
                            }
                            
                        case 2:
                            // Insights
                            InsightsSection(insights: analytics.insights)
                            
                        case 3:
                            // Seasonal Patterns
                            if !viewModel.seasonalPatterns.isEmpty {
                                SeasonalPatternsView(patterns: viewModel.seasonalPatterns)
                            }
                            
                        default:
                            EmptyView()
                        }
                        
                        // Heatmap (for monthly/yearly views)
                        if selectedPeriod == .month || selectedPeriod == .year {
                            SpendingHeatmapView(
                                heatmapData: viewModel.spendingHeatmap,
                                year: Calendar.current.component(.year, from: Date())
                            )
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Time Analysis")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            Task { await viewModel.exportData() }
                        }) {
                            Label("Export Data", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(action: {
                            Task { await viewModel.loadAnalytics(for: selectedPeriod) }
                        }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingDatePicker) {
                DatePickerSheet(
                    date: $customStartDate,
                    onSelect: {
                        Task {
                            await viewModel.loadAnalytics(for: .custom, startDate: customStartDate)
                        }
                    }
                )
            }
            .task {
                await viewModel.loadAnalytics(for: selectedPeriod)
                await viewModel.loadSeasonalPatterns()
            }
    }
}

// MARK: - Period Selector
struct PeriodSelector: View {
    @Binding var selectedPeriod: Core.AnalyticsPeriod
    @Binding var showingDatePicker: Bool
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Core.AnalyticsPeriod.allCases, id: \.self) { period in
                    Button(action: {
                        if period == .custom {
                            showingDatePicker = true
                        } else {
                            selectedPeriod = period
                        }
                    }) {
                        Text(period.rawValue)
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedPeriod == period ? AppColors.primary : Color(.systemGray5))
                            .foregroundStyle(selectedPeriod == period ? .white : .primary)
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Metrics Overview Card
struct MetricsOverviewCard: View {
    let metrics: Core.TimeMetrics
    let comparison: Core.PeriodComparison?
    
    var body: some View {
        VStack(spacing: 20) {
            // Total Spent with comparison
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Spent")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(metrics.totalSpent, format: .currency(code: "USD").precision(.fractionLength(2)))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    
                    if let comparison = comparison {
                        ComparisonBadge(
                            change: comparison.spendingChange,
                            percentage: comparison.spendingChangePercentage,
                            trend: comparison.trend
                        )
                    }
                }
                
                Spacer()
                
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(AppColors.primary.opacity(0.3))
            }
            
            // Key Metrics Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                MetricCard(
                    title: "Items Added",
                    value: "\(metrics.itemsAdded)",
                    icon: "plus.circle",
                    color: .blue,
                    comparison: comparison?.itemCountChange
                )
                
                MetricCard(
                    title: "Avg Value",
                    value: metrics.averageItemValue.asCurrency(),
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                )
                
                if let mostExpensive = metrics.mostExpensiveItem {
                    MetricCard(
                        title: "Most Expensive",
                        value: mostExpensive.name,
                        subtitle: mostExpensive.purchasePrice.asCurrency(),
                        icon: "crown.fill",
                        color: .orange
                    )
                }
                
                if let mostActiveDay = metrics.mostActiveDay {
                    MetricCard(
                        title: "Most Active",
                        value: mostActiveDay.formatted(date: .abbreviated, time: .omitted),
                        icon: "flame.fill",
                        color: .red
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct ComparisonBadge: View {
    let change: Decimal
    let percentage: Double
    let trend: Core.TrendDirection
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: trend.icon)
                .font(.system(size: 12))
            
            Text("\(abs(Int(percentage)))%")
                .font(.system(size: 13, weight: .semibold))
            
            Text("vs last period")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(Color(hex: trend.color))
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    let icon: String
    let color: Color
    var comparison: Int? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(color)
                Spacer()
                if let comparison = comparison, comparison != 0 {
                    Text("\(comparison > 0 ? "+" : "")\(comparison)")
                        .font(.caption)
                        .foregroundStyle(comparison > 0 ? .green : .red)
                }
            }
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(12)
    }
}

// MARK: - Spending Trends Chart
struct SpendingTrendsChart: View {
    let trends: [Core.TrendData]
    let period: Core.AnalyticsPeriod
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending Trends")
                .font(.headline)
                .padding(.horizontal)
            
            Chart(trends) { trend in
                LineMark(
                    x: .value("Date", trend.date),
                    y: .value("Amount", NSDecimalNumber(decimal: trend.value).doubleValue)
                )
                .foregroundStyle(AppColors.primary)
                .lineStyle(StrokeStyle(lineWidth: 3))
                
                PointMark(
                    x: .value("Date", trend.date),
                    y: .value("Amount", NSDecimalNumber(decimal: trend.value).doubleValue)
                )
                .foregroundStyle(AppColors.primary)
                .symbolSize(100)
                
                AreaMark(
                    x: .value("Date", trend.date),
                    y: .value("Amount", NSDecimalNumber(decimal: trend.value).doubleValue)
                )
                .foregroundStyle(AppColors.primary.opacity(0.1))
            }
            .frame(height: 250)
            .padding(.horizontal)
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(formatAxisLabel(date: date, period: period))
                                .font(.caption)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text("$\(Int(amount))")
                                .font(.caption)
                        }
                    }
                }
            }
            
            // Trend Summary
            if let first = trends.first, let last = trends.last {
                TrendSummaryRow(first: first, last: last)
            }
        }
        .padding(.vertical)
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    func formatAxisLabel(date: Date, period: Core.AnalyticsPeriod) -> String {
        let formatter = DateFormatter()
        
        switch period {
        case .day, .week:
            formatter.dateFormat = "MMM d"
        case .month:
            formatter.dateFormat = "MMM"
        case .quarter, .year:
            formatter.dateFormat = "yyyy"
        case .custom:
            formatter.dateFormat = "MMM d"
        }
        
        return formatter.string(from: date)
    }
}

struct TrendSummaryRow: View {
    let first: Core.TrendData
    let last: Core.TrendData
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Start: \(first.value.asCurrency())")
                    .font(.caption)
                Text(first.label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "arrow.right")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("Current: \(last.value.asCurrency())")
                    .font(.caption)
                Text(last.label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

// MARK: - Category Breakdown Chart
struct CategoryBreakdownChart: View {
    let categories: [Core.CategoryTimeMetric]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Category Breakdown")
                .font(.headline)
                .padding(.horizontal)
            
            Chart(categories.prefix(5)) { category in
                SectorMark(
                    angle: .value("Amount", NSDecimalNumber(decimal: category.totalSpent).doubleValue),
                    innerRadius: .ratio(0.6),
                    angularInset: 2
                )
                .foregroundStyle(Color(hex: category.category.color))
                .cornerRadius(4)
            }
            .frame(height: 200)
            .padding()
            
            // Category List
            VStack(spacing: 8) {
                ForEach(categories.prefix(5)) { category in
                    CategoryTimeRow(category: category)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct CategoryTimeRow: View {
    let category: Core.CategoryTimeMetric
    
    var body: some View {
        HStack {
            Image(systemName: category.category.icon)
                .font(.system(size: 16))
                .foregroundStyle(Color(hex: category.category.color))
                .frame(width: 24)
            
            Text(category.category.rawValue)
                .font(.system(size: 14, weight: .medium))
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(category.totalSpent, format: .currency(code: "USD").precision(.fractionLength(2)))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                
                Text("\(Int(category.percentageOfTotal))% • \(category.itemCount) items")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Store Breakdown Chart
struct StoreBreakdownChart: View {
    let stores: [Core.StoreTimeMetric]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Store Breakdown")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                ForEach(stores.prefix(5)) { store in
                    StoreTimeBar(store: store, maxValue: stores.first?.totalSpent ?? 1)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct StoreTimeBar: View {
    let store: Core.StoreTimeMetric
    let maxValue: Decimal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(store.storeName)
                    .font(.system(size: 14, weight: .medium))
                
                Spacer()
                
                Text(store.totalSpent, format: .currency(code: "USD").precision(.fractionLength(2)))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 20)
                        .cornerRadius(10)
                    
                    Rectangle()
                        .fill(AppColors.primary)
                        .frame(
                            width: geometry.size.width * CGFloat(
                                NSDecimalNumber(decimal: store.totalSpent).doubleValue / 
                                NSDecimalNumber(decimal: maxValue).doubleValue
                            ),
                            height: 20
                        )
                        .cornerRadius(10)
                    
                    Text("\(Int(store.percentageOfTotal))%")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                }
            }
            .frame(height: 20)
            
            Text("\(store.itemCount) items")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Insights Section
struct InsightsSection: View {
    let insights: [Core.TimeInsight]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Insights")
                .font(.headline)
                .padding(.horizontal)
            
            if insights.isEmpty {
                Text("No significant insights for this period")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(insights) { insight in
                        InsightCard(insight: insight)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct InsightCard: View {
    let insight: Core.TimeInsight
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: insight.type.icon)
                .font(.system(size: 20))
                .foregroundStyle(Color(hex: insight.impact.color))
                .frame(width: 32, height: 32)
                .background(Color(hex: insight.impact.color).opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.system(size: 15, weight: .semibold))
                
                Text(insight.description)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Acquisition Rate Card
struct AcquisitionRateCard: View {
    let analysis: Core.AcquisitionAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Acquisition Rate", systemImage: "plus.circle")
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: analysis.trend.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: analysis.trend.color))
            }
            
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Average/Period")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(Int(analysis.averageItemsPerPeriod)) items")
                        .font(.system(size: 16, weight: .semibold))
                }
                
                if let peakDate = analysis.peakPeriod {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Peak Period")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(peakDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next Period")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("~\(analysis.projectedNextPeriod) items")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Seasonal Patterns View
struct SeasonalPatternsView: View {
    let patterns: [Core.SeasonalPattern]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Seasonal Patterns")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(patterns, id: \.season) { pattern in
                    SeasonCard(pattern: pattern)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct SeasonCard: View {
    let pattern: Core.SeasonalPattern
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: pattern.season.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(seasonColor(pattern.season))
                
                Text(pattern.season.rawValue)
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Avg: \(pattern.averageSpending.asCurrency())")
                    .font(.system(size: 14, weight: .medium))
                
                Text("Peak: \(pattern.peakMonth)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if !pattern.typicalCategories.isEmpty {
                HStack(spacing: 4) {
                    ForEach(pattern.typicalCategories.prefix(3), id: \.self) { category in
                        Image(systemName: category.icon)
                            .font(.caption)
                            .foregroundStyle(Color(hex: category.color))
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    func seasonColor(_ season: Core.Season) -> Color {
        switch season {
        case .spring: return .green
        case .summer: return .yellow
        case .fall: return .orange
        case .winter: return .blue
        }
    }
}

// MARK: - Spending Heatmap
struct SpendingHeatmapView: View {
    let heatmapData: [[Double]]
    let year: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending Heatmap \(year)")
                .font(.headline)
                .padding(.horizontal)
            
            if heatmapData.isEmpty {
                Text("No data available for heatmap")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 2) {
                        // Month labels
                        HStack(spacing: 2) {
                            Text("").frame(width: 30)
                            ForEach(0..<31, id: \.self) { day in
                                Text("\(day + 1)")
                                    .font(.system(size: 8))
                                    .frame(width: 16, height: 16)
                            }
                        }
                        
                        // Heatmap grid
                        ForEach(0..<12, id: \.self) { month in
                            HStack(spacing: 2) {
                                Text(monthName(month))
                                    .font(.system(size: 10))
                                    .frame(width: 30, alignment: .trailing)
                                
                                ForEach(0..<31, id: \.self) { day in
                                    HeatmapCell(
                                        value: month < heatmapData.count && day < heatmapData[month].count ? 
                                               heatmapData[month][day] : 0,
                                        maxValue: maxHeatmapValue()
                                    )
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .padding(.vertical)
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    func monthName(_ index: Int) -> String {
        let formatter = DateFormatter()
        return String(formatter.shortMonthSymbols[index].prefix(3))
    }
    
    func maxHeatmapValue() -> Double {
        heatmapData.flatMap { $0 }.max() ?? 1
    }
}

struct HeatmapCell: View {
    let value: Double
    let maxValue: Double
    
    var body: some View {
        Rectangle()
            .fill(cellColor)
            .frame(width: 16, height: 16)
            .cornerRadius(2)
    }
    
    var cellColor: Color {
        guard maxValue > 0 else { return Color(.systemGray5) }
        let intensity = value / maxValue
        
        if intensity == 0 {
            return Color(.systemGray5)
        } else if intensity < 0.25 {
            return AppColors.primary.opacity(0.25)
        } else if intensity < 0.5 {
            return AppColors.primary.opacity(0.5)
        } else if intensity < 0.75 {
            return AppColors.primary.opacity(0.75)
        } else {
            return AppColors.primary
        }
    }
}

// MARK: - Date Picker Sheet
struct DatePickerSheet: View {
    @Binding var date: Date
    let onSelect: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Select Start Date")
                    .font(.headline)
                
                DatePicker(
                    "Start Date",
                    selection: $date,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()
                
                Button(action: {
                    onSelect()
                    dismiss()
                }) {
                    Text("Analyze")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.primary)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - View Model
@MainActor
final class TimeBasedAnalyticsViewModel: ObservableObject {
    @Published var currentAnalytics: Core.TimeBasedAnalytics?
    @Published var monthlyTrends: [Core.TrendData] = []
    @Published var yearlyTrends: [Core.TrendData] = []
    @Published var seasonalPatterns: [Core.SeasonalPattern] = []
    @Published var spendingHeatmap: [[Double]] = []
    @Published var acquisitionAnalysis: Core.AcquisitionAnalysis?
    @Published var isLoading = false
    
    private let analyticsService: Core.TimeBasedAnalyticsService
    
    init(itemRepository: any ItemRepository) {
        self.analyticsService = Core.TimeBasedAnalyticsService(itemRepository: itemRepository)
    }
    
    func loadAnalytics(for period: Core.AnalyticsPeriod, startDate: Date? = nil) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            currentAnalytics = try await analyticsService.calculateAnalytics(
                for: period,
                startDate: startDate
            )
            
            // Load additional data based on period
            if period == .month || period == .year {
                spendingHeatmap = try await analyticsService.getSpendingHeatmap()
            }
            
            // Load acquisition analysis
            acquisitionAnalysis = try await analyticsService.getAcquisitionRateAnalysis(
                period: period
            )
        } catch {
            print("Error loading analytics: \(error)")
        }
    }
    
    func loadSeasonalPatterns() async {
        do {
            seasonalPatterns = try await analyticsService.analyzeSeasonalPatterns()
        } catch {
            print("Error loading seasonal patterns: \(error)")
        }
    }
    
    func exportData() async {
        guard let analytics = currentAnalytics else { return }
        
        do {
            let data = try await Core.AnalyticsExportService.shared.exportTimeBasedAnalytics(
                analytics,
                format: .csv
            )
            
            let filename = "TimeAnalytics_\(Date().formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-"))"
            let fileURL = try Core.AnalyticsExportService.shared.saveToFile(
                data: data,
                filename: filename,
                format: .csv
            )
            
            print("Analytics exported to: \(fileURL)")
            // In a real app, would present share sheet or show success message
        } catch {
            print("Export failed: \(error)")
        }
    }
}