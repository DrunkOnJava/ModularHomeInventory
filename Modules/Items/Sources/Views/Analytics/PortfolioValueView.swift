//
//  PortfolioValueView.swift
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
//  Testing: ItemsTests/Analytics/PortfolioValueViewTests.swift
//
//  Description: Comprehensive portfolio value tracking view displaying current value, historical
//  trends, category breakdowns, and depreciation insights with interactive charts and detailed
//  analytics for total portfolio performance monitoring.
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core
import SharedUI
import Charts

/// Portfolio Value Tracking view showing value over time
/// Swift 5.9 - No Swift 6 features
struct PortfolioValueView: View {
    @StateObject private var viewModel: PortfolioValueViewModel
    @State private var selectedTimeRange: TimeRange = .year
    @State private var showingBreakdown = false
    @State private var selectedDataPoint: PortfolioDataPoint?
    
    enum TimeRange: String, CaseIterable {
        case month = "1M"
        case quarter = "3M"
        case halfYear = "6M"
        case year = "1Y"
        case all = "All"
        
        var displayName: String { rawValue }
    }
    
    init(viewModel: PortfolioValueViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Current value card
                currentValueCard
                
                // Time range selector
                timeRangePicker
                
                // Value chart
                valueChartCard
                
                // Statistics
                statisticsCard
                
                // Category breakdown
                categoryBreakdownCard
                
                // Most valuable items
                mostValuableItemsCard
                
                // Depreciation insights
                depreciationCard
            }
            .padding(AppSpacing.md)
        }
        .background(AppColors.background)
        .navigationTitle("Portfolio Value")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            Task {
                await viewModel.loadData(for: selectedTimeRange)
            }
        }
        .sheet(isPresented: $showingBreakdown) {
            PortfolioBreakdownView(viewModel: viewModel)
        }
    }
    
    // MARK: - Components
    
    private var currentValueCard: some View {
        VStack(spacing: AppSpacing.lg) {
            VStack(spacing: AppSpacing.xs) {
                Text("Total Portfolio Value")
                    .textStyle(.labelMedium)
                    .foregroundStyle(AppColors.textSecondary)
                
                Text(viewModel.currentValue, format: .currency(code: viewModel.currency))
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: viewModel.valueChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption)
                    Text("\(viewModel.valueChange >= 0 ? "+" : "")\(viewModel.valueChange.formatted(.currency(code: viewModel.currency)))")
                    Text("(\(viewModel.valueChangePercent)%)")
                }
                .textStyle(.bodyMedium)
                .foregroundStyle(viewModel.valueChange >= 0 ? .green : .red)
            }
            
            HStack(spacing: AppSpacing.xl) {
                ValueMetric(
                    label: "Items",
                    value: "\(viewModel.totalItems)",
                    icon: "shippingbox"
                )
                
                ValueMetric(
                    label: "Avg. Value",
                    value: viewModel.averageValue.formatted(.currency(code: viewModel.currency)),
                    icon: "chart.line.uptrend.xyaxis"
                )
                
                ValueMetric(
                    label: "Total Cost",
                    value: viewModel.totalCost.formatted(.currency(code: viewModel.currency)),
                    icon: "dollarsign.circle"
                )
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.large)
    }
    
    private var timeRangePicker: some View {
        HStack(spacing: 0) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button(action: {
                    selectedTimeRange = range
                    Task {
                        await viewModel.loadData(for: range)
                    }
                }) {
                    Text(range.displayName)
                        .textStyle(.bodyMedium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                        .background(selectedTimeRange == range ? AppColors.primary : Color.clear)
                        .foregroundStyle(selectedTimeRange == range ? .white : AppColors.textPrimary)
                }
            }
        }
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }
    
    private var valueChartCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Value Over Time")
                .textStyle(.headlineMedium)
                .foregroundStyle(AppColors.textPrimary)
            
            if !viewModel.valueHistory.isEmpty {
                Chart(viewModel.valueHistory) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Value", dataPoint.value)
                    )
                    .foregroundStyle(AppColors.primary)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Value", dataPoint.value)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [AppColors.primary.opacity(0.3), AppColors.primary.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
                .frame(height: 250)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .currency(code: viewModel.currency).precision(.fractionLength(0)))
                    }
                }
            } else {
                Rectangle()
                    .fill(AppColors.surface)
                    .frame(height: 250)
                    .overlay {
                        Text("No data available")
                            .textStyle(.bodyMedium)
                            .foregroundStyle(AppColors.textSecondary)
                    }
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.large)
    }
    
    private var statisticsCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Statistics")
                .textStyle(.headlineMedium)
                .foregroundStyle(AppColors.textPrimary)
            
            VStack(spacing: AppSpacing.md) {
                StatRow(
                    label: "Peak Value",
                    value: viewModel.peakValue.formatted(.currency(code: viewModel.currency)),
                    date: viewModel.peakValueDate,
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                )
                
                StatRow(
                    label: "Average Growth",
                    value: "\(viewModel.averageGrowthRate)% per month",
                    date: nil,
                    icon: "arrow.up.forward",
                    color: .blue
                )
                
                StatRow(
                    label: "Total Depreciation",
                    value: viewModel.totalDepreciation.formatted(.currency(code: viewModel.currency)),
                    date: nil,
                    icon: "arrow.down.forward",
                    color: .orange
                )
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.large)
    }
    
    private var categoryBreakdownCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Value by Category")
                    .textStyle(.headlineMedium)
                    .foregroundStyle(AppColors.textPrimary)
                
                Spacer()
                
                Button(action: { showingBreakdown = true }) {
                    Text("Details")
                        .textStyle(.labelMedium)
                        .foregroundStyle(AppColors.primary)
                }
            }
            
            if !viewModel.categoryValues.isEmpty {
                Chart(viewModel.categoryValues) { data in
                    SectorMark(
                        angle: .value("Value", data.value),
                        innerRadius: .ratio(0.618),
                        angularInset: 1.5
                    )
                    .foregroundStyle(by: .value("Category", data.category.displayName))
                    .cornerRadius(5)
                }
                .frame(height: 200)
            }
            
            // Legend
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.sm) {
                ForEach(viewModel.categoryValues.prefix(6)) { data in
                    HStack(spacing: AppSpacing.xs) {
                        Circle()
                            .fill(colorForCategory(data.category))
                            .frame(width: 8, height: 8)
                        
                        Text(data.category.displayName)
                            .textStyle(.labelSmall)
                            .foregroundStyle(AppColors.textSecondary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(data.percentage)
                            .textStyle(.labelSmall)
                            .foregroundStyle(AppColors.textPrimary)
                    }
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.large)
    }
    
    private var mostValuableItemsCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Most Valuable Items")
                .textStyle(.headlineMedium)
                .foregroundStyle(AppColors.textPrimary)
            
            VStack(spacing: AppSpacing.sm) {
                ForEach(viewModel.mostValuableItems.prefix(5)) { item in
                    HStack {
                        Image(systemName: item.category.icon)
                            .font(.title3)
                            .foregroundStyle(AppColors.primary)
                            .frame(width: 32, height: 32)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .textStyle(.bodyMedium)
                                .foregroundStyle(AppColors.textPrimary)
                                .lineLimit(1)
                            
                            if let brand = item.brand {
                                Text(brand)
                                    .textStyle(.labelSmall)
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            if let value = item.value {
                                Text(value, format: .currency(code: viewModel.currency))
                                    .textStyle(.bodyMedium)
                                    .foregroundStyle(AppColors.textPrimary)
                            }
                            
                            if let purchasePrice = item.purchasePrice,
                               let currentValue = item.value {
                                let change = currentValue - purchasePrice
                                Text("\(change >= 0 ? "+" : "")\(change.formatted(.currency(code: viewModel.currency)))")
                                    .textStyle(.labelSmall)
                                    .foregroundStyle(change >= 0 ? .green : .red)
                            }
                        }
                    }
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.large)
    }
    
    private var depreciationCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Depreciation Insights")
                .textStyle(.headlineMedium)
                .foregroundStyle(AppColors.textPrimary)
            
            VStack(spacing: AppSpacing.md) {
                DepreciationRow(
                    category: "Electronics",
                    rate: "-18%",
                    annualLoss: "$2,340",
                    icon: "tv"
                )
                
                DepreciationRow(
                    category: "Furniture",
                    rate: "-12%",
                    annualLoss: "$890",
                    icon: "sofa"
                )
                
                DepreciationRow(
                    category: "Appliances",
                    rate: "-15%",
                    annualLoss: "$1,250",
                    icon: "washer"
                )
            }
            
            Text("Based on typical depreciation rates for each category")
                .textStyle(.labelSmall)
                .foregroundStyle(AppColors.textTertiary)
        }
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.large)
    }
    
    private func colorForCategory(_ category: ItemCategory) -> Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .red, .pink, .yellow, .cyan]
        let index = ItemCategory.allCases.firstIndex(of: category) ?? 0
        return colors[index % colors.count]
    }
}

