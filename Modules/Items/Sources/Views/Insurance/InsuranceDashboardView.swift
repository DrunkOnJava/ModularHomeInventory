//
//  InsuranceDashboardView.swift
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
//  Dependencies: SwiftUI, Core, SharedUI, Charts
//  Testing: ItemsTests/Insurance/InsuranceDashboardViewTests.swift
//
//  Description: Comprehensive insurance dashboard displaying policy information, coverage
//  analysis, claim management, and coverage gap identification with interactive charts
//  and detailed insurance portfolio management features.
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core
import SharedUI
import Charts

public struct InsuranceDashboardView: View {
    @StateObject private var viewModel: InsuranceDashboardViewModel
    @State private var showingAddPolicy = false
    @State private var selectedPolicy: InsurancePolicy?
    @State private var showingCoverageAnalysis = false
    
    public init(
        itemRepository: any ItemRepository,
        insuranceRepository: InsurancePolicyRepository
    ) {
        self._viewModel = StateObject(wrappedValue: InsuranceDashboardViewModel(
            itemRepository: itemRepository,
            insuranceRepository: insuranceRepository
        ))
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Coverage Overview
                coverageOverviewSection
                
                // Premium Summary
                premiumSummarySection
                
                // Active Policies
                activePoliciesSection
                
                // Coverage by Category Chart
                coverageByCategoryChart
                
                // Recommendations
                if !viewModel.recommendations.isEmpty {
                    recommendationsSection
                }
                
                // Claims Summary
                if viewModel.claimAnalysis.totalClaims > 0 {
                    claimsSummarySection
                }
            }
            .appPadding()
        }
        .background(AppColors.background)
        .navigationTitle("Insurance")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingAddPolicy = true
                    } label: {
                        Label("Add Policy", systemImage: "plus")
                    }
                    
                    Button {
                        showingCoverageAnalysis = true
                    } label: {
                        Label("Coverage Analysis", systemImage: "chart.pie")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddPolicy) {
            NavigationView {
                // Add Insurance Policy View would go here
                Text("Add Insurance Policy")
                    .navigationTitle("Add Policy")
            }
        }
        .sheet(item: $selectedPolicy) { policy in
            NavigationView {
                // Insurance Policy Detail View would go here
                VStack {
                    Text("Policy Details")
                    Text(policy.provider)
                        .font(.headline)
                    Text(policy.policyNumber)
                        .font(.subheadline)
                }
                .navigationTitle("Policy Details")
            }
        }
        .sheet(isPresented: $showingCoverageAnalysis) {
            NavigationView {
                // Coverage Analysis View would go here
                VStack {
                    Text("Coverage Analysis")
                        .font(.title2)
                    if viewModel.coverageAnalysis != nil {
                        Text("Total Coverage: \(viewModel.coverageAnalysis.coveragePercentage, format: .percent)")
                    }
                }
                .navigationTitle("Coverage Analysis")
            }
        }
        .task {
            await viewModel.loadData()
        }
    }
    
    // MARK: - Sections
    
    private var coverageOverviewSection: some View {
        VStack(spacing: AppSpacing.md) {
            Text("Coverage Overview")
                .textStyle(.headlineSmall)
                .foregroundStyle(AppColors.textPrimary)
            
            VStack(spacing: AppSpacing.sm) {
                // Coverage percentage indicator
                HStack {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("\(Int(viewModel.coverageAnalysis.coveragePercentage * 100))%")
                            .textStyle(.headlineLarge)
                            .foregroundStyle(AppColors.primary)
                        Text("Items Covered")
                            .textStyle(.bodySmall)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Coverage bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppColors.surface)
                            
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppColors.primary)
                                .frame(width: geometry.size.width * viewModel.coverageAnalysis.coveragePercentage)
                        }
                    }
                    .frame(height: 24)
                    .frame(maxWidth: 200)
                }
                
                Divider()
                
                // Coverage stats
                HStack {
                    StatItem(
                        value: viewModel.coverageAnalysis.totalItemValue,
                        label: "Total Value",
                        format: .currency
                    )
                    
                    Spacer()
                    
                    StatItem(
                        value: viewModel.coverageAnalysis.coveredValue,
                        label: "Covered Value",
                        format: .currency,
                        color: AppColors.success
                    )
                    
                    Spacer()
                    
                    StatItem(
                        value: viewModel.coverageAnalysis.uncoveredValue,
                        label: "Uncovered",
                        format: .currency,
                        color: AppColors.error
                    )
                }
            }
            .appPadding()
            .background(AppColors.surface)
            .cornerRadius(AppCornerRadius.medium)
        }
    }
    
    private var premiumSummarySection: some View {
        VStack(spacing: AppSpacing.md) {
            Text("Premium Summary")
                .textStyle(.headlineSmall)
                .foregroundStyle(AppColors.textPrimary)
            
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(viewModel.premiumAnalysis.monthlyAverage, format: .currency(code: "USD"))
                        .textStyle(.headlineMedium)
                        .foregroundStyle(AppColors.primary)
                    Text("Monthly Average")
                        .textStyle(.bodySmall)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                    Text(viewModel.premiumAnalysis.totalAnnualPremium, format: .currency(code: "USD"))
                        .textStyle(.headlineMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    Text("Annual Total")
                        .textStyle(.bodySmall)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .appPadding()
            .background(AppColors.surface)
            .cornerRadius(AppCornerRadius.medium)
        }
    }
    
    private var activePoliciesSection: some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                Text("Active Policies")
                    .textStyle(.headlineSmall)
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Text("\(viewModel.activePolicies.count)")
                    .textStyle(.labelMedium)
                    .foregroundStyle(AppColors.textSecondary)
            }
            
            ForEach(viewModel.activePolicies) { policy in
                InsurancePolicyRow(policy: policy)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedPolicy = policy
                    }
            }
        }
    }
    
    private var coverageByCategoryChart: some View {
        VStack(spacing: AppSpacing.md) {
            Text("Coverage by Category")
                .textStyle(.headlineSmall)
                .foregroundStyle(AppColors.textPrimary)
            
            Chart(Array(viewModel.categoryBreakdown.enumerated()), id: \.offset) { index, item in
                BarMark(
                    x: .value("Category", item.category.displayName),
                    y: .value("Value", item.coveredValue)
                )
                .foregroundStyle(AppColors.primary)
                
                BarMark(
                    x: .value("Category", item.category.displayName),
                    y: .value("Value", item.uncoveredValue),
                    stacking: .standard
                )
                .foregroundStyle(AppColors.error.opacity(0.5))
            }
            .frame(height: 200)
            .appPadding()
            .background(AppColors.surface)
            .cornerRadius(AppCornerRadius.medium)
        }
    }
    
    private var recommendationsSection: some View {
        VStack(spacing: AppSpacing.md) {
            Text("Recommendations")
                .textStyle(.headlineSmall)
                .foregroundStyle(AppColors.textPrimary)
            
            ForEach(viewModel.recommendations.prefix(3), id: \.title) { recommendation in
                RecommendationCard(recommendation: recommendation)
            }
            
            if viewModel.recommendations.count > 3 {
                Button("View All Recommendations") {
                    showingCoverageAnalysis = true
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.textSecondary)
            }
        }
    }
    
    private var claimsSummarySection: some View {
        VStack(spacing: AppSpacing.md) {
            Text("Claims History")
                .textStyle(.headlineSmall)
                .foregroundStyle(AppColors.textPrimary)
            
            VStack(spacing: AppSpacing.sm) {
                HStack {
                    StatItem(
                        value: Double(viewModel.claimAnalysis.totalClaims),
                        label: "Total Claims",
                        format: .number
                    )
                    
                    Spacer()
                    
                    StatItem(
                        value: viewModel.claimAnalysis.totalPaidAmount,
                        label: "Total Paid",
                        format: .currency
                    )
                    
                    Spacer()
                    
                    StatItem(
                        value: viewModel.claimAnalysis.approvalRate * 100,
                        label: "Approval Rate",
                        format: .percent
                    )
                }
            }
            .appPadding()
            .background(AppColors.surface)
            .cornerRadius(AppCornerRadius.medium)
        }
    }
}

