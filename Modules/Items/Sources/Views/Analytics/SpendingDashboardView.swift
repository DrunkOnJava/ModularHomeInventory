import SwiftUI
import Core
import SharedUI
import Charts

/// Spending Dashboard view showing visual spending overview
/// Swift 5.9 - No Swift 6 features
struct SpendingDashboardView: View {
    @StateObject private var viewModel: SpendingDashboardViewModel
    @State private var selectedTimeRange: TimeRange = .month
    @State private var showingCategoryDetail = false
    @State private var selectedCategory: ItemCategory?
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "Quarter"
        case year = "Year"
        case all = "All Time"
        
        var displayName: String { rawValue }
    }
    
    init(viewModel: SpendingDashboardViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Time range selector
                timeRangePicker
                
                // Total spending card
                totalSpendingCard
                
                // Spending chart
                spendingChartCard
                
                // Category breakdown
                categoryBreakdownCard
                
                // Recent purchases
                recentPurchasesCard
                
                // Top retailers
                topRetailersCard
                
                // Portfolio value link
                portfolioValueLink
                
                // Time analysis link
                timeAnalysisLink
                
                // Depreciation report link
                depreciationReportLink
                
                // Purchase patterns link
                purchasePatternsLink
                
                // Budget tracking link
                budgetTrackingLink
                
                // Warranty dashboard link
                warrantyDashboardLink
            }
            .padding(AppSpacing.md)
        }
        .background(AppColors.background)
        .navigationTitle("Spending Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            Task {
                await viewModel.loadData(for: selectedTimeRange)
            }
        }
        .sheet(isPresented: $showingCategoryDetail) {
            if let category = selectedCategory {
                CategorySpendingDetailView(
                    category: category,
                    timeRange: selectedTimeRange,
                    items: viewModel.getItems(for: category)
                )
            }
        }
    }
    
    // MARK: - Components
    
    private var timeRangePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(TimeRange.allCases, id: \.self) { range in
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
    
    private var totalSpendingCard: some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Total Spent")
                        .textStyle(.labelMedium)
                        .foregroundStyle(AppColors.textSecondary)
                    
                    Text(viewModel.totalSpent, format: .currency(code: viewModel.currency))
                        .textStyle(.headlineLarge)
                        .foregroundStyle(AppColors.textPrimary)
                }
                
                Spacer()
                
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(AppColors.primary)
            }
            
            HStack(spacing: AppSpacing.xl) {
                StatItem(
                    label: "Items",
                    value: "\(viewModel.itemCount)",
                    icon: "shippingbox"
                )
                
                StatItem(
                    label: "Avg. Price",
                    value: viewModel.averagePrice.formatted(.currency(code: viewModel.currency)),
                    icon: "chart.line.uptrend.xyaxis"
                )
                
                StatItem(
                    label: "Categories",
                    value: "\(viewModel.categoryCount)",
                    icon: "square.grid.2x2"
                )
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.large)
    }
    
    private var spendingChartCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Spending Over Time")
                .textStyle(.headlineMedium)
                .foregroundStyle(AppColors.textPrimary)
            
            Chart(viewModel.spendingData) { dataPoint in
                BarMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Amount", dataPoint.amount)
                )
                .foregroundStyle(AppColors.primary)
            }
            .frame(height: 200)
        }
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.large)
    }
    
    private var categoryBreakdownCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("By Category")
                    .textStyle(.headlineMedium)
                    .foregroundStyle(AppColors.textPrimary)
                
                Spacer()
                
                NavigationLink(destination: CategoryAnalyticsView(
                    viewModel: CategoryAnalyticsViewModel(itemRepository: viewModel.itemRepository)
                )) {
                    Text("See All")
                        .foregroundStyle(AppColors.primary)
                        .textStyle(.labelMedium)
                }
            }
            
            VStack(spacing: AppSpacing.sm) {
                ForEach(viewModel.topCategories.prefix(5)) { categoryData in
                    CategoryRow(
                        data: categoryData,
                        totalSpent: viewModel.totalSpent
                    ) {
                        selectedCategory = categoryData.category
                        showingCategoryDetail = true
                    }
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.large)
    }
    
    private var recentPurchasesCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Recent Purchases")
                .textStyle(.headlineMedium)
                .foregroundStyle(AppColors.textPrimary)
            
            VStack(spacing: AppSpacing.sm) {
                ForEach(viewModel.recentPurchases.prefix(5)) { item in
                    HStack {
                        Image(systemName: item.category.icon)
                            .font(.title3)
                            .foregroundStyle(AppColors.primary)
                            .frame(width: 32, height: 32)
                        
                        VStack(alignment: .leading, spacing: 2) {
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
                            Text(price, format: .currency(code: viewModel.currency))
                                .textStyle(.bodyMedium)
                                .foregroundStyle(AppColors.textPrimary)
                        }
                    }
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.large)
    }
    
    private var topRetailersCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Top Stores")
                    .textStyle(.headlineMedium)
                    .foregroundStyle(AppColors.textPrimary)
                
                Spacer()
                
                NavigationLink(destination: RetailerAnalyticsView(
                    itemRepository: viewModel.itemRepository,
                    receiptRepository: viewModel.receiptRepository
                )) {
                    Text("View All")
                        .textStyle(.labelMedium)
                        .foregroundStyle(AppColors.primary)
                }
            }
            
            VStack(spacing: AppSpacing.sm) {
                ForEach(viewModel.topRetailers.prefix(5)) { retailerData in
                    HStack {
                        Text(retailerData.name)
                            .textStyle(.bodyMedium)
                            .foregroundStyle(AppColors.textPrimary)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(retailerData.totalSpent, format: .currency(code: viewModel.currency))
                                .textStyle(.bodyMedium)
                                .foregroundStyle(AppColors.textPrimary)
                            
                            Text("\(retailerData.itemCount) items")
                                .textStyle(.labelSmall)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.large)
    }
    
    private var portfolioValueLink: some View {
        NavigationLink(destination: PortfolioValueView(
            viewModel: PortfolioValueViewModel(itemRepository: viewModel.itemRepository)
        )) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(AppColors.primary)
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Portfolio Value Tracking")
                        .textStyle(.headlineMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Text("Track your inventory value over time")
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16))
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding(AppSpacing.lg)
            .background(AppColors.surface)
            .cornerRadius(AppCornerRadius.large)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var timeAnalysisLink: some View {
        NavigationLink(destination: TimeBasedAnalyticsView(
            itemRepository: viewModel.itemRepository
        )) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: "calendar.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(AppColors.primary)
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Time-based Analysis")
                        .textStyle(.headlineMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Text("Analyze spending trends over time")
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16))
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding(AppSpacing.lg)
            .background(AppColors.surface)
            .cornerRadius(AppCornerRadius.large)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var depreciationReportLink: some View {
        NavigationLink(destination: DepreciationReportView(
            itemRepository: viewModel.itemRepository
        )) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: "chart.line.downtrend.xyaxis.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(AppColors.primary)
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Depreciation Report")
                        .textStyle(.headlineMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Text("Track asset value depreciation")
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16))
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding(AppSpacing.lg)
            .background(AppColors.surface)
            .cornerRadius(AppCornerRadius.large)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var purchasePatternsLink: some View {
        NavigationLink(destination: PurchasePatternsView(
            itemRepository: viewModel.itemRepository
        )) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 44))
                    .foregroundStyle(AppColors.primary)
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Purchase Patterns")
                        .textStyle(.headlineMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Text("Identify buying habits and trends")
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16))
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding(AppSpacing.lg)
            .background(AppColors.surface)
            .cornerRadius(AppCornerRadius.large)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private var budgetTrackingLink: some View {
        if let budgetRepository = viewModel.budgetRepository {
            NavigationLink(destination: BudgetDashboardView(
                budgetRepository: budgetRepository,
                itemRepository: viewModel.itemRepository
            )) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(AppColors.primary)
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Budget Tracking")
                        .textStyle(.headlineMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Text("Set and monitor spending budgets")
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16))
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding(AppSpacing.lg)
            .background(AppColors.surface)
            .cornerRadius(AppCornerRadius.large)
        }
        .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var warrantyDashboardLink: some View {
        NavigationLink(destination: WarrantyDashboardView(
            warrantyRepository: viewModel.warrantyRepository,
            itemRepository: viewModel.itemRepository
        )) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 44))
                    .foregroundStyle(AppColors.primary)
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Warranty Dashboard")
                        .textStyle(.headlineMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Text("Track warranty expirations and alerts")
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16))
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding(AppSpacing.lg)
            .background(AppColors.surface)
            .cornerRadius(AppCornerRadius.large)
        }
        .buttonStyle(PlainButtonStyle())
    }

