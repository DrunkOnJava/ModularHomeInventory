import SwiftUI
import Core
import SharedUI
import Charts

/// Purchase patterns analysis view
/// Swift 5.9 - No Swift 6 features
struct PurchasePatternsView: View {
    @StateObject private var viewModel: PurchasePatternsViewModel
    @State private var selectedPatternType = "All"
    @State private var showingPatternDetail = false
    @State private var selectedPattern: Core.PatternType?
    @State private var timeRange = 365 // Days to analyze
    
    init(itemRepository: any ItemRepository) {
        self._viewModel = StateObject(wrappedValue: PurchasePatternsViewModel(
            itemRepository: itemRepository
        ))
    }
    
    var body: some View {
        ScrollView {
                VStack(spacing: 24) {
                    // Time Range Selector
                    timeRangeSelector
                    
                    if viewModel.isLoading {
                        ProgressView("Analyzing purchase patterns...")
                            .padding(50)
                    } else if let pattern = viewModel.currentPattern {
                        // Summary Card
                        patternSummaryCard(pattern: pattern)
                        
                        // Pattern Type Filter
                        patternTypeFilter
                        
                        // Insights Section
                        if !pattern.insights.isEmpty {
                            insightsSection(insights: pattern.insights)
                        }
                        
                        // Recommendations Section
                        if !pattern.recommendations.isEmpty {
                            recommendationsSection(recommendations: pattern.recommendations)
                        }
                        
                        // Pattern Details
                        patternDetailsSection(patterns: filteredPatterns(pattern.patterns))
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Purchase Patterns")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            Task { await viewModel.refreshPatterns() }
                        }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        
                        Button(action: {
                            // Export functionality
                        }) {
                            Label("Export Report", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingPatternDetail) {
                if let pattern = selectedPattern {
                    PatternDetailView(pattern: pattern)
                }
            }
            .task {
                await viewModel.analyzePatterns(days: timeRange)
            }
    }
    
    // MARK: - Components
    
    private var timeRangeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Analysis Period")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Picker("Time Range", selection: $timeRange) {
                Text("Last 30 Days").tag(30)
                Text("Last 90 Days").tag(90)
                Text("Last 6 Months").tag(180)
                Text("Last Year").tag(365)
                Text("All Time").tag(9999)
            }
            .pickerStyle(.segmented)
            .onChange(of: timeRange) { _ in
                Task {
                    await viewModel.analyzePatterns(days: timeRange)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func patternSummaryCard(pattern: Core.PurchasePattern) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Patterns Found")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("\(pattern.patterns.count)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                }
                
                Spacer()
                
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 40))
                    .foregroundStyle(AppColors.primary.opacity(0.3))
            }
            