// MARK: - Supporting Views

struct InsurancePolicyRow: View {
    let policy: InsurancePolicy
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Type icon
            Image(systemName: policy.type.icon)
                .font(.title3)
                .foregroundStyle(AppColors.primary)
                .frame(width: 44, height: 44)
                .background(AppColors.primaryMuted)
                .cornerRadius(AppCornerRadius.small)
            
            // Policy info
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(policy.provider)
                    .textStyle(.bodyLarge)
                    .foregroundStyle(AppColors.textPrimary)
                
                Text(policy.policyNumber)
                    .textStyle(.bodySmall)
                    .foregroundStyle(AppColors.textSecondary)
            }
            
            Spacer()
            
            // Status and premium
            VStack(alignment: .trailing, spacing: AppSpacing.xxs) {
                StatusBadge(status: policy.status)
                
                Text(policy.premium.amount, format: .currency(code: "USD"))
                    .textStyle(.bodySmall)
                    .foregroundStyle(AppColors.textSecondary)
                Text(" /\(policy.premium.frequency.displayName.lowercased())")
                    .textStyle(.bodySmall)
                    .foregroundStyle(AppColors.textSecondary)
                    .textStyle(.labelSmall)
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
        .appPadding()
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.medium)
    }
}

struct StatusBadge: View {
    let status: PolicyStatus
    
