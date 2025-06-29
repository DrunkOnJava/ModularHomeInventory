//
//  BudgetAlertsView.swift
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
//  URL Scheme: com.googleusercontent.apps.316432172622-6huvbn752v0ep68jkfgpesikg
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
//  Testing: ItemsTests/Budget/BudgetAlertsViewTests.swift
//
//  Description: Budget alerts management interface displaying overspending warnings, approaching
//  limits, and budget milestone notifications with customizable alert settings and notification
//  preferences for proactive spending management.
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core
import SharedUI

/// View for displaying budget alerts
/// Swift 5.9 - No Swift 6 features
struct BudgetAlertsView: View {
    @StateObject private var viewModel: BudgetAlertsViewModel
    
    init(budgetRepository: any BudgetRepository) {
        self._viewModel = StateObject(wrappedValue: BudgetAlertsViewModel(
            budgetRepository: budgetRepository
        ))
    }
    
    var body: some View {
        List {
            if viewModel.alerts.isEmpty {
                ContentUnavailableView(
                    "No Alerts",
                    systemImage: "bell.slash",
                    description: Text("You don't have any budget alerts")
                )
            } else {
                ForEach(viewModel.groupedAlerts.keys.sorted(by: >), id: \.self) { date in
                    Section(header: Text(sectionHeader(for: date))) {
                        ForEach(viewModel.groupedAlerts[date] ?? []) { alert in
                            AlertRow(
                                alert: alert,
                                budget: viewModel.budgets[alert.budgetId],
                                onTap: {
                                    Task {
                                        await viewModel.markAsRead(alert)
                                    }
                                }
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle("Budget Alerts")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadAlerts()
        }
    }
    
    private func sectionHeader(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return date.formatted(date: .abbreviated, time: .omitted)
        }
    }
}

struct AlertRow: View {
    let alert: Core.BudgetAlert
    let budget: Core.Budget?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: alert.type.icon)
                    .font(.title2)
                    .foregroundStyle(Color(hex: alert.type.color))
                    .frame(width: 36, height: 36)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(alert.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.primary)
                    
                    Text(alert.message)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    
                    if let budget = budget {
                        Label(budget.name, systemImage: "chart.pie")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if !alert.isRead {
                        Circle()
                            .fill(AppColors.primary)
                            .frame(width: 8, height: 8)
                    }
                    
                    Text(alert.createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - View Model

@MainActor
final class BudgetAlertsViewModel: ObservableObject {
    @Published var alerts: [Core.BudgetAlert] = []
    @Published var budgets: [UUID: Core.Budget] = [:]
    
    private let budgetRepository: any BudgetRepository
    
    var groupedAlerts: [Date: [Core.BudgetAlert]] {
        Dictionary(grouping: alerts) { alert in
            Calendar.current.startOfDay(for: alert.createdAt)
        }
    }
    
    init(budgetRepository: any BudgetRepository) {
        self.budgetRepository = budgetRepository
    }
    
    func loadAlerts() async {
        do {
            // Load all budgets first
            let allBudgets = try await budgetRepository.fetchAll()
            for budget in allBudgets {
                budgets[budget.id] = budget
            }
            
            // Load alerts for each budget
            var allAlerts: [Core.BudgetAlert] = []
            for budget in allBudgets {
                let budgetAlerts = try await budgetRepository.fetchAlerts(for: budget.id)
                allAlerts.append(contentsOf: budgetAlerts)
            }
            
            // Sort by date descending
            alerts = allAlerts.sorted { $0.createdAt > $1.createdAt }
            
        } catch {
            print("Error loading alerts: \(error)")
        }
    }
    
    func markAsRead(_ alert: Core.BudgetAlert) async {
        do {
            try await budgetRepository.markAlertAsRead(alert.id)
            
            // Update local state
            if let index = alerts.firstIndex(where: { $0.id == alert.id }) {
                alerts[index] = Core.BudgetAlert(
                    id: alert.id,
                    budgetId: alert.budgetId,
                    type: alert.type,
                    title: alert.title,
                    message: alert.message,
                    percentageUsed: alert.percentageUsed,
                    amountSpent: alert.amountSpent,
                    amountRemaining: alert.amountRemaining,
                    createdAt: alert.createdAt,
                    isRead: true
                )
            }
        } catch {
            print("Error marking alert as read: \(error)")
        }
    }
}