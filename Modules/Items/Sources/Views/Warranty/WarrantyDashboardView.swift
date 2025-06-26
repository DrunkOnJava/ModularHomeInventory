//
//  WarrantyDashboardView.swift
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
//  Dependencies: SwiftUI, Core, SharedUI, Charts
//  Testing: ItemsTests/WarrantyDashboardViewTests.swift
//
//  Description: Dashboard view for warranty overview and analytics
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core
import SharedUI
import Charts

/// Dashboard view for warranty overview
/// Swift 5.9 - No Swift 6 features
struct WarrantyDashboardView: View {
    @StateObject private var viewModel: WarrantyDashboardViewModel
    @State private var selectedTimeframe = TimeFrame.thisYear
    @State private var showingNotificationSettings = false
    
    init(
        warrantyRepository: any WarrantyRepository,
        itemRepository: any ItemRepository
    ) {
        self._viewModel = StateObject(wrappedValue: WarrantyDashboardViewModel(
            warrantyRepository: warrantyRepository,
            itemRepository: itemRepository
        ))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Summary Cards
                summarySection
                
                // Expiration Timeline Chart
                if !viewModel.expirationData.isEmpty {
                    expirationChartSection
                }
                
                // Warranty Status Breakdown
                statusBreakdownSection
                
                // Upcoming Expirations List
                if !viewModel.upcomingExpirations.isEmpty {
                    upcomingExpirationsSection
                }
                
                // Coverage by Category
                if !viewModel.categoryData.isEmpty {
                    categoryBreakdownSection
                }
            }
            .appPadding()
        }
        .background(AppColors.background)
        .navigationTitle("Warranty Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingNotificationSettings = true }) {
                    Image(systemName: "bell")
                }
            }
        }
        .sheet(isPresented: $showingNotificationSettings) {
            NavigationView {
                WarrantyNotificationsView(
                    warrantyRepository: viewModel.warrantyRepository,
                    itemRepository: viewModel.itemRepository
                )
            }
        }
        .task {
            await viewModel.loadData()
        }
    }
    
    // MARK: - Sections
    
    private var summarySection: some View {
        VStack(spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.md) {
                SummaryCard(
                    title: "Active",
                    value: "\(viewModel.activeCount)",
                    icon: "checkmark.shield",
                    color: .green
                )
                
                SummaryCard(
                    title: "Expiring Soon",
                    value: "\(viewModel.expiringSoonCount)",
                    icon: "exclamationmark.shield",
                    color: .orange
                )
            }
            
            HStack(spacing: AppSpacing.md) {
                SummaryCard(
                    title: "Expired",
                    value: "\(viewModel.expiredCount)",
                    icon: "xmark.shield",
                    color: .red
                )
                
                SummaryCard(
                    title: "Total Value",
                    value: viewModel.totalValue.formatted(.currency(code: "USD")),
                    icon: "dollarsign.circle",
                    color: AppColors.primary
                )
            }
        }
    }
    
    private var expirationChartSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Expiration Timeline")
                    .textStyle(.headlineMedium)
                
                Spacer()
                
                Picker("Timeframe", selection: $selectedTimeframe) {
                    ForEach(TimeFrame.allCases) { timeframe in
                        Text(timeframe.rawValue).tag(timeframe)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedTimeframe) { _ in
                    Task { await viewModel.loadData(timeframe: selectedTimeframe) }
                }
            }
            
            Chart(viewModel.expirationData) { data in
                BarMark(
                    x: .value("Month", data.month, unit: .month),
                    y: .value("Count", data.count)
                )
                .foregroundStyle(data.isExpired ? Color.red : AppColors.primary)
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                }
            }
        }
        .appPadding()
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.medium)
    }
    
    private var statusBreakdownSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Status Breakdown")
                .textStyle(.headlineMedium)
            
            VStack(spacing: AppSpacing.sm) {
                StatusRow(
                    status: "Active",
                    count: viewModel.activeCount,
                    total: viewModel.totalCount,
                    color: .green
                )
                
                StatusRow(
                    status: "Expiring Soon",
                    count: viewModel.expiringSoonCount,
                    total: viewModel.totalCount,
                    color: .orange
                )
                
                StatusRow(
                    status: "Expired",
                    count: viewModel.expiredCount,
                    total: viewModel.totalCount,
                    color: .red
                )
            }
        }
        .appPadding()
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.medium)
    }
    
    private var upcomingExpirationsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Upcoming Expirations")
                    .textStyle(.headlineMedium)
                
                Spacer()
                
                Text("\(viewModel.upcomingExpirations.count)")
                    .textStyle(.labelMedium)
                    .foregroundStyle(AppColors.textSecondary)
            }
            
            VStack(spacing: AppSpacing.sm) {
                ForEach(viewModel.upcomingExpirations.prefix(5)) { warranty in
                    if let item = viewModel.items[warranty.itemId] {
                        UpcomingExpirationRow(warranty: warranty, item: item)
                    }
                }
            }
            
            if viewModel.upcomingExpirations.count > 5 {
                Button(action: {
                    // Navigate to full list
                }) {
                    Text("View All (\(viewModel.upcomingExpirations.count))")
                        .textStyle(.labelMedium)
                        .foregroundStyle(AppColors.primary)
                }
            }
        }
        .appPadding()
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.medium)
    }
    
    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Coverage by Category")
                .textStyle(.headlineMedium)
            
            Chart(viewModel.categoryData) { data in
                SectorMark(
                    angle: .value("Count", data.count),
                    innerRadius: .ratio(0.6),
                    angularInset: 2
                )
                .foregroundStyle(by: .value("Category", data.category))
                .cornerRadius(4)
            }
            .frame(height: 250)
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    let frame = geometry.frame(in: .local)
                    VStack {
                        Text("\(viewModel.totalCount)")
                            .textStyle(.headlineLarge)
                        Text("Total")
                            .textStyle(.bodySmall)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .position(x: frame.midX, y: frame.midY)
                }
            }
            
            // Legend
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.sm) {
                ForEach(viewModel.categoryData) { data in
                    HStack(spacing: AppSpacing.xs) {
                        Circle()
                            .fill(categoryColor(for: data.category))
                            .frame(width: 12, height: 12)
                        
                        Text(data.category)
                            .textStyle(.labelSmall)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text("\(data.count)")
                            .textStyle(.labelSmall)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }
        }
        .appPadding()
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.medium)
    }
    
    private func categoryColor(for category: String) -> Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .yellow]
        let index = abs(category.hashValue) % colors.count
        return colors[index]
    }
}

