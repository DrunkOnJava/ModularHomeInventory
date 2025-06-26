//
//  WarrantyDetailView.swift
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
//  Testing: ItemsTests/WarrantyDetailViewTests.swift
//
//  Description: Detail view for displaying warranty information and status
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core
import SharedUI

/// Detailed view for a single warranty
/// Swift 5.9 - No Swift 6 features
struct WarrantyDetailView: View {
    let warranty: Warranty
    let itemRepository: any ItemRepository
    let warrantyRepository: any WarrantyRepository
    
    @State private var item: Item?
    @State private var showingEditWarranty = false
    @State private var showingDeleteAlert = false
    @State private var showingContactOptions = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Status card
                    statusCard
                    
                    // Coverage details
                    if warranty.coverageDetails != nil {
                        coverageDetailsCard
                    }
                    
                    // Contact information
                    contactCard
                    
                    // Documents
                    if !warranty.documentIds.isEmpty {
                        documentsCard
                    }
                    
                    // Additional info
                    additionalInfoCard
                    
                    // Delete button
                    deleteButton
                }
                .padding(AppSpacing.md)
            }
            .background(AppColors.background)
            .navigationTitle("Warranty Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showingEditWarranty = true
                    }
                }
            }
            .onAppear {
                loadItem()
            }
            .sheet(isPresented: $showingEditWarranty) {
                // Edit warranty view would go here
                Text("Edit Warranty")
            }
            .alert("Delete Warranty?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteWarranty()
                }
            } message: {
                Text("This action cannot be undone.")
            }
            .confirmationDialog("Contact Options", isPresented: $showingContactOptions) {
                if let phone = warranty.phoneNumber {
                    Button("Call \(phone)") {
                        if let url = URL(string: "tel://\(phone.replacingOccurrences(of: " ", with: ""))") {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                
                if let email = warranty.email {
                    Button("Email \(email)") {
                        if let url = URL(string: "mailto:\(email)") {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                
                if let website = warranty.website {
                    Button("Visit Website") {
                        if let url = URL(string: website) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                
                Button("Cancel", role: .cancel) { }
            }
        }
    }
    
    // MARK: - Components
    
    private var statusCard: some View {
        VStack(spacing: AppSpacing.md) {
            // Item info
            if let item = item {
                HStack {
                    Image(systemName: item.category.icon)
                        .font(.title2)
                        .foregroundStyle(AppColors.primary)
                        .frame(width: 50, height: 50)
                        .background(AppColors.primaryMuted)
                        .cornerRadius(AppCornerRadius.medium)
                    
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(item.name)
                            .textStyle(.headlineMedium)
                            .foregroundStyle(AppColors.textPrimary)
                        
                        if let brand = item.brand {
                            Text(brand)
                                .textStyle(.bodyMedium)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                    
                    Spacer()
                }
                
                Divider()
            }
            
            // Warranty status
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(warranty.provider)
                        .textStyle(.headlineMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Label(warranty.type.displayName, systemImage: warranty.type.icon)
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                Spacer()
                
                // Status badge
                VStack(spacing: AppSpacing.xs) {
                    Image(systemName: warranty.status.icon)
                        .font(.title)
                        .foregroundStyle(statusColor)
                    
                    Text(warranty.status.displayName)
                        .textStyle(.labelMedium)
                        .foregroundStyle(statusColor)
                }
            }
            
            // Progress bar
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(AppColors.divider)
                            .frame(height: 8)
                        
                        Rectangle()
                            .fill(statusColor)
                            .frame(width: geometry.size.width * warranty.progress, height: 8)
                    }
                    .cornerRadius(4)
                }
                .frame(height: 8)
                
                HStack {
                    Text(warranty.startDate, style: .date)
                        .textStyle(.labelSmall)
                        .foregroundStyle(AppColors.textSecondary)
                    
                    Spacer()
                    
                    Text(warranty.endDate, style: .date)
                        .textStyle(.labelSmall)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            
            // Days remaining
            if warranty.daysRemaining > 0 {
                Text("\(warranty.daysRemaining) days remaining")
                    .textStyle(.bodyLarge)
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm)
                    .background(statusColor.opacity(0.1))
                    .cornerRadius(AppCornerRadius.small)
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.large)
    }
    
    private var coverageDetailsCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Label("Coverage Details", systemImage: "doc.text")
                .textStyle(.headlineMedium)
                .foregroundStyle(AppColors.textPrimary)
            
            if let details = warranty.coverageDetails {
                Text(details)
                    .textStyle(.bodyMedium)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.large)
    }
    
    private var contactCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Label("Contact Information", systemImage: "phone")
                .textStyle(.headlineMedium)
                .foregroundStyle(AppColors.textPrimary)
            
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                if let phone = warranty.phoneNumber {
                    HStack {
                        Image(systemName: "phone.fill")
                            .foregroundStyle(AppColors.primary)
                            .frame(width: 20)
                        Text(phone)
                            .textStyle(.bodyMedium)
                            .foregroundStyle(AppColors.textPrimary)
                    }
                }
                
                if let email = warranty.email {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(AppColors.primary)
                            .frame(width: 20)
                        Text(email)
                            .textStyle(.bodyMedium)
                            .foregroundStyle(AppColors.textPrimary)
                    }
                }
                
                if let website = warranty.website {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundStyle(AppColors.primary)
                            .frame(width: 20)
                        Text(website)
                            .textStyle(.bodyMedium)
                            .foregroundStyle(AppColors.textPrimary)
                            .lineLimit(1)
                    }
                }
            }
            
            if warranty.phoneNumber != nil || warranty.email != nil || warranty.website != nil {
                Button(action: { showingContactOptions = true }) {
                    Label("Contact Provider", systemImage: "arrow.up.right.square")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.top, AppSpacing.sm)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.large)
    }
    
    private var documentsCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Label("Documents", systemImage: "doc.fill")
                .textStyle(.headlineMedium)
                .foregroundStyle(AppColors.textPrimary)
            
            Text("\(warranty.documentIds.count) attached documents")
                .textStyle(.bodyMedium)
                .foregroundStyle(AppColors.textSecondary)
            
            Button(action: { }) {
                Label("View Documents", systemImage: "doc.text.magnifyingglass")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.large)
    }
    
    private var additionalInfoCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Label("Additional Information", systemImage: "info.circle")
                .textStyle(.headlineMedium)
                .foregroundStyle(AppColors.textPrimary)
            
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                if let registrationNumber = warranty.registrationNumber {
                    InfoRow(label: "Registration #", value: registrationNumber)
                }
                
                if warranty.isExtended {
                    InfoRow(label: "Type", value: "Extended Warranty")
                }
                
                if let cost = warranty.cost {
                    InfoRow(label: "Cost", value: cost.formatted(.currency(code: "USD")))
                }
                
                InfoRow(label: "Added", value: warranty.createdAt.formatted(date: .abbreviated, time: .omitted))
                
                if let notes = warranty.notes {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Notes")
                            .textStyle(.labelMedium)
                            .foregroundStyle(AppColors.textSecondary)
                        Text(notes)
                            .textStyle(.bodyMedium)
                            .foregroundStyle(AppColors.textPrimary)
                    }
                    .padding(.top, AppSpacing.xs)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.large)
    }
    
    private var deleteButton: some View {
        Button(action: { showingDeleteAlert = true }) {
            Label("Delete Warranty", systemImage: "trash")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(AppColors.error)
    }
    
    // MARK: - Helper Views
    
    private struct InfoRow: View {
        let label: String
        let value: String
        
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
    
    // MARK: - Helper Properties
    
    private var statusColor: Color {
        switch warranty.status {
        case .active: return AppColors.success
        case .expiringSoon: return AppColors.warning
        case .expired: return AppColors.error
        }
    }
    
    // MARK: - Actions
    
    private func loadItem() {
        Task {
            do {
                item = try await itemRepository.fetch(id: warranty.itemId)
            } catch {
                print("Error loading item: \(error)")
            }
        }
    }
    
    private func deleteWarranty() {
        Task {
            do {
                try await warrantyRepository.delete(warranty)
                dismiss()
            } catch {
                print("Error deleting warranty: \(error)")
            }
        }
    }
}