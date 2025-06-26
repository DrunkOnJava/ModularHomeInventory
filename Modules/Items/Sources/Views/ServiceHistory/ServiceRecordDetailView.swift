//
//  ServiceRecordDetailView.swift
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
//  Testing: ItemsTests/ServiceRecordDetailViewTests.swift
//
//  Description: Detail view for displaying service record information
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core
import SharedUI

struct ServiceRecordDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingEdit = false
    @State private var showingDelete = false
    
    let record: ServiceRecord
    let item: Item
    let serviceRepository: ServiceRecordRepository
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                // Header
                headerSection
                
                // Provider Info
                providerSection
                
                // Service Details
                detailsSection
                
                // Cost Information
                if record.cost != nil || record.wasUnderWarranty {
                    costSection
                }
                
                // Additional Info
                if record.mileage != nil || record.hoursUsed != nil {
                    additionalInfoSection
                }
                
                // Next Service
                if let nextDate = record.nextServiceDate {
                    nextServiceSection(nextDate)
                }
                
                // Documents
                if !record.documentIds.isEmpty {
                    documentsSection
                }
            }
            .appPadding()
        }
        .background(AppColors.background)
        .navigationTitle("Service Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingEdit = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        showingDelete = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            // Edit view would go here
            Text("Edit Service Record")
        }
        .alert("Delete Service Record", isPresented: $showingDelete) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    try? await serviceRepository.delete(record)
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete this service record? This action cannot be undone.")
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Image(systemName: record.type.icon)
                    .font(.title2)
                    .foregroundStyle(Color(record.type.color))
                    .frame(width: 50, height: 50)
                    .background(Color(record.type.color).opacity(0.1))
                    .cornerRadius(AppCornerRadius.medium)
                
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(record.type.displayName)
                        .textStyle(.headlineMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Text(record.date, format: .dateTime.month().day().year())
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                Spacer()
            }
            
            Text(record.description)
                .textStyle(.bodyLarge)
                .foregroundStyle(AppColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .appPadding()
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.medium)
    }
    
    private var providerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Provider")
                .textStyle(.labelMedium)
                .foregroundStyle(AppColors.textSecondary)
            
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                ServiceLabeledContent("Company", value: record.provider)
                
                if let technician = record.technician {
                    ServiceLabeledContent("Technician", value: technician)
                }
            }
            .appPadding()
            .background(AppColors.surface)
            .cornerRadius(AppCornerRadius.medium)
        }
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Details")
                .textStyle(.labelMedium)
                .foregroundStyle(AppColors.textSecondary)
            
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                if let notes = record.notes {
                    Text(notes)
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .appPadding()
            .background(AppColors.surface)
            .cornerRadius(AppCornerRadius.medium)
        }
    }
    
    private var costSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Cost")
                .textStyle(.labelMedium)
                .foregroundStyle(AppColors.textSecondary)
            
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                if record.wasUnderWarranty {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(AppColors.success)
                        Text("Covered under warranty")
                            .textStyle(.bodyMedium)
                            .foregroundStyle(AppColors.success)
                    }
                }
                
                if let cost = record.cost, cost > 0 {
                    ServiceLabeledContentView("Service Cost") {
                        Text(cost, format: .currency(code: "USD"))
                            .textStyle(.bodyLarge)
                            .foregroundStyle(AppColors.primary)
                    }
                }
            }
            .appPadding()
            .background(AppColors.surface)
            .cornerRadius(AppCornerRadius.medium)
        }
    }
    
    private var additionalInfoSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Additional Information")
                .textStyle(.labelMedium)
                .foregroundStyle(AppColors.textSecondary)
            
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                if let mileage = record.mileage {
                    ServiceLabeledContent("Mileage", value: "\(mileage.formatted()) miles")
                }
                
                if let hours = record.hoursUsed {
                    ServiceLabeledContent("Hours Used", value: "\(hours.formatted()) hours")
                }
            }
            .appPadding()
            .background(AppColors.surface)
            .cornerRadius(AppCornerRadius.medium)
        }
    }
    
    private func nextServiceSection(_ date: Date) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Next Service")
                .textStyle(.labelMedium)
                .foregroundStyle(AppColors.textSecondary)
            
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.title3)
                    .foregroundStyle(AppColors.primary)
                
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(date, format: .dateTime.month().day().year())
                        .textStyle(.bodyLarge)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
                    if daysUntil > 0 {
                        Text("In \(daysUntil) days")
                            .textStyle(.bodySmall)
                            .foregroundStyle(AppColors.textSecondary)
                    } else if daysUntil == 0 {
                        Text("Due today")
                            .textStyle(.bodySmall)
                            .foregroundStyle(AppColors.warning)
                    } else {
                        Text("Overdue by \(abs(daysUntil)) days")
                            .textStyle(.bodySmall)
                            .foregroundStyle(AppColors.error)
                    }
                }
                
                Spacer()
            }
            .appPadding()
            .background(AppColors.primaryMuted)
            .cornerRadius(AppCornerRadius.medium)
        }
    }
    
    private var documentsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Documents")
                .textStyle(.labelMedium)
                .foregroundStyle(AppColors.textSecondary)
            
            Text("\(record.documentIds.count) attached documents")
                .textStyle(.bodyMedium)
                .foregroundStyle(AppColors.textSecondary)
                .appPadding()
                .background(AppColors.surface)
                .cornerRadius(AppCornerRadius.medium)
        }
    }
}

// MARK: - Supporting Views

private struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .textStyle(.labelLarge)
            .foregroundStyle(AppColors.textSecondary)
            .textCase(.uppercase)
    }
}

private struct ServiceLabeledContent: View {
    let label: String
    let value: String
    
    init(_ label: String, value: String) {
        self.label = label
        self.value = value
    }
    
    var body: some View {
        HStack {
            Text(label)
                .textStyle(.bodyMedium)
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
            Text(value)
                .textStyle(.bodyMedium)
                .foregroundStyle(AppColors.textPrimary)
        }
    }
}

private struct ServiceLabeledContentView<Content: View>: View {
    let label: String
    let content: () -> Content
    
    init(_ label: String, @ViewBuilder content: @escaping () -> Content) {
        self.label = label
        self.content = content
    }
    
    var body: some View {
        HStack {
            Text(label)
                .textStyle(.bodyMedium)
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
            content()
        }
    }
}