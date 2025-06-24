import SwiftUI
import Core
import SharedUI
import Charts

extension Calendar {
    func isDateInThisMonth(_ date: Date) -> Bool {
        return isDate(date, equalTo: Date(), toGranularity: .month)
    }
}

/// Budget dashboard view for tracking spending against budgets
/// Swift 5.9 - No Swift 6 features
struct BudgetDashboardView: View {
    @StateObject private var viewModel: BudgetDashboardViewModel
    @State private var showingAddBudget = false
    @State private var selectedBudget: Core.Budget?
    @State private var showingBudgetDetail = false
    
    init(budgetRepository: any BudgetRepository, itemRepository: any ItemRepository) {
        self._viewModel = StateObject(wrappedValue: BudgetDashboardViewModel(
            budgetService: Core.BudgetService(
                budgetRepository: budgetRepository,
                itemRepository: itemRepository
            ),
            budgetRepository: budgetRepository
        ))
    }
    
    var body: some View {
        ScrollView {
                VStack(spacing: 24) {
                    // Summary Card
                    if viewModel.isLoading {
                        ProgressView("Loading budgets...")
                            .padding(50)
                    } else {
                        budgetSummaryCard
                        
                        // Active Budgets
                        if !viewModel.activeBudgets.isEmpty {
                            activeBudgetsSection
                        }
                        
                        // Recent Alerts
                        if !viewModel.recentAlerts.isEmpty {
                            alertsSection
                        }
                        
                        // Budget Performance
                        if !viewModel.budgetPerformance.isEmpty {
                            performanceSection
                        }
                        
                        // Empty State
                        if viewModel.activeBudgets.isEmpty {
                            emptyStateView
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Budget Tracking")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddBudget = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(AppColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showingAddBudget) {
                AddBudgetView(
                    budgetService: viewModel.budgetService,
                    onSave: { budget in
                        Task {
                            await viewModel.loadBudgets()
                        }
                    }
                )
            }
            .sheet(isPresented: $showingBudgetDetail) {
                if let budget = selectedBudget {
                    BudgetDetailView(
                        budget: budget,
                        budgetService: viewModel.budgetService,
                        budgetRepository: viewModel.budgetRepository
                    )
                }
            }
            .task {
                await viewModel.loadBudgets()
            }
        }
    
    // MARK: - Components
    
    private var budgetSummaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Monthly Budget")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(viewModel.totalMonthlyBudget.formatted(.currency(code: "USD")))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                }
                
                Spacer()
                
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(AppColors.primary.opacity(0.3))
            }
            
            HStack(spacing: 20) {
                SummaryMetric(
                    label: "Spent",
                    value: viewModel.totalSpentThisMonth.formatted(.currency(code: "USD")),
                    icon: "arrow.up.circle.fill",
                    color: .red
                )
                
                SummaryMetric(
                    label: "Remaining",
                    value: viewModel.totalRemainingThisMonth.formatted(.currency(code: "USD")),
                    icon: "arrow.down.circle.fill",
                    color: .green
                )
                
                SummaryMetric(
                    label: "Active",
                    value: "\(viewModel.activeBudgets.count)",
                    icon: "checklist",
                    color: .blue
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private var activeBudgetsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Active Budgets")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                ForEach(viewModel.activeBudgets) { budget in
                    Button(action: {
                        selectedBudget = budget
                        showingBudgetDetail = true
                    }) {
                        BudgetCard(
                            budget: budget,
                            status: viewModel.budgetStatuses[budget.id]
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var alertsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Alerts")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink(destination: BudgetAlertsView(
                    budgetRepository: viewModel.budgetRepository
                )) {
                    Text("View All")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.primary)
                }
            }
            .padding(.horizontal)
            
            VStack(spacing: 12) {
                ForEach(viewModel.recentAlerts.prefix(3)) { alert in
                    AlertCard(alert: alert, budget: viewModel.getBudget(for: alert.budgetId))
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Budget Performance")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.budgetPerformance) { performance in
                        PerformanceCard(
                            performance: performance,
                            budget: viewModel.getBudget(for: performance.budgetId)
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.pie")
                .font(.system(size: 60))
                .foregroundStyle(AppColors.primary.opacity(0.5))
            
            Text("No Budgets Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create your first budget to start tracking your spending")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { showingAddBudget = true }) {
                Label("Create Budget", systemImage: "plus.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppColors.primary)
                    .foregroundStyle(.white)
                    .cornerRadius(25)
            }
        }
        .padding(40)
    }
}

// MARK: - Supporting Views

struct BudgetCard: View {
    let budget: Core.Budget
    let status: Core.BudgetStatus?
    
    private var percentageUsed: Double {
        status?.percentageUsed ?? 0
    }
    
    private var progressColor: Color {
        if percentageUsed >= 1.0 {
            return .red
        } else if percentageUsed >= 0.8 {
            return .orange
        } else {
            return AppColors.primary
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(budget.name)
                        .font(.system(size: 16, weight: .semibold))
                    
                    if let category = budget.category {
                        Label(category.displayName, systemImage: category.icon)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text((status?.spent ?? 0).formatted(.currency(code: "USD")))
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("of \(budget.amount.formatted(.currency(code: "USD")))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(progressColor)
                        .frame(width: geometry.size.width * min(1.0, percentageUsed), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("\(Int(percentageUsed * 100))% used")
                    .font(.caption)
                    .foregroundStyle(progressColor)
                
                Spacer()
                
                if let status = status {
                    Text("\(status.remaining.formatted(.currency(code: "USD"))) remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct AlertCard: View {
    let alert: Core.BudgetAlert
    let budget: Core.Budget?
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: alert.type.icon)
                .font(.title2)
                .foregroundStyle(Color(hex: alert.type.color))
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.title)
                    .font(.system(size: 15, weight: .medium))
                
                Text(alert.message)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            if !alert.isRead {
                Circle()
                    .fill(AppColors.primary)
                    .frame(width: 8, height: 8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PerformanceCard: View {
    let performance: Core.BudgetPerformance
    let budget: Core.Budget?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(budget?.name ?? "Unknown Budget")
                .font(.system(size: 15, weight: .medium))
            
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("Avg. Used")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Text("\(Int(performance.averagePercentageUsed * 100))%")
                        .font(.system(size: 18, weight: .semibold))
                }
                
                VStack(spacing: 4) {
                    Text("Exceeded")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Text("\(performance.timesExceeded)")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(performance.timesExceeded > 0 ? .red : .primary)
                }
            }
            
            if performance.trend != .stable {
                HStack(spacing: 4) {
                    Image(systemName: performance.trend == .up ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption)
                    
                    Text(performance.trend.rawValue)
                        .font(.caption)
                }
                .foregroundStyle(performance.trend == .up ? .red : .green)
            }
        }
        .padding()
        .frame(width: 150)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - View Model

@MainActor
final class BudgetDashboardViewModel: ObservableObject {
    @Published var activeBudgets: [Core.Budget] = []
    @Published var budgetStatuses: [UUID: Core.BudgetStatus] = [:]
    @Published var recentAlerts: [Core.BudgetAlert] = []
    @Published var budgetPerformance: [Core.BudgetPerformance] = []
    @Published var isLoading = false
    
    let budgetService: Core.BudgetService
    let budgetRepository: any BudgetRepository
    
    var totalMonthlyBudget: Decimal {
        activeBudgets
            .filter { $0.period == .monthly || $0.period == .custom }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }
    
    var totalSpentThisMonth: Decimal {
        budgetStatuses.values
            .filter { Calendar.current.isDateInThisMonth($0.periodStart) }
            .reduce(Decimal(0)) { $0 + $1.spent }
    }
    
    var totalRemainingThisMonth: Decimal {
        budgetStatuses.values
            .filter { Calendar.current.isDateInThisMonth($0.periodStart) }
            .reduce(Decimal(0)) { $0 + $1.remaining }
    }
    
    init(budgetService: Core.BudgetService, budgetRepository: any BudgetRepository) {
        self.budgetService = budgetService
        self.budgetRepository = budgetRepository
    }
    
    func loadBudgets() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Load active budgets
            activeBudgets = try await budgetRepository.fetchActive()
            
            // Load statuses
            for budget in activeBudgets {
                if let status = try await budgetRepository.getCurrentStatus(for: budget.id) {
                    budgetStatuses[budget.id] = status
                }
                
                // Load performance
                if let performance = try? await budgetRepository.getBudgetPerformance(for: budget.id) {
                    budgetPerformance.append(performance)
                }
            }
            
            // Load recent alerts
            recentAlerts = try await budgetRepository.fetchUnreadAlerts()
            
            // Check all budgets for updates
            try await budgetService.checkBudgets()
            
        } catch {
            print("Error loading budgets: \(error)")
        }
    }
    
    func getBudget(for id: UUID) -> Core.Budget? {
        activeBudgets.first { $0.id == id }
    }
}