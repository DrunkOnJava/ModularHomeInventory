import SwiftUI
import Core
import SharedUI

/// View for creating a new budget
/// Swift 5.9 - No Swift 6 features
struct AddBudgetView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AddBudgetViewModel
    
    init(budgetService: Core.BudgetService, onSave: @escaping (Core.Budget) -> Void) {
        self._viewModel = StateObject(wrappedValue: AddBudgetViewModel(
            budgetService: budgetService,
            onSave: onSave
        ))
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Basic Information
                Section("Budget Details") {
                    TextField("Budget Name", text: $viewModel.name)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Description (Optional)", text: $viewModel.description, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(2...4)
                }
                
                // Amount and Period
                Section("Amount & Period") {
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0.00", value: $viewModel.amount, format: .currency(code: "USD"))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 120)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                    
                    Picker("Period", selection: $viewModel.period) {
                        ForEach(Core.BudgetPeriod.allCases, id: \.self) { period in
                            Label(period.rawValue, systemImage: period.icon)
                                .tag(period)
                        }
                    }
                    
                    if viewModel.period == .custom {
                        DatePicker("Start Date", selection: $viewModel.startDate, displayedComponents: .date)
                        
                        Toggle("Has End Date", isOn: $viewModel.hasEndDate)
                        
                        if viewModel.hasEndDate {
                            DatePicker("End Date", selection: $viewModel.endDate, displayedComponents: .date)
                        }
                    }
                }
                
                // Category Filter
                Section("Category Filter (Optional)") {
                    Toggle("Apply to Specific Category", isOn: $viewModel.hasCategory)
                    
                    if viewModel.hasCategory {
                        Picker("Category", selection: $viewModel.selectedCategory) {
                            Text("Select Category").tag(nil as ItemCategory?)
                            ForEach(ItemCategory.allCases, id: \.self) { category in
                                Label(category.displayName, systemImage: category.icon)
                                    .tag(category as ItemCategory?)
                            }
                        }
                    }
                }
                
                // Notifications
                Section("Notifications") {
                    Toggle("Enable Notifications", isOn: $viewModel.enableNotifications)
                    
                    if viewModel.enableNotifications {
                        HStack {
                            Text("Alert at")
                            Spacer()
                            Text("\(Int(viewModel.notificationThreshold * 100))%")
                                .foregroundStyle(.secondary)
                        }
                        
                        Slider(value: $viewModel.notificationThreshold, in: 0.5...0.95, step: 0.05)
                            .tint(AppColors.primary)
                    }
                }
                
                // Summary
                Section("Summary") {
                    summaryView
                }
            }
            .navigationTitle("New Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await viewModel.saveBudget()
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.isValid)
                }
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
    
    private var summaryView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Budget:")
                Spacer()
                Text(viewModel.amount.formatted(.currency(code: "USD")))
                    .fontWeight(.semibold)
            }
            
            HStack {
                Text("Period:")
                Spacer()
                Text(viewModel.period.rawValue)
                    .foregroundStyle(.secondary)
            }
            
            if viewModel.hasCategory, let category = viewModel.selectedCategory {
                HStack {
                    Text("Category:")
                    Spacer()
                    Label(category.displayName, systemImage: category.icon)
                        .foregroundStyle(.secondary)
                }
            }
            
            if viewModel.period != .custom {
                HStack {
                    Text("Daily Budget:")
                    Spacer()
                    Text((viewModel.amount / Decimal(viewModel.period.days)).formatted(.currency(code: "USD")))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .font(.system(size: 15))
    }
}

// MARK: - View Model

@MainActor
final class AddBudgetViewModel: ObservableObject {
    @Published var name = ""
    @Published var description = ""
    @Published var amount: Decimal = 0
    @Published var period: Core.BudgetPeriod = .monthly
    @Published var startDate = Date()
    @Published var endDate = Date().addingTimeInterval(30 * 86400)
    @Published var hasEndDate = false
    @Published var hasCategory = false
    @Published var selectedCategory: ItemCategory?
    @Published var enableNotifications = true
    @Published var notificationThreshold = 0.8
    @Published var showingError = false
    @Published var errorMessage = ""
    
    private let budgetService: Core.BudgetService
    private let onSave: (Core.Budget) -> Void
    
    var isValid: Bool {
        !name.isEmpty && amount > 0 && (!hasCategory || selectedCategory != nil)
    }
    
    init(budgetService: Core.BudgetService, onSave: @escaping (Core.Budget) -> Void) {
        self.budgetService = budgetService
        self.onSave = onSave
    }
    
    func saveBudget() async {
        guard isValid else { return }
        
        let budget = Core.Budget(
            name: name,
            description: description.isEmpty ? nil : description,
            amount: amount,
            period: period,
            category: hasCategory ? selectedCategory : nil,
            startDate: period == .custom ? startDate : Date(),
            endDate: period == .custom && hasEndDate ? endDate : nil,
            isActive: true,
            notificationThreshold: enableNotifications ? notificationThreshold : 1.0
        )
        
        do {
            let created = try await budgetService.createBudget(budget)
            await MainActor.run {
                onSave(created)
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}