// MARK: - Supporting Views

private struct ValueMetric: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AppColors.primary)
            
            Text(value)
                .textStyle(.bodyLarge)
                .foregroundStyle(AppColors.textPrimary)
            
            Text(label)
                .textStyle(.labelSmall)
                .foregroundStyle(AppColors.textSecondary)
        }
    }
}

private struct StatRow: View {
    let label: String
    let value: String
    let date: Date?
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.1))
                .cornerRadius(AppCornerRadius.small)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .textStyle(.labelMedium)
                    .foregroundStyle(AppColors.textSecondary)
                
                if let date = date {
                    Text(date, style: .date)
                        .textStyle(.labelSmall)
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
            
            Spacer()
            
            Text(value)
                .textStyle(.bodyLarge)
                .foregroundStyle(AppColors.textPrimary)
        }
    }
}

private struct DepreciationRow: View {
    let category: String
    let rate: String
    let annualLoss: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AppColors.warning)
                .frame(width: 36, height: 36)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(category)
                    .textStyle(.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
                
                Text("\(rate) annually")
                    .textStyle(.labelSmall)
                    .foregroundStyle(AppColors.textSecondary)
            }
            
            Spacer()
            
            Text(annualLoss)
                .textStyle(.bodyMedium)
                .foregroundStyle(AppColors.warning)
        }
    }
}