    var body: some View {
        Text(status.displayName)
            .textStyle(.labelSmall)
            .appPadding(.horizontal, AppSpacing.sm)
            .appPadding(.vertical, AppSpacing.xxs)
            .background(Color(status.color).opacity(0.1))
            .foregroundStyle(Color(status.color))
            .cornerRadius(AppCornerRadius.small)
    }
}

struct RecommendationCard: View {
    let recommendation: CoverageRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Image(systemName: iconForType(recommendation.type))
                    .foregroundStyle(colorForPriority(recommendation.priority))
                
                Text(recommendation.title)
                    .textStyle(.bodyLarge)
                    .foregroundStyle(AppColors.textPrimary)
                
                Spacer()
            }
            
            Text(recommendation.description)
                .textStyle(.bodySmall)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            
            if let savings = recommendation.estimatedSavings {
                Text("Potential savings: \(savings, format: .currency(code: "USD"))")
                    .textStyle(.labelSmall)
                    .foregroundStyle(AppColors.success)
            }
        }
        .appPadding()
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.medium)
    }
    
    private func iconForType(_ type: InsuranceRecommendationType) -> String {
        switch type {
        case .addCoverage: return "plus.circle"
        case .increaseCoverage: return "arrow.up.circle"
        case .consolidate: return "arrow.triangle.merge"
        case .renew: return "arrow.clockwise"
        case .review: return "magnifyingglass"
        }
    }
    
    private func colorForPriority(_ priority: InsuranceRecommendationPriority) -> Color {
        switch priority {
        case .low: return AppColors.textSecondary
        case .medium: return AppColors.warning
        case .high: return AppColors.error
        }
    }
}

struct StatItem: View {
    let value: Any
    let label: String
    var format: Format = .number
    var color: Color = AppColors.textPrimary
    
    enum Format {
        case number
        case currency
        case percent
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: AppSpacing.xxs) {
            Group {
                switch format {
                case .number:
                    if let intValue = value as? Int {
                        Text("\(intValue)")
                    } else if let doubleValue = value as? Double {
                        Text("\(Int(doubleValue))")
                    }
                case .currency:
                    if let decimalValue = value as? Decimal {
                        Text(decimalValue, format: .currency(code: "USD"))
                    }
                case .percent:
                    if let doubleValue = value as? Double {
                        Text("\(Int(doubleValue))%")
                    }
                }
            }
            .textStyle(.bodyLarge)
            .foregroundStyle(color)
            
            Text(label)
                .textStyle(.labelSmall)
                .foregroundStyle(AppColors.textSecondary)
        }
    }
}