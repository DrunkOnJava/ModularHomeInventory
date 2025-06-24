import SwiftUI
import Core
import SharedUI
import Charts

/// Main view for displaying retailer analytics
/// Swift 5.9 - No Swift 6 features
struct RetailerAnalyticsView: View {
    @StateObject private var viewModel: RetailerAnalyticsViewModel
    @State private var selectedMetric: Core.RankingMetric = .totalSpent
    @State private var selectedStore: Core.RetailerAnalytics?
    @State private var showingStoreDetail = false
    @State private var selectedTimeRange = TimeRange.allTime
    
    init(
        itemRepository: any ItemRepository,
        receiptRepository: (any ReceiptRepository)? = nil
    ) {
        self._viewModel = StateObject(wrappedValue: RetailerAnalyticsViewModel(
            itemRepository: itemRepository,
            receiptRepository: receiptRepository
        ))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Insights Summary
                    if let insights = viewModel.insights {
                        InsightsSummaryCard(insights: insights)
                    }
                    
                    // Time Range Picker
                    TimeRangePicker(selection: $selectedTimeRange)
                        .onChange(of: selectedTimeRange) { _ in
                            Task {
                                await viewModel.loadAnalytics()
                            }
                        }
                    
                    // Top Stores Chart
                    if !viewModel.analytics.isEmpty {
                        TopStoresChart(
                            analytics: Array(viewModel.analytics.prefix(5)),
                            onSelectStore: { store in
                                selectedStore = viewModel.analytics.first { $0.storeName == store }
                                showingStoreDetail = true
                            }
                        )
                    }
                    
                    // Ranking Metrics
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Store Rankings")
                            .font(.headline)
                        
                        // Metric Selector
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Core.RankingMetric.allCases, id: \.self) { metric in
                                    MetricChip(
                                        metric: metric,
                                        isSelected: selectedMetric == metric,
                                        onTap: {
                                            selectedMetric = metric
                                            Task {
                                                await viewModel.loadRankings(for: metric)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        
                        // Rankings List
                        if !viewModel.rankings.isEmpty {
                            RankingsList(rankings: viewModel.rankings)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Category Leaders
                    if let insights = viewModel.insights, !insights.categoryLeaders.isEmpty {
                        CategoryLeadersSection(leaders: insights.categoryLeaders)
                    }
                    
                    // Spending Comparison
                    if !viewModel.spendingComparison.isEmpty {
                        SpendingComparisonChart(comparison: viewModel.spendingComparison)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Retailer Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await viewModel.loadAnalytics()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(item: $selectedStore) { store in
                StoreDetailView(
                    analytics: store,
                    itemRepository: viewModel.itemRepository
                )
            }
            .task {
                await viewModel.loadAnalytics()
                await viewModel.loadRankings(for: selectedMetric)
            }
        }
    }
}

// MARK: - Insights Summary Card
struct InsightsSummaryCard: View {
    let insights: Core.RetailerInsights
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Retailer Insights")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                InsightItem(
                    title: "Total Stores",
                    value: "\(insights.totalStores)",
                    icon: "building.2",
                    color: AppColors.primary
                )
                
                InsightItem(
                    title: "Total Spent",
                    value: "$\(insights.totalSpentAllStores.formatted())",
                    icon: "dollarsign.circle.fill",
                    color: .green
                )
                
                if let favorite = insights.favoriteStore {
                    InsightItem(
                        title: "Favorite Store",
                        value: favorite,
                        icon: "heart.fill",
                        color: .red
                    )
                }
                
                if let frequent = insights.mostFrequentStore {
                    InsightItem(
                        title: "Most Frequent",
                        value: frequent,
                        icon: "clock.fill",
                        color: .orange
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

struct InsightItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.system(size: 20))
                Spacer()
            }
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(12)
    }
}

// MARK: - Time Range Picker
enum TimeRange: String, CaseIterable {
    case lastMonth = "Last Month"
    case last3Months = "Last 3 Months"
    case last6Months = "Last 6 Months"
    case lastYear = "Last Year"
    case allTime = "All Time"
    
    var dateInterval: DateInterval? {
        let now = Date()
        let calendar = Calendar.current
        
        switch self {
        case .lastMonth:
            let start = calendar.date(byAdding: .month, value: -1, to: now)!
            return DateInterval(start: start, end: now)
        case .last3Months:
            let start = calendar.date(byAdding: .month, value: -3, to: now)!
            return DateInterval(start: start, end: now)
        case .last6Months:
            let start = calendar.date(byAdding: .month, value: -6, to: now)!
            return DateInterval(start: start, end: now)
        case .lastYear:
            let start = calendar.date(byAdding: .year, value: -1, to: now)!
            return DateInterval(start: start, end: now)
        case .allTime:
            return nil
        }
    }
}

struct TimeRangePicker: View {
    @Binding var selection: TimeRange
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Button(action: {
                        selection = range
                    }) {
                        Text(range.rawValue)
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selection == range ? AppColors.primary : Color(.systemGray5))
                            .foregroundStyle(selection == range ? .white : .primary)
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Top Stores Chart
struct TopStoresChart: View {
    let analytics: [Core.RetailerAnalytics]
    let onSelectStore: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Stores by Spending")
                .font(.headline)
                .padding(.horizontal)
            
            Chart(analytics) { store in
                BarMark(
                    x: .value("Store", store.storeName),
                    y: .value("Amount", NSDecimalNumber(decimal: store.totalSpent).doubleValue)
                )
                .foregroundStyle(AppColors.primary)
                .cornerRadius(8)
            }
            .frame(height: 200)
            .padding(.horizontal)
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
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
            .onTapGesture { location in
                // Simple tap detection - in real app would calculate which bar was tapped
                if let firstStore = analytics.first {
                    onSelectStore(firstStore.storeName)
                }
            }
        }
        .padding(.vertical)
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Metric Chip
struct MetricChip: View {
    let metric: Core.RankingMetric
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: metric.icon)
                    .font(.system(size: 14))
                Text(metric.rawValue)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? AppColors.primary : Color(.systemGray5))
            .foregroundStyle(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

// MARK: - Rankings List
struct RankingsList: View {
    let rankings: [Core.StoreRanking]
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(rankings.prefix(10).enumerated()), id: \.element.id) { index, ranking in
                HStack {
                    // Rank
                    Text("#\(ranking.rank)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(rankColor(for: ranking.rank))
                        .frame(width: 30)
                    
                    // Store Name
                    Text(ranking.storeName)
                        .font(.system(size: 15, weight: .medium))
                    
                    Spacer()
                    
                    // Value
                    Text(formattedValue(ranking.value, metric: ranking.metric))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal)
                
                if index < rankings.count - 1 {
                    Divider()
                        .padding(.horizontal)
                }
            }
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    func rankColor(for rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return Color(.systemGray2)
        case 3: return .orange
        default: return .secondary
        }
    }
    
    func formattedValue(_ value: Decimal, metric: Core.RankingMetric) -> String {
        switch metric {
        case .totalSpent, .averageTransaction:
            return value.asCurrency()
        case .itemCount:
            return "\(Int(truncating: NSDecimalNumber(decimal: value))) items"
        case .frequency:
            let score = Int(truncating: NSDecimalNumber(decimal: value))
            switch score {
            case 1: return "Daily"
            case 2: return "Weekly"
            case 3: return "Monthly"
            case 4: return "Occasional"
            default: return "Rare"
            }
        }
    }
}

// MARK: - Category Leaders Section
struct CategoryLeadersSection: View {
    let leaders: [Core.CategoryLeader]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Best Stores by Category")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(leaders) { leader in
                        CategoryLeaderCard(leader: leader)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct CategoryLeaderCard: View {
    let leader: Core.CategoryLeader
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: leader.category.icon)
                .font(.system(size: 24))
                .foregroundStyle(Color(hex: leader.category.color))
            
            Text(leader.category.rawValue)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(leader.storeName)
                .font(.system(size: 15, weight: .semibold))
                .lineLimit(1)
            
            HStack(spacing: 4) {
                Text("\(leader.itemCount)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                Text("items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text("~\(leader.averagePrice.asCurrency())")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(width: 140)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Spending Comparison Chart
struct SpendingComparisonChart: View {
    let comparison: [(store: String, amount: Decimal, percentage: Double)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending Distribution")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                ForEach(Array(comparison.prefix(5).enumerated()), id: \.offset) { index, item in
                    SpendingBar(
                        store: item.store,
                        amount: item.amount,
                        percentage: item.percentage,
                        color: barColor(for: index)
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    func barColor(for index: Int) -> Color {
        let colors: [Color] = [
            AppColors.primary,
            .blue,
            .green,
            .orange,
            .purple
        ]
        return colors[index % colors.count]
    }
}

struct SpendingBar: View {
    let store: String
    let amount: Decimal
    let percentage: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(store)
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                Text("$\(amount.formatted())")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 20)
                        .cornerRadius(10)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(percentage / 100), height: 20)
                        .cornerRadius(10)
                    
                    Text("\(Int(percentage))%")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                }
            }
            .frame(height: 20)
        }
    }
}

// MARK: - View Model
@MainActor
final class RetailerAnalyticsViewModel: ObservableObject {
    @Published var analytics: [Core.RetailerAnalytics] = []
    @Published var insights: Core.RetailerInsights?
    @Published var rankings: [Core.StoreRanking] = []
    @Published var spendingComparison: [(store: String, amount: Decimal, percentage: Double)] = []
    @Published var isLoading = false
    
    let itemRepository: any ItemRepository
    private let analyticsService: Core.RetailerAnalyticsService
    
    init(
        itemRepository: any ItemRepository,
        receiptRepository: (any ReceiptRepository)? = nil
    ) {
        self.itemRepository = itemRepository
        self.analyticsService = Core.RetailerAnalyticsService(
            itemRepository: itemRepository,
            receiptRepository: receiptRepository
        )
    }
    
    func loadAnalytics() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Load retailer analytics
            analytics = try await analyticsService.calculateAllRetailerAnalytics()
            
            // Load insights
            insights = try await analyticsService.getRetailerInsights()
            
            // Load spending comparison
            spendingComparison = try await analyticsService.getSpendingComparison()
        } catch {
            print("Error loading analytics: \(error)")
        }
    }
    
    func loadRankings(for metric: Core.RankingMetric) async {
        do {
            rankings = try await analyticsService.getStoreRankings(metric: metric)
        } catch {
            print("Error loading rankings: \(error)")
        }
    }
}