// MARK: - Portfolio Breakdown View

private struct PortfolioBreakdownView: View {
    let viewModel: PortfolioValueViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.categoryValues) { data in
                    HStack {
                        Image(systemName: data.category.icon)
                            .font(.title3)
                            .foregroundStyle(AppColors.primary)
                            .frame(width: 44, height: 44)
                            .background(AppColors.primaryMuted)
                            .cornerRadius(AppCornerRadius.small)
                        
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text(data.category.displayName)
                                .textStyle(.bodyLarge)
                                .foregroundStyle(AppColors.textPrimary)
                            
                            Text("\(data.itemCount) items • \(data.percentage)")
                                .textStyle(.labelSmall)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                            Text(data.value, format: .currency(code: "USD"))
                                .textStyle(.bodyLarge)
                                .foregroundStyle(AppColors.textPrimary)
                            
                            if data.valueChange != 0 {
                                Text("\(data.valueChange >= 0 ? "+" : "")\(data.valueChange.formatted(.currency(code: "USD")))")
                                    .textStyle(.labelSmall)
                                    .foregroundStyle(data.valueChange >= 0 ? .green : .red)
                            }
                        }
                    }
                    .padding(.vertical, AppSpacing.xs)
                    .listRowBackground(AppColors.surface)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .navigationTitle("Portfolio Breakdown")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}