import SwiftUI
import Core
import SharedUI
import Charts

/// Depreciation report view for tracking asset value over time
/// Swift 5.9 - No Swift 6 features
struct DepreciationReportView: View {
    @StateObject private var viewModel: DepreciationReportViewModel
    @State private var selectedMethod: Core.DepreciationMethod = .categoryBased
    @State private var selectedCategories: Set<Core.ItemCategory> = []
    @State private var showingFilters = false
    @State private var showingItemDetail = false
    @State private var selectedItem: Core.DepreciatingItem?
    @State private var selectedTab = 0
    
    init(itemRepository: any ItemRepository) {
        self._viewModel = StateObject(wrappedValue: DepreciationReportViewModel(
            itemRepository: itemRepository
        ))
    }
    
    var body: some View {
        ScrollView {
                VStack(spacing: 24) {
                    // Summary Card
                    summaryCard
                    
                    // Method Selector
                    methodSelector
                    
                    // Tab Selection
                    Picker("View", selection: $selectedTab) {
                        Text("Overview").tag(0)
                        Text("By Category").tag(1)
                        Text("Items").tag(2)
                        Text("Schedule").tag(3)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    switch selectedTab {
                    case 0:
                        // Overview Charts
                        if let report = viewModel.currentReport {
                            overviewSection(report: report)
                        }
                        
                    case 1:
                        // Category Breakdown
                        if !viewModel.categoryBreakdown.isEmpty {
                            categoryBreakdownSection
                        }
                        
                    case 2:
                        // Individual Items
                        if let report = viewModel.currentReport {
                            itemsListSection(report: report)
                        }
                        
                    case 3:
                        // Depreciation Schedule
                        if let schedule = viewModel.selectedItemSchedule {
                            scheduleSection(schedule: schedule)
                        } else {
                            Text("Select an item to view its depreciation schedule")
                                .foregroundStyle(.secondary)
                                .padding()
                        }
                        
                    default:
                        EmptyView()
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Depreciation Report")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                Task {
                    await viewModel.generateReport(method: selectedMethod)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            showingFilters = true
                        }) {
                            Label("Filter Categories", systemImage: "line.3.horizontal.decrease.circle")
                        }
                        
                        Button(action: {
                            Task { await viewModel.exportReport() }
                        }) {
                            Label("Export Report", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(action: {
                            Task { await viewModel.refreshReport() }
                        }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                CategoryFilterSheet(
                    selectedCategories: $selectedCategories,
                    onApply: {
                        Task {
                            await viewModel.generateReport(
                                method: selectedMethod,
                                categories: Array(selectedCategories)
                            )
                        }
                    }
                )
            }
            .sheet(isPresented: $showingItemDetail) {
                if let item = selectedItem {
                    ItemDepreciationDetailView(
                        item: item,
                        onScheduleRequest: { itemId in
                            Task {
                                await viewModel.loadScheduleForItem(itemId: itemId)
                                selectedTab = 3
                            }
                        }
                    )
                }
            }
            .task {
                await viewModel.generateReport(method: selectedMethod)
            }
        }
    
    // MARK: - Components
    
    private var summaryCard: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Assets Value")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let report = viewModel.currentReport {
                        Text(report.totalCurrentValue, format: .currency(code: "USD").precision(.fractionLength(2)))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 14))
                            Text("\(Int(report.depreciationPercentage))% depreciated")
                                .font(.caption)
                        }
                        .foregroundStyle(.red)
                    }
                }
                
                Spacer()
                
                // Depreciation Chart
                if let report = viewModel.currentReport {
                    DepreciationGauge(
                        originalValue: report.totalOriginalValue,
                        currentValue: report.totalCurrentValue
                    )
                    .frame(width: 100, height: 100)
                }
            }
            
            // Key Metrics
            if let report = viewModel.currentReport {
                HStack(spacing: 16) {
                    MetricBox(
                        label: "Original Value",
                        value: report.totalOriginalValue.asCurrency(),
                        icon: "dollarsign.circle",
                        color: .blue
                    )
                    
                    MetricBox(
                        label: "Depreciation",
                        value: report.totalDepreciation.asCurrency(),
                        icon: "chart.line.downtrend.xyaxis",
                        color: .red
                    )
                    
                    MetricBox(
                        label: "Items",
                        value: "\(report.items.count)",
                        icon: "shippingbox",
                        color: .green
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private var methodSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Depreciation Method")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Core.DepreciationMethod.allCases, id: \.self) { method in
                        Button(action: {
                            selectedMethod = method
                            Task {
                                await viewModel.generateReport(
                                    method: method,
                                    categories: Array(selectedCategories)
                                )
                            }
                        }) {
                            VStack(spacing: 4) {
                                Text(method.rawValue)
                                    .font(.system(size: 14, weight: .medium))
                                
                                Text(method.description)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedMethod == method ? AppColors.primary : Color(.systemGray5))
                            .foregroundStyle(selectedMethod == method ? .white : .primary)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func overviewSection(report: Core.DepreciationReport) -> some View {
        VStack(spacing: 16) {
            // Value Over Time Chart
            ValueOverTimeChart(items: report.items)
                .frame(height: 250)
                .padding(.horizontal)
            
            // Top Depreciating Items
            if !report.items.isEmpty {
                TopDepreciatingItemsCard(
                    items: Array(report.items.sorted { $0.depreciationAmount > $1.depreciationAmount }.prefix(5))
                )
            }
        }
    }
    
    private var categoryBreakdownSection: some View {
        VStack(spacing: 16) {
            ForEach(viewModel.categoryBreakdown.sorted(by: { $0.value.totalOriginalValue > $1.value.totalOriginalValue }), id: \.key) { category, summary in
                CategoryDepreciationCard(
                    category: category,
                    summary: summary
                )
            }
        }
        .padding(.horizontal)
    }
    
    private func itemsListSection(report: Core.DepreciationReport) -> some View {
        VStack(spacing: 12) {
            ForEach(report.items.sorted(by: { $0.itemName < $1.itemName })) { item in
                Button(action: {
                    selectedItem = item
                    showingItemDetail = true
                }) {
                    ItemDepreciationRow(item: item)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal)
    }
    
    private func scheduleSection(schedule: Core.DepreciationSchedule) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Schedule Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Depreciation Schedule")
                    .font(.headline)
                
                HStack {
                    Label("Method: \(schedule.method.rawValue)", systemImage: "function")
                    Spacer()
                    Label("Life: \(schedule.usefulLife) years", systemImage: "calendar")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            
            // Annual Schedule Chart
            if !schedule.annualDepreciation.isEmpty {
                DepreciationScheduleChart(schedule: schedule)
                    .frame(height: 250)
                    .padding(.horizontal)
            }
            
            // Schedule Table
            DepreciationScheduleTable(schedule: schedule)
        }
    }
}

// MARK: - Supporting Views

struct DepreciationGauge: View {
    let originalValue: Decimal
    let currentValue: Decimal
    
    private var percentage: Double {
        guard originalValue > 0 else { return 0 }
        return NSDecimalNumber(decimal: currentValue).doubleValue / 
               NSDecimalNumber(decimal: originalValue).doubleValue
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray4), lineWidth: 10)
            
            Circle()
                .trim(from: 0, to: CGFloat(percentage))
                .stroke(AppColors.primary, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            VStack(spacing: 2) {
                Text("\(Int(percentage * 100))%")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Text("Value")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct MetricBox: View {
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
                .font(.system(size: 14, weight: .semibold))
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemGray5))
        .cornerRadius(8)
    }
}

struct ValueOverTimeChart: View {
    let items: [Core.DepreciatingItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Asset Value Over Time")
                .font(.headline)
            
            Chart {
                ForEach(items) { item in
                    LineMark(
                        x: .value("Age", item.ageInYears),
                        y: .value("Value", NSDecimalNumber(decimal: item.currentValue).doubleValue)
                    )
                    .foregroundStyle(by: .value("Category", item.category.rawValue))
                }
            }
            .chartLegend(position: .bottom)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TopDepreciatingItemsCard: View {
    let items: [Core.DepreciatingItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Depreciating Assets")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                ForEach(items) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.itemName)
                                .font(.system(size: 14, weight: .medium))
                            Text("\(item.category.rawValue) • \(Int(item.ageInYears)) years old")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("-\(item.depreciationAmount.asCurrency())")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.red)
                            Text("\(Int(item.depreciationPercentage))% depreciated")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct CategoryDepreciationCard: View {
    let category: Core.ItemCategory
    let summary: Core.CategoryDepreciationSummary
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Label(category.rawValue, systemImage: category.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: category.color))
                
                Spacer()
                
                Text("\(summary.itemCount) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Original")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(summary.totalOriginalValue, format: .currency(code: "USD").precision(.fractionLength(2)))
                        .font(.system(size: 14, weight: .semibold))
                }
                
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(summary.totalCurrentValue, format: .currency(code: "USD").precision(.fractionLength(2)))
                        .font(.system(size: 14, weight: .semibold))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("-\(Int(summary.averageDepreciationPercentage))%")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.red)
                    Text("depreciated")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ItemDepreciationRow: View {
    let item: Core.DepreciatingItem
    
    var body: some View {
        HStack {
            Image(systemName: item.category.icon)
                .font(.title2)
                .foregroundStyle(Color(hex: item.category.color))
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.itemName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary)
                
                Text("Purchased \(item.purchaseDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(item.currentValue, format: .currency(code: "USD").precision(.fractionLength(2)))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                
                HStack(spacing: 2) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 10))
                    Text("\(Int(item.depreciationPercentage))%")
                }
                .font(.caption)
                .foregroundStyle(.red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct DepreciationScheduleChart: View {
    let schedule: Core.DepreciationSchedule
    
    var body: some View {
        Chart(schedule.annualDepreciation) { entry in
            LineMark(
                x: .value("Year", entry.year),
                y: .value("Book Value", NSDecimalNumber(decimal: entry.bookValue).doubleValue)
            )
            .foregroundStyle(AppColors.primary)
            .lineStyle(StrokeStyle(lineWidth: 3))
            
            PointMark(
                x: .value("Year", entry.year),
                y: .value("Book Value", NSDecimalNumber(decimal: entry.bookValue).doubleValue)
            )
            .foregroundStyle(AppColors.primary)
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
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let year = value.as(Int.self) {
                        Text("Year \(year)")
                            .font(.caption)
                    }
                }
            }
        }
    }
}

struct DepreciationScheduleTable: View {
    let schedule: Core.DepreciationSchedule
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Annual Breakdown")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    HStack(spacing: 0) {
                        Text("Year")
                            .frame(width: 60, alignment: .leading)
                        Text("Depreciation")
                            .frame(width: 100, alignment: .trailing)
                        Text("Accumulated")
                            .frame(width: 100, alignment: .trailing)
                        Text("Book Value")
                            .frame(width: 100, alignment: .trailing)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray5))
                    
                    // Rows
                    ForEach(schedule.annualDepreciation) { entry in
                        HStack(spacing: 0) {
                            Text("\(entry.year)")
                                .frame(width: 60, alignment: .leading)
                            Text(entry.depreciationAmount, format: .currency(code: "USD").precision(.fractionLength(2)))
                                .frame(width: 100, alignment: .trailing)
                            Text(entry.accumulatedDepreciation, format: .currency(code: "USD").precision(.fractionLength(2)))
                                .frame(width: 100, alignment: .trailing)
                            Text(entry.bookValue, format: .currency(code: "USD").precision(.fractionLength(2)))
                                .frame(width: 100, alignment: .trailing)
                                .foregroundStyle(AppColors.primary)
                                .fontWeight(.medium)
                        }
                        .font(.system(size: 13))
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Detail Views

struct ItemDepreciationDetailView: View {
    let item: Core.DepreciatingItem
    let onScheduleRequest: (UUID) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Item Header
                    HStack {
                        Image(systemName: item.category.icon)
                            .font(.largeTitle)
                            .foregroundStyle(Color(hex: item.category.color))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.itemName)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text(item.category.rawValue)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Value Summary
                    VStack(spacing: 16) {
                        ValueRow(label: "Purchase Price", value: item.purchasePrice.asCurrency())
                        ValueRow(label: "Current Value", value: item.currentValue.asCurrency(), valueColor: AppColors.primary)
                        ValueRow(label: "Total Depreciation", value: "-\(item.depreciationAmount.asCurrency())", valueColor: .red)
                        ValueRow(label: "Depreciation Rate", value: "\(Int(item.depreciationPercentage))%")
                        
                        Divider()
                        
                        ValueRow(label: "Purchase Date", value: item.purchaseDate.formatted(date: .long, time: .omitted))
                        ValueRow(label: "Age", value: String(format: "%.1f years", item.ageInYears))
                        ValueRow(label: "Method", value: item.depreciationMethod.rawValue)
                        
                        if let lifespan = item.estimatedLifespan {
                            ValueRow(label: "Estimated Lifespan", value: "\(lifespan) years")
                        }
                        
                        if let salvageValue = item.salvageValue {
                            ValueRow(label: "Salvage Value", value: salvageValue.asCurrency())
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // View Schedule Button
                    Button(action: {
                        onScheduleRequest(item.itemId)
                        dismiss()
                    }) {
                        Label("View Full Schedule", systemImage: "calendar")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColors.primary)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Depreciation Details")
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

struct ValueRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundStyle(valueColor)
        }
        .font(.system(size: 15))
    }
}

struct CategoryFilterSheet: View {
    @Binding var selectedCategories: Set<Core.ItemCategory>
    let onApply: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Core.ItemCategory.allCases, id: \.self) { category in
                    HStack {
                        Label(category.rawValue, systemImage: category.icon)
                            .foregroundStyle(Color(hex: category.color))
                        
                        Spacer()
                        
                        if selectedCategories.contains(category) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(AppColors.primary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedCategories.contains(category) {
                            selectedCategories.remove(category)
                        } else {
                            selectedCategories.insert(category)
                        }
                    }
                }
            }
            .navigationTitle("Filter Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        onApply()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - View Model
@MainActor
final class DepreciationReportViewModel: ObservableObject {
    @Published var currentReport: Core.DepreciationReport?
    @Published var categoryBreakdown: [Core.ItemCategory: Core.CategoryDepreciationSummary] = [:]
    @Published var selectedItemSchedule: Core.DepreciationSchedule?
    @Published var isLoading = false
    
    private let depreciationService: Core.DepreciationService
    private let itemRepository: any ItemRepository
    
    init(itemRepository: any ItemRepository) {
        self.itemRepository = itemRepository
        self.depreciationService = Core.DepreciationService(itemRepository: itemRepository)
    }
    
    func generateReport(
        method: Core.DepreciationMethod = .categoryBased,
        categories: [Core.ItemCategory]? = nil
    ) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            currentReport = try await depreciationService.generateDepreciationReport(
                method: method,
                includeCategories: categories
            )
            
            categoryBreakdown = try await depreciationService.calculateDepreciationByCategory()
        } catch {
            print("Error generating depreciation report: \(error)")
        }
    }
    
    func loadScheduleForItem(itemId: UUID) async {
        do {
            let items = try await itemRepository.fetchAll()
            if let item = items.first(where: { $0.id == itemId }) {
                selectedItemSchedule = depreciationService.calculateDepreciationSchedule(item: item)
            }
        } catch {
            print("Error loading item schedule: \(error)")
        }
    }
    
    func refreshReport() async {
        if let report = currentReport {
            await generateReport(method: .categoryBased)
        }
    }
    
    func exportReport() async {
        guard let report = currentReport else { return }
        
        do {
            let data = try await Core.AnalyticsExportService.shared.exportDepreciationReport(
                report,
                format: .csv
            )
            
            let filename = "DepreciationReport_\(Date().formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-"))"
            let fileURL = try Core.AnalyticsExportService.shared.saveToFile(
                data: data,
                filename: filename,
                format: .csv
            )
            
            print("Report exported to: \(fileURL)")
            // In a real app, would present share sheet or show success message
        } catch {
            print("Export failed: \(error)")
        }
    }
}