// MARK: - Supporting Views

private struct StatItem: View {
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

private struct CategoryRow: View {
    let data: CategorySpendingData
    let totalSpent: Decimal
    let action: () -> Void
    
    private var percentage: Double {
        guard totalSpent > 0 else { return 0 }
        return Double(truncating: (data.totalSpent / totalSpent * 100) as NSNumber)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: AppSpacing.xs) {
                HStack {
                    Label(data.category.displayName, systemImage: data.category.icon)
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Spacer()
                    
                    Text(data.totalSpent, format: .currency(code: "USD"))
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.textPrimary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(AppColors.divider)
                            .frame(height: 4)
                        
                        Rectangle()
                            .fill(AppColors.primary)
                            .frame(width: geometry.size.width * CGFloat(percentage / 100), height: 4)
                    }
                }
                .frame(height: 4)
                
                HStack {
                    Text("\(Int(percentage))%")
                        .textStyle(.labelSmall)
                        .foregroundStyle(AppColors.textSecondary)
                    
                    Spacer()
                    
                    Text("\(data.itemCount) items")
                        .textStyle(.labelSmall)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Category Detail View

private struct CategorySpendingDetailView: View {
    let category: ItemCategory
    let timeRange: SpendingDashboardView.TimeRange
    let items: [Item]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(items) { item in
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
                .listRowBackground(AppColors.surface)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .navigationTitle("\(category.displayName) Spending")
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