            HStack(spacing: 20) {
                SummaryMetric(
                    label: "Insights",
                    value: "\(pattern.insights.count)",
                    icon: "lightbulb.fill",
                    color: .yellow
                )
                
                SummaryMetric(
                    label: "Recommendations",
                    value: "\(pattern.recommendations.count)",
                    icon: "star.fill",
                    color: .orange
                )
                
                SummaryMetric(
                    label: "Period",
                    value: formatPeriod(pattern.periodAnalyzed),
                    icon: "calendar",
                    color: .blue
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private var patternTypeFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(["All", "Recurring", "Seasonal", "Category", "Brand", "Price", "Time", "Retailer", "Bulk"], id: \.self) { type in
                    Button(action: {
                        selectedPatternType = type
                    }) {
                        Text(type)
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedPatternType == type ? AppColors.primary : Color(.systemGray5))
                            .foregroundStyle(selectedPatternType == type ? .white : .primary)
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func insightsSection(insights: [Core.PatternInsight]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Insights")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                ForEach(insights) { insight in
                    PatternInsightCard(insight: insight)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func recommendationsSection(recommendations: [Core.PatternRecommendation]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recommendations")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                ForEach(recommendations) { recommendation in
                    RecommendationCard(recommendation: recommendation)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func patternDetailsSection(patterns: [Core.PatternType]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pattern Details")
                .font(.headline)
                .padding(.horizontal)
            
            if patterns.isEmpty {
                Text("No patterns found for selected filter")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(patterns, id: \.id) { pattern in
                        Button(action: {
                            selectedPattern = pattern
                            showingPatternDetail = true
                        }) {
                            PatternCard(pattern: pattern)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func filteredPatterns(_ patterns: [Core.PatternType]) -> [Core.PatternType] {
        guard selectedPatternType != "All" else { return patterns }
        
        return patterns.filter { pattern in
            switch pattern {
            case .recurring: return selectedPatternType == "Recurring"
            case .seasonal: return selectedPatternType == "Seasonal"
            case .categoryPreference: return selectedPatternType == "Category"
            case .brandLoyalty: return selectedPatternType == "Brand"
            case .priceRange: return selectedPatternType == "Price"
            case .shoppingTime: return selectedPatternType == "Time"
            case .retailerPreference: return selectedPatternType == "Retailer"
            case .bulkBuying: return selectedPatternType == "Bulk"
            }
        }
    }
    
    private func formatPeriod(_ interval: DateInterval) -> String {
        let days = Int(interval.duration / 86400)
        if days < 31 {
            return "\(days) days"
        } else if days < 365 {
            return "\(days / 30) months"
        } else {
            return "\(days / 365) year\(days > 365 ? "s" : "")"
        }
    }
}

// MARK: - Supporting Views

struct SummaryMetric: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct PatternInsightCard: View {
    let insight: Core.PatternInsight
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: insight.type.icon)
                .font(.system(size: 20))
                .foregroundStyle(Color(hex: insight.impact.color))
                .frame(width: 32, height: 32)
                .background(Color(hex: insight.impact.color).opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(insight.title)
                        .font(.system(size: 15, weight: .semibold))
                    
                    if insight.actionable {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(AppColors.primary)
                    }
                }
                
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

struct RecommendationCard: View {
    let recommendation: Core.PatternRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(recommendation.type.rawValue, systemImage: iconForType(recommendation.type))
                    .font(.caption)
                    .foregroundStyle(Color(hex: recommendation.priority.color))
                
                Spacer()
                
                if let savings = recommendation.potentialSavings {
                    Text("Save $\(savings.formatted())")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                }
            }
            
            Text(recommendation.title)
                .font(.system(size: 15, weight: .semibold))
            
            Text(recommendation.description)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            Button(action: {
                // Action based on recommendation type
            }) {
                Text("Take Action")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColors.primary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    func iconForType(_ type: Core.RecommendationType) -> String {
        switch type {
        case .bulkBuy: return "shippingbox.fill"
        case .timing: return "clock.fill"
        case .alternative: return "arrow.triangle.swap"
        case .budget: return "dollarsign.circle.fill"
        case .recurring: return "repeat"
        case .seasonal: return "calendar"
        }
    }
}

struct PatternCard: View {
    let pattern: Core.PatternType
    
    var body: some View {
        HStack {
            Image(systemName: patternIcon)
                .font(.title2)
                .foregroundStyle(patternColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(patternTitle)
                    .font(.system(size: 15, weight: .medium))
                
                Text(patternDescription)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    var patternIcon: String {
        switch pattern {
        case .recurring: return "repeat"
        case .seasonal: return "calendar"
        case .categoryPreference: return "folder"
        case .brandLoyalty: return "star"
        case .priceRange: return "dollarsign.circle"
        case .shoppingTime: return "clock"
        case .retailerPreference: return "storefront"
        case .bulkBuying: return "shippingbox"
        }
    }
    
    var patternColor: Color {
        switch pattern {
        case .recurring: return .blue
        case .seasonal: return .orange
        case .categoryPreference: return .purple
        case .brandLoyalty: return .yellow
        case .priceRange: return .green
        case .shoppingTime: return .indigo
        case .retailerPreference: return .pink
        case .bulkBuying: return .brown
        }
    }
    
    var patternTitle: String {
        switch pattern {
        case .recurring(let p): return "Recurring: \(p.itemName)"
        case .seasonal(let p): return "\(p.season.rawValue) Pattern"
        case .categoryPreference(let p): return "\(p.category.rawValue) Preference"
        case .brandLoyalty(let p): return "\(p.brand) Loyalty"
        case .priceRange(let p): return "\(p.category.rawValue) Price Range"
        case .shoppingTime(let p): return "\(p.preferredDayOfWeek) Shopping"
        case .retailerPreference(let p): return "\(p.retailer) (#\(p.loyaltyRank))"
        case .bulkBuying(let p): return "Bulk: \(p.itemType)"
        }
    }
    
    var patternDescription: String {
        switch pattern {
        case .recurring(let p): 
            return "Every \(Int(p.averageInterval)) days • \(Int(p.confidence * 100))% confidence"
        case .seasonal(let p):
            return "\(p.itemCount) items • Peak: \(p.peakMonth)"
        case .categoryPreference(let p):
            return "\(p.purchaseCount) items • \(Int(p.percentageOfTotal))% of spending"
        case .brandLoyalty(let p):
            return "\(p.purchaseCount) purchases • \(Int(p.loyaltyScore * 100))% loyalty"
        case .priceRange(let p):
            return "$\(p.minPrice.formatted()) - $\(p.maxPrice.formatted()) • Sweet spot: $\(p.sweetSpot.formatted())"
        case .shoppingTime(let p):
            return "\(p.preferredTimeOfDay.rawValue) • \(p.weekendVsWeekday.rawValue)"
        case .retailerPreference(let p):
            return "\(p.visitCount) visits • $\(p.averageBasketSize.formatted()) avg"
        case .bulkBuying(let p):
            return "Avg qty: \(p.averageQuantity) • Save $\(p.bulkSavings.formatted())"
        }
    }
}

// MARK: - Pattern Detail View

struct PatternDetailView: View {
    let pattern: Core.PatternType
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Pattern specific content
                    switch pattern {
                    case .recurring(let p):
                        RecurringPatternDetail(pattern: p)
                    case .seasonal(let p):
                        SeasonalPatternDetail(pattern: p)
                    case .categoryPreference(let p):
                        CategoryPreferenceDetail(pattern: p)
                    case .brandLoyalty(let p):
                        BrandLoyaltyDetail(pattern: p)
                    case .priceRange(let p):
                        PriceRangeDetail(pattern: p)
                    case .shoppingTime(let p):
                        ShoppingTimeDetail(pattern: p)
                    case .retailerPreference(let p):
                        RetailerPreferenceDetail(pattern: p)
                    case .bulkBuying(let p):
                        BulkBuyingDetail(pattern: p)
                    }
                }
                .padding()
            }
            .navigationTitle("Pattern Details")
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

// Pattern detail views would go here...
struct RecurringPatternDetail: View {
    let pattern: Core.RecurringPattern
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(pattern.itemName)
                .font(.title2)
                .fontWeight(.semibold)
            
            Label("\(pattern.category.rawValue)", systemImage: pattern.category.icon)
                .foregroundStyle(Color(hex: pattern.category.color))
            
            VStack(alignment: .leading, spacing: 12) {
                DetailRow(label: "Purchase Frequency", value: pattern.frequency.rawValue)
                DetailRow(label: "Average Interval", value: "\(Int(pattern.averageInterval)) days")
                DetailRow(label: "Last Purchase", value: pattern.lastPurchaseDate.formatted(date: .abbreviated, time: .omitted))
                DetailRow(label: "Next Expected", value: pattern.nextExpectedDate.formatted(date: .abbreviated, time: .omitted))
                DetailRow(label: "Confidence", value: "\(Int(pattern.confidence * 100))%")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            if pattern.nextExpectedDate < Date().addingTimeInterval(7 * 86400) {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)
                    Text("Time to restock soon!")
                        .font(.system(size: 14, weight: .medium))
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
}

struct SeasonalPatternDetail: View {
    let pattern: Core.SeasonalBuyingPattern
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: pattern.season.icon)
                    .font(.largeTitle)
                Text(pattern.season.rawValue)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                DetailRow(label: "Items Purchased", value: "\(pattern.itemCount)")
                DetailRow(label: "Average Spending", value: "$\(pattern.averageSpending.formatted())")
                DetailRow(label: "Peak Month", value: pattern.peakMonth)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            if !pattern.categories.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Popular Categories")
                        .font(.headline)
                    
                    ForEach(pattern.categories, id: \.self) { category in
                        Label(category.rawValue, systemImage: category.icon)
                            .foregroundStyle(Color(hex: category.color))
                    }
                }
            }
        }
    }
}

// Additional detail views for other pattern types...

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.system(size: 15))
    }
}

// MARK: - View Model

@MainActor
final class PurchasePatternsViewModel: ObservableObject {
    @Published var currentPattern: Core.PurchasePattern?
    @Published var isLoading = false
    
    private let patternService: Core.PurchasePatternService
    
    init(itemRepository: any ItemRepository) {
        self.patternService = Core.PurchasePatternService(itemRepository: itemRepository)
    }
    
    func analyzePatterns(days: Int) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let startDate = days < 9999 ? 
                Calendar.current.date(byAdding: .day, value: -days, to: Date()) : nil
            
            currentPattern = try await patternService.analyzePurchasePatterns(
                startDate: startDate
            )
        } catch {
            print("Error analyzing patterns: \(error)")
        }
    }
    
    func refreshPatterns() async {
        if currentPattern != nil {
            await analyzePatterns(days: 365)
        }
    }
}

// Placeholder implementations for other detail views
struct CategoryPreferenceDetail: View {
    let pattern: Core.CategoryPreference
    var body: some View { Text("Category Preference Details") }
}

struct BrandLoyaltyDetail: View {
    let pattern: Core.BrandLoyalty
    var body: some View { Text("Brand Loyalty Details") }
}

struct PriceRangeDetail: View {
    let pattern: Core.PriceRangePattern
    var body: some View { Text("Price Range Details") }
}

struct ShoppingTimeDetail: View {
    let pattern: Core.ShoppingTimePattern
    var body: some View { Text("Shopping Time Details") }
}

struct RetailerPreferenceDetail: View {
    let pattern: Core.RetailerPreference
    var body: some View { Text("Retailer Preference Details") }
}

struct BulkBuyingDetail: View {
    let pattern: Core.BulkBuyingPattern
    var body: some View { Text("Bulk Buying Details") }
}