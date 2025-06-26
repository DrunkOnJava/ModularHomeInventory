//
//  BudgetRepository.swift
//  HomeInventoryModular
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
//  Module: Core
//  Dependencies: Foundation
//  Testing: Modules/Core/Tests/CoreTests/BudgetRepositoryTests.swift
//
//  Description: Repository protocol for comprehensive budget management including CRUD
//  operations, status tracking, alerts, transactions, and analytics. Provides budget
//  performance analysis and historical data management.
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation

/// Repository protocol for budget management
/// Swift 5.9 - No Swift 6 features
public protocol BudgetRepository {
    // MARK: - Budget CRUD
    func create(_ budget: Budget) async throws -> Budget
    func update(_ budget: Budget) async throws -> Budget
    func delete(_ budget: Budget) async throws
    func fetch(id: UUID) async throws -> Budget?
    func fetchAll() async throws -> [Budget]
    func fetchActive() async throws -> [Budget]
    func fetchByCategory(_ category: ItemCategory) async throws -> [Budget]
    
    // MARK: - Budget Status
    func getCurrentStatus(for budgetId: UUID) async throws -> BudgetStatus?
    func getHistoricalStatuses(for budgetId: UUID, limit: Int) async throws -> [BudgetStatus]
    func updateStatus(_ status: BudgetStatus) async throws -> BudgetStatus
    
    // MARK: - Budget Alerts
    func createAlert(_ alert: BudgetAlert) async throws -> BudgetAlert
    func fetchAlerts(for budgetId: UUID) async throws -> [BudgetAlert]
    func fetchUnreadAlerts() async throws -> [BudgetAlert]
    func markAlertAsRead(_ alertId: UUID) async throws
    
    // MARK: - Budget Transactions
    func recordTransaction(_ transaction: BudgetTransaction) async throws -> BudgetTransaction
    func fetchTransactions(for budgetId: UUID, in period: DateInterval?) async throws -> [BudgetTransaction]
    func deleteTransaction(_ transactionId: UUID) async throws
    
    // MARK: - Budget History
    func recordHistoryEntry(_ entry: BudgetHistoryEntry) async throws -> BudgetHistoryEntry
    func fetchHistory(for budgetId: UUID, limit: Int) async throws -> [BudgetHistoryEntry]
    
    // MARK: - Analytics
    func calculateSpending(for budgetId: UUID, in period: DateInterval) async throws -> Decimal
    func getAverageSpending(for budgetId: UUID, periods: Int) async throws -> Decimal
    func getBudgetPerformance(for budgetId: UUID) async throws -> BudgetPerformance
}

/// Budget performance analytics
public struct BudgetPerformance: Codable, Identifiable {
    public var id: UUID { budgetId }
    public let budgetId: UUID
    public let averageSpending: Decimal
    public let monthsAnalyzed: Int
    public let timesExceeded: Int
    public let averagePercentageUsed: Double
    public let trend: TrendDirection
    public let savingsOpportunity: Decimal?
    
    public init(
        budgetId: UUID,
        averageSpending: Decimal,
        monthsAnalyzed: Int,
        timesExceeded: Int,
        averagePercentageUsed: Double,
        trend: TrendDirection,
        savingsOpportunity: Decimal? = nil
    ) {
        self.budgetId = budgetId
        self.averageSpending = averageSpending
        self.monthsAnalyzed = monthsAnalyzed
        self.timesExceeded = timesExceeded
        self.averagePercentageUsed = averagePercentageUsed
        self.trend = trend
        self.savingsOpportunity = savingsOpportunity
    }
}