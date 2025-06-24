import SwiftUI
import Core
import SharedUI
import Charts

/// Detailed view for a specific budget
/// Swift 5.9 - No Swift 6 features
struct BudgetDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: BudgetDetailViewModel
    @State private var showingEditBudget = false
    @State private var showingDeleteConfirmation = false
    
    init(budget: Core.Budget, budgetService: Core.BudgetService, budgetRepository: any BudgetRepository) {
        self._viewModel = StateObject(wrappedValue: BudgetDetailViewModel(
            budget: budget,
            budgetService: budgetService,
            budgetRepository: budgetRepository
        ))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Current Status Card
                    if let status = viewModel.currentStatus {
                        currentStatusCard(status: status)
                    }
                    
                    // Spending Chart
                    if !viewModel.transactions.isEmpty {
                        spendingChartCard
                    }
                    
                    // Insights
                    if let insights = viewModel.insights {
                        insightsCard(insights: insights)
                    }
                    
                    // Recent Transactions
                    if !viewModel.transactions.isEmpty {
                        transactionsCard
                    }
                    
                    // History
                    if !viewModel.history.isEmpty {
                        historyCard
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle(viewModel.budget.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingEditBudget = true }) {
                            Label("Edit Budget", systemImage: "pencil")
                        }
                        
                        Button(action: { viewModel.toggleActive() }) {
                            Label(
                                viewModel.budget.isActive ? "Pause Budget" : "Resume Budget",
                                systemImage: viewModel.budget.isActive ? "pause.circle" : "play.circle"
                            )
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                            Label("Delete Budget", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingEditBudget) {
                EditBudgetView(
                    budget: viewModel.budget,
                    budgetService: viewModel.budgetService,
                    onUpdate: { updated in
                        viewModel.budget = updated
                        Task { await viewModel.loadData() }
                    }
                )
            }
            .alert("Delete Budget?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteBudget()
                        dismiss()
                    }
                }
            } message: {
                Text("This will permanently delete this budget and all its history.")
            }
            .task {
                await viewModel.loadData()
            }
        }
    }
    
    // MARK: - Components
    
    private func currentStatusCard(status: Core.BudgetStatus) -> some View {
        VStack(spacing: 16) {
            // Progress Circle
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 12)
                    .frame(width: 150, height: 150)
                
                Circle()
                    .trim(from: 0, to: min(1.0, status.percentageUsed))
                    .stroke(progressColor(for: status.percentageUsed), lineWidth: 12)
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 4) {
                    Text("\(Int(status.percentageUsed * 100))%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    
                    Text("Used")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Stats
            HStack(spacing: 30) {
                VStack(spacing: 4) {
                    Text("Spent")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(status.spent.formatted(.currency(code: "USD")))
                        .font(.system(size: 18, weight: .semibold))
                }
                
                VStack(spacing: 4) {
                    Text("Remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(status.remaining.formatted(.currency(code: "USD")))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(status.remaining > 0 ? .green : .red)
                }
                
                VStack(spacing: 4) {
                    Text("Items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("\(status.itemCount)")
                        .font(.system(size: 18, weight: .semibold))
                }
            }
            
            // Period Info
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.secondary)
                
                Text("\(status.periodStart.formatted(date: .abbreviated, time: .omitted)) - \(status.periodEnd.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Projected Spending
            if let projected = status.projectedSpending, projected != status.spent {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundStyle(projected > viewModel.budget.amount ? .red : .orange)
                    
                    Text("Projected: \(projected.formatted(.currency(code: "USD")))")
                        .font(.caption)
                        .foregroundStyle(projected > viewModel.budget.amount ? .red : .orange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .cornerRadius(20)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private var spendingChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending Timeline")
                .font(.headline)
                .padding(.horizontal)
            
            Chart(viewModel.spendingData) { data in
                LineMark(
                    x: .value("Date", data.date),
                    y: .value("Amount", data.cumulativeAmount)
                )
                .foregroundStyle(AppColors.primary)
                .interpolationMethod(.catmullRom)
                
                AreaMark(
                    x: .value("Date", data.date),
                    y: .value("Amount", data.cumulativeAmount)
                )
                .foregroundStyle(AppColors.primary.opacity(0.1))
                .interpolationMethod(.catmullRom)
            }
            .frame(height: 200)
            .padding(.horizontal)
            
            // Budget line
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7))
            }
        }
        .padding(.vertical)
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private func insightsCard(insights: Core.BudgetInsights) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insights & Recommendations")
                .font(.headline)
            
            // Insights
            if !insights.insights.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(insights.insights, id: \.self) { insight in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.yellow)
                            
                            Text(insight)
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            
            Divider()
            
            // Recommendations
            if !insights.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(insights.recommendations, id: \.self) { recommendation in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.orange)
                            
                            Text(recommendation)
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            
            // Projected Savings
            if let savings = insights.projectedAnnualSavings, savings > 0 {
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Potential Annual Savings")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(savings.formatted(.currency(code: "USD")))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.green)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private var transactionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Transactions")
                    .font(.headline)
                
                Spacer()
                
                Text("\(viewModel.transactions.count) total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            VStack(spacing: 12) {
                ForEach(viewModel.transactions.prefix(10)) { transaction in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(transaction.itemName)
                                .font(.subheadline)
                            
                            HStack(spacing: 8) {
                                if let store = transaction.storeName {
                                    Text(store)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Text(transaction.amount.formatted(.currency(code: "USD")))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("History")
                .font(.headline)
            
            VStack(spacing: 12) {
                ForEach(viewModel.history) { entry in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(formatPeriod(entry.period))
                                .font(.subheadline)
                            
                            Text("\(entry.itemCount) items")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(entry.actualSpent.formatted(.currency(code: "USD")))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(entry.wasOverBudget ? .red : .primary)
                            
                            Text("\(Int(entry.percentageUsed * 100))% of budget")
                                .font(.caption)
                                .foregroundStyle(entry.wasOverBudget ? .red : .secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    // MARK: - Helper Methods
    
    private func progressColor(for percentage: Double) -> Color {
        if percentage >= 1.0 {
            return .red
        } else if percentage >= 0.8 {
            return .orange
        } else {
            return AppColors.primary
        }
    }
    
    private func formatPeriod(_ interval: DateInterval) -> String {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: interval.start, to: interval.end)
    }
}

// MARK: - View Model

@MainActor
final class BudgetDetailViewModel: ObservableObject {
    @Published var budget: Core.Budget
    @Published var currentStatus: Core.BudgetStatus?
    @Published var transactions: [Core.BudgetTransaction] = []
    @Published var history: [Core.BudgetHistoryEntry] = []
    @Published var insights: Core.BudgetInsights?
    @Published var spendingData: [SpendingDataPoint] = []
    
    let budgetService: Core.BudgetService
    let budgetRepository: any BudgetRepository
    
    init(budget: Core.Budget, budgetService: Core.BudgetService, budgetRepository: any BudgetRepository) {
        self.budget = budget
        self.budgetService = budgetService
        self.budgetRepository = budgetRepository
    }
    
    func loadData() async {
        do {
            // Load current status
            currentStatus = try await budgetRepository.getCurrentStatus(for: budget.id)
            
            // Load transactions
            if let status = currentStatus {
                let period = DateInterval(start: status.periodStart, end: status.periodEnd)
                transactions = try await budgetRepository.fetchTransactions(for: budget.id, in: period)
                
                // Generate spending timeline
                generateSpendingData(from: transactions, in: period)
            }
            
            // Load history
            history = try await budgetRepository.fetchHistory(for: budget.id, limit: 12)
            
            // Load insights
            insights = try await budgetService.getBudgetInsights(for: budget)
            
        } catch {
            print("Error loading budget details: \(error)")
        }
    }
    
    func toggleActive() {
        budget = Core.Budget(
            id: budget.id,
            name: budget.name,
            description: budget.description,
            amount: budget.amount,
            period: budget.period,
            category: budget.category,
            startDate: budget.startDate,
            endDate: budget.endDate,
            isActive: !budget.isActive,
            notificationThreshold: budget.notificationThreshold,
            createdAt: budget.createdAt,
            updatedAt: Date()
        )
        
        Task {
            do {
                budget = try await budgetService.updateBudget(budget)
            } catch {
                print("Error updating budget: \(error)")
            }
        }
    }
    
    func deleteBudget() async {
        do {
            try await budgetService.deleteBudget(budget)
        } catch {
            print("Error deleting budget: \(error)")
        }
    }
    
    private func generateSpendingData(from transactions: [Core.BudgetTransaction], in period: DateInterval) {
        let sortedTransactions = transactions.sorted { $0.date < $1.date }
        var cumulativeAmount: Decimal = 0
        var dataPoints: [SpendingDataPoint] = []
        
        // Add starting point
        dataPoints.append(SpendingDataPoint(date: period.start, cumulativeAmount: 0))
        
        // Add transaction points
        for transaction in sortedTransactions {
            cumulativeAmount += transaction.amount
            dataPoints.append(SpendingDataPoint(
                date: transaction.date,
                cumulativeAmount: cumulativeAmount
            ))
        }
        
        // Add current point if different from last
        if let lastDate = dataPoints.last?.date, lastDate < Date() {
            dataPoints.append(SpendingDataPoint(
                date: min(Date(), period.end),
                cumulativeAmount: cumulativeAmount
            ))
        }
        
        spendingData = dataPoints
    }
}

struct SpendingDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let cumulativeAmount: Decimal
}