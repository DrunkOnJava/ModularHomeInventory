//
//  BudgetServiceTests.swift
//  CoreTests
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import XCTest
@testable import Core

final class BudgetServiceTests: XCTestCase {
    
    var sut: BudgetService!
    
    override func setUp() {
        super.setUp()
        sut = BudgetService()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Budget Creation Tests
    
    func testCreateBudget() {
        // Given
        let budget = Budget(
            name: "Electronics Budget",
            category: .electronics,
            amount: 1000.0,
            period: .monthly
        )
        
        // When
        sut.addBudget(budget)
        
        // Then
        XCTAssertEqual(sut.budgets.count, 1)
        XCTAssertEqual(sut.budgets.first?.name, "Electronics Budget")
        XCTAssertEqual(sut.budgets.first?.amount, 1000.0)
    }
    
    func testCreateMultipleBudgets() {
        // Given
        let budget1 = Budget(name: "Tech", category: .electronics, amount: 500, period: .monthly)
        let budget2 = Budget(name: "Home", category: .furniture, amount: 300, period: .monthly)
        let budget3 = Budget(name: "Annual", category: nil, amount: 5000, period: .yearly)
        
        // When
        sut.addBudget(budget1)
        sut.addBudget(budget2)
        sut.addBudget(budget3)
        
        // Then
        XCTAssertEqual(sut.budgets.count, 3)
        XCTAssertTrue(sut.budgets.contains { $0.name == "Tech" })
        XCTAssertTrue(sut.budgets.contains { $0.name == "Home" })
        XCTAssertTrue(sut.budgets.contains { $0.name == "Annual" })
    }
    
    // MARK: - Budget Update Tests
    
    func testUpdateBudget() {
        // Given
        var budget = Budget(name: "Monthly", category: .other, amount: 100, period: .monthly)
        sut.addBudget(budget)
        
        // When
        budget.amount = 150
        budget.name = "Updated Monthly"
        sut.updateBudget(budget)
        
        // Then
        XCTAssertEqual(sut.budgets.first?.amount, 150)
        XCTAssertEqual(sut.budgets.first?.name, "Updated Monthly")
    }
    
    // MARK: - Budget Deletion Tests
    
    func testDeleteBudget() {
        // Given
        let budget = Budget(name: "Test", category: .other, amount: 100, period: .monthly)
        sut.addBudget(budget)
        XCTAssertEqual(sut.budgets.count, 1)
        
        // When
        sut.deleteBudget(budget)
        
        // Then
        XCTAssertEqual(sut.budgets.count, 0)
    }
    
    // MARK: - Spending Calculation Tests
    
    func testCalculateSpending() async {
        // Given
        let budget = Budget(name: "Electronics", category: .electronics, amount: 1000, period: .monthly)
        sut.addBudget(budget)
        
        let items = [
            Item(name: "Phone", category: .electronics, purchasePrice: 699.99, purchaseDate: Date()),
            Item(name: "Headphones", category: .electronics, purchasePrice: 199.99, purchaseDate: Date()),
            Item(name: "Chair", category: .furniture, purchasePrice: 299.99, purchaseDate: Date())
        ]
        
        // When
        let spending = await sut.calculateSpending(for: budget, items: items)
        
        // Then
        XCTAssertEqual(spending, 899.98, accuracy: 0.01)
    }
    
    func testCalculateSpendingWithNullCategory() async {
        // Given - Budget for all categories
        let budget = Budget(name: "Total", category: nil, amount: 2000, period: .monthly)
        sut.addBudget(budget)
        
        let items = [
            Item(name: "Item1", category: .electronics, purchasePrice: 100, purchaseDate: Date()),
            Item(name: "Item2", category: .furniture, purchasePrice: 200, purchaseDate: Date()),
            Item(name: "Item3", category: .clothing, purchasePrice: 150, purchaseDate: Date())
        ]
        
        // When
        let spending = await sut.calculateSpending(for: budget, items: items)
        
        // Then
        XCTAssertEqual(spending, 450)
    }
    
    func testCalculateSpendingOutsidePeriod() async {
        // Given
        let budget = Budget(name: "Monthly", category: .electronics, amount: 1000, period: .monthly)
        sut.addBudget(budget)
        
        let items = [
            Item(name: "Current", category: .electronics, purchasePrice: 100, purchaseDate: Date()),
            Item(name: "Old", category: .electronics, purchasePrice: 200, purchaseDate: Date().addingTimeInterval(-60 * 24 * 60 * 60)) // 60 days ago
        ]
        
        // When
        let spending = await sut.calculateSpending(for: budget, items: items)
        
        // Then
        XCTAssertEqual(spending, 100) // Only current month item
    }
    
    // MARK: - Budget Status Tests
    
    func testGetBudgetStatus() async {
        // Given
        let budget = Budget(name: "Tech", category: .electronics, amount: 1000, period: .monthly)
        sut.addBudget(budget)
        
        let items = [
            Item(name: "Laptop", category: .electronics, purchasePrice: 800, purchaseDate: Date())
        ]
        
        // When
        let status = await sut.getBudgetStatus(for: budget, items: items)
        
        // Then
        XCTAssertEqual(status.spent, 800)
        XCTAssertEqual(status.remaining, 200)
        XCTAssertEqual(status.percentage, 80)
        XCTAssertEqual(status.status, .warning)
    }
    
    func testBudgetStatusOverspent() async {
        // Given
        let budget = Budget(name: "Small", category: .other, amount: 100, period: .monthly)
        sut.addBudget(budget)
        
        let items = [
            Item(name: "Expensive", category: .other, purchasePrice: 150, purchaseDate: Date())
        ]
        
        // When
        let status = await sut.getBudgetStatus(for: budget, items: items)
        
        // Then
        XCTAssertEqual(status.spent, 150)
        XCTAssertEqual(status.remaining, -50)
        XCTAssertEqual(status.percentage, 150)
        XCTAssertEqual(status.status, .overBudget)
    }
    
    func testBudgetStatusGood() async {
        // Given
        let budget = Budget(name: "Large", category: .other, amount: 1000, period: .monthly)
        sut.addBudget(budget)
        
        let items = [
            Item(name: "Small", category: .other, purchasePrice: 100, purchaseDate: Date())
        ]
        
        // When
        let status = await sut.getBudgetStatus(for: budget, items: items)
        
        // Then
        XCTAssertEqual(status.percentage, 10)
        XCTAssertEqual(status.status, .good)
    }
    
    // MARK: - Alert Tests
    
    func testCheckBudgetAlerts() async {
        // Given
        let budget = Budget(
            name: "Alert Test",
            category: .electronics,
            amount: 1000,
            period: .monthly,
            alertThreshold: 80,
            alertEnabled: true
        )
        sut.addBudget(budget)
        
        let items = [
            Item(name: "Item", category: .electronics, purchasePrice: 850, purchaseDate: Date())
        ]
        
        // When
        let alerts = await sut.checkBudgetAlerts(items: items)
        
        // Then
        XCTAssertEqual(alerts.count, 1)
        XCTAssertEqual(alerts.first?.budgetName, "Alert Test")
        XCTAssertEqual(alerts.first?.percentage, 85)
    }
    
    func testNoAlertsWhenDisabled() async {
        // Given
        var budget = Budget(name: "No Alert", category: .other, amount: 100, period: .monthly)
        budget.alertEnabled = false
        sut.addBudget(budget)
        
        let items = [
            Item(name: "Item", category: .other, purchasePrice: 90, purchaseDate: Date())
        ]
        
        // When
        let alerts = await sut.checkBudgetAlerts(items: items)
        
        // Then
        XCTAssertTrue(alerts.isEmpty)
    }
    
    // MARK: - Period Tests
    
    func testBudgetPeriodDisplayNames() {
        XCTAssertEqual(BudgetService.BudgetPeriod.weekly.displayName, "Weekly")
        XCTAssertEqual(BudgetService.BudgetPeriod.monthly.displayName, "Monthly")
        XCTAssertEqual(BudgetService.BudgetPeriod.quarterly.displayName, "Quarterly")
        XCTAssertEqual(BudgetService.BudgetPeriod.yearly.displayName, "Yearly")
    }
    
    func testBudgetPeriodDateRanges() {
        let now = Date()
        
        // Weekly
        let weeklyRange = BudgetService.BudgetPeriod.weekly.dateRange(from: now)
        let weekDiff = Calendar.current.dateComponents([.day], from: weeklyRange.start, to: weeklyRange.end).day ?? 0
        XCTAssertEqual(weekDiff, 7)
        
        // Monthly
        let monthlyRange = BudgetService.BudgetPeriod.monthly.dateRange(from: now)
        let monthComponents = Calendar.current.dateComponents([.month], from: monthlyRange.start, to: monthlyRange.end)
        XCTAssertEqual(monthComponents.month, 1)
        
        // Quarterly
        let quarterlyRange = BudgetService.BudgetPeriod.quarterly.dateRange(from: now)
        let quarterComponents = Calendar.current.dateComponents([.month], from: quarterlyRange.start, to: quarterlyRange.end)
        XCTAssertEqual(quarterComponents.month, 3)
        
        // Yearly
        let yearlyRange = BudgetService.BudgetPeriod.yearly.dateRange(from: now)
        let yearComponents = Calendar.current.dateComponents([.year], from: yearlyRange.start, to: yearlyRange.end)
        XCTAssertEqual(yearComponents.year, 1)
    }
}