// MARK: - Supporting Views

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                Spacer()
            }
            
            Text(value)
                .textStyle(.headlineLarge)
                .foregroundStyle(AppColors.textPrimary)
            
            Text(title)
                .textStyle(.bodySmall)
                .foregroundStyle(AppColors.textSecondary)
        }
        .appPadding()
        .frame(maxWidth: .infinity)
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.medium)
    }
}

struct StatusRow: View {
    let status: String
    let count: Int
    let total: Int
    let color: Color
    
    private var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(count) / Double(total)
    }
    
    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                
                Text(status)
                    .textStyle(.bodyMedium)
                
                Spacer()
                
                Text("\(count)")
                    .textStyle(.labelMedium)
                    .foregroundStyle(AppColors.textSecondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppColors.secondaryBackground)
                        .frame(height: 4)
                    
                    Capsule()
                        .fill(color)
                        .frame(width: geometry.size.width * percentage, height: 4)
                }
            }
            .frame(height: 4)
        }
    }
}

struct UpcomingExpirationRow: View {
    let warranty: Warranty
    let item: Item
    
    private var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: warranty.endDate).day ?? 0
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(item.name)
                    .textStyle(.bodyMedium)
                    .lineLimit(1)
                
                Text(warranty.provider)
                    .textStyle(.labelSmall)
                    .foregroundStyle(AppColors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: AppSpacing.xxs) {
                Text("\(daysRemaining) days")
                    .textStyle(.labelMedium)
                    .foregroundStyle(daysRemaining <= 30 ? .orange : AppColors.textPrimary)
                
                Text(warranty.endDate, style: .date)
                    .textStyle(.labelSmall)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .appPadding(.vertical, AppSpacing.xs)
    }
}

// MARK: - View Model

@MainActor
final class WarrantyDashboardViewModel: ObservableObject {
    @Published var activeCount = 0
    @Published var expiringSoonCount = 0
    @Published var expiredCount = 0
    @Published var totalCount = 0
    @Published var totalValue: Decimal = 0
    @Published var upcomingExpirations: [Warranty] = []
    @Published var expirationData: [ExpirationData] = []
    @Published var categoryData: [CategoryData] = []
    @Published var items: [UUID: Item] = [:]
    
    let warrantyRepository: any WarrantyRepository
    let itemRepository: any ItemRepository
    
