//
//  EditBudgetView.swift
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
//  Dependencies: SwiftUI, Core, SharedUI
//  Testing: ItemsTests/Budget/EditBudgetViewTests.swift
//
//  Description: Budget editing interface allowing modification of budget parameters including
//  name, amount, period, categories, and alert settings with form validation and
//  real-time updates for existing budget management.
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

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