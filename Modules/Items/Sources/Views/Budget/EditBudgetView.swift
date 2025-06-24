import SwiftUI
import Core
import SharedUI

/// View for editing an existing budget
/// Swift 5.9 - No Swift 6 features
struct EditBudgetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var description: String
    @State private var amount: Decimal
    @State private var notificationThreshold: Double
    @State private var isActive: Bool
    
    let budget: Core.Budget
    let budgetService: Core.BudgetService
    let onUpdate: (Core.Budget) -> Void
    
    init(budget: Core.Budget, budgetService: Core.BudgetService, onUpdate: @escaping (Core.Budget) -> Void) {
        self.budget = budget
        self.budgetService = budgetService
        self.onUpdate = onUpdate
        self._name = State(initialValue: budget.name)
        self._description = State(initialValue: budget.description ?? "")
        self._amount = State(initialValue: budget.amount)
        self._notificationThreshold = State(initialValue: budget.notificationThreshold)
        self._isActive = State(initialValue: budget.isActive)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Budget Details") {
                    TextField("Budget Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Amount") {
                    HStack {
                        Text("Budget Amount")
                        Spacer()
                        TextField("0.00", value: $amount, format: .currency(code: "USD"))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 120)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section("Settings") {
                    Toggle("Active", isOn: $isActive)
                    
                    HStack {
                        Text("Alert at")
                        Spacer()
                        Text("\(Int(notificationThreshold * 100))%")
                            .foregroundStyle(.secondary)
                    }
                    
                    Slider(value: $notificationThreshold, in: 0.5...0.95, step: 0.05)
                        .tint(AppColors.primary)
                }
            }
            .navigationTitle("Edit Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await updateBudget()
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty || amount <= 0)
                }
            }
        }
    }
    
    private func updateBudget() async {
        let updated = Core.Budget(
            id: budget.id,
            name: name,
            description: description.isEmpty ? nil : description,
            amount: amount,
            period: budget.period,
            category: budget.category,
            startDate: budget.startDate,
            endDate: budget.endDate,
            isActive: isActive,
            notificationThreshold: notificationThreshold,
            createdAt: budget.createdAt,
            updatedAt: Date()
        )
        
        do {
            let result = try await budgetService.updateBudget(updated)
            await MainActor.run {
                onUpdate(result)
            }
        } catch {
            print("Error updating budget: \(error)")
        }
    }
}