    init(
        warrantyRepository: any WarrantyRepository,
        itemRepository: any ItemRepository
    ) {
        self.warrantyRepository = warrantyRepository
        self.itemRepository = itemRepository
    }
    
    func loadData(timeframe: TimeFrame = .thisYear) async {
        do {
            // Load all warranties and items
            let warranties = try await warrantyRepository.fetchAll()
            let allItems = try await itemRepository.fetchAll()
            
            // Create items dictionary
            items = Dictionary(uniqueKeysWithValues: allItems.map { ($0.id, $0) })
            
            // Calculate counts
            let now = Date()
            activeCount = warranties.filter { warranty in
                if case Warranty.Status.active = warranty.status {
                    return true
                }
                return false
            }.count
            expiringSoonCount = warranties.filter { warranty in
                if case .expiringSoon = warranty.status {
                    return true
                }
                return false
            }.count
            expiredCount = warranties.filter { warranty in
                if case Warranty.Status.expired = warranty.status {
                    return true
                }
                return false
            }.count
            totalCount = warranties.count
            
            // Calculate total value of items with warranties
            totalValue = warranties.compactMap { warranty in
                items[warranty.itemId]?.value
            }.reduce(0, +)
            
            // Get upcoming expirations (next 90 days)
            let ninetyDaysFromNow = Calendar.current.date(byAdding: .day, value: 90, to: now)!
            upcomingExpirations = warranties
                .filter { $0.endDate > now && $0.endDate <= ninetyDaysFromNow }
                .sorted { $0.endDate < $1.endDate }
            
            // Generate expiration timeline data
            expirationData = generateExpirationData(warranties: warranties, timeframe: timeframe)
            
            // Generate category breakdown
            categoryData = generateCategoryData(warranties: warranties, items: allItems)
            
        } catch {
            print("Error loading warranty dashboard data: \(error)")
        }
    }
    
    private func generateExpirationData(warranties: [Warranty], timeframe: TimeFrame) -> [ExpirationData] {
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date
        let endDate: Date
        
        switch timeframe {
        case .thisMonth:
            startDate = calendar.dateInterval(of: .month, for: now)?.start ?? now
            endDate = calendar.dateInterval(of: .month, for: now)?.end ?? now
        case .thisQuarter:
            startDate = calendar.dateInterval(of: .quarter, for: now)?.start ?? now
            endDate = calendar.dateInterval(of: .quarter, for: now)?.end ?? now
        case .thisYear:
            startDate = calendar.dateInterval(of: .year, for: now)?.start ?? now
            endDate = calendar.dateInterval(of: .year, for: now)?.end ?? now
        }
        
        // Group warranties by month
        var dataByMonth: [Date: (expired: Int, expiring: Int)] = [:]
        
        for warranty in warranties {
            if warranty.endDate >= startDate && warranty.endDate <= endDate {
                let monthStart = calendar.dateInterval(of: .month, for: warranty.endDate)?.start ?? warranty.endDate
                var counts = dataByMonth[monthStart] ?? (0, 0)
                
                if warranty.endDate < now {
                    counts.expired += 1
                } else {
                    counts.expiring += 1
                }
                
                dataByMonth[monthStart] = counts
            }
        }
        
        // Convert to array
        return dataByMonth.flatMap { (month, counts) in
            var result: [ExpirationData] = []
            
            if counts.expired > 0 {
                result.append(ExpirationData(month: month, count: counts.expired, isExpired: true))
            }
            
            if counts.expiring > 0 {
                result.append(ExpirationData(month: month, count: counts.expiring, isExpired: false))
            }
            
            return result
        }.sorted { $0.month < $1.month }
    }
    
    private func generateCategoryData(warranties: [Warranty], items: [Item]) -> [CategoryData] {
        var categoryCounts: [String: Int] = [:]
        
        for warranty in warranties {
            if let item = items.first(where: { $0.id == warranty.itemId }) {
                let category = item.category.displayName
                categoryCounts[category] = (categoryCounts[category] ?? 0) + 1
            }
        }
        
        return categoryCounts.map { CategoryData(category: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
}

// MARK: - Data Models

struct ExpirationData: Identifiable {
    let id = UUID()
    let month: Date
    let count: Int
    let isExpired: Bool
}

struct CategoryData: Identifiable {
    let id = UUID()
    let category: String
    let count: Int
}

enum TimeFrame: String, CaseIterable, Identifiable {
    case thisMonth = "This Month"
    case thisQuarter = "This Quarter"
    case thisYear = "This Year"
    
    var id: String { rawValue }
}