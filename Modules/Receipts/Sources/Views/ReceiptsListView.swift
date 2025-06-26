//
//  ReceiptsListView.swift
//  Receipts Module
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
//  Module: Receipts
//  Dependencies: SwiftUI, Core, SharedUI
//  Testing: ReceiptsTests/ReceiptsListViewTests.swift
//
//  Description: Main receipts list view with grouping and empty state handling
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core
import SharedUI

/// Main receipts list view
/// Swift 5.9 - No Swift 6 features
struct ReceiptsListView: View {
    @StateObject private var viewModel: ReceiptsListViewModel
    @State private var showingImport = false
    
    init(viewModel: ReceiptsListViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.receipts.isEmpty {
                ProgressView("Loading receipts...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.receipts.isEmpty {
                emptyStateView
            } else {
                receiptsList
            }
        }
        .sheet(isPresented: $showingImport) {
            if let addView = viewModel.makeAddReceiptView() {
                addView
            }
        }
        .task {
            await viewModel.loadReceipts()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(AppColors.textTertiary)
            
            Text("No Receipts Yet")
                .textStyle(.headlineMedium)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Import receipts from emails or scan them to get started")
                .textStyle(.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .appPadding(.horizontal)
            
            PrimaryButton(title: "Import Receipt", action: { showingImport = true })
                .appPadding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var receiptsList: some View {
        List {
            ForEach(viewModel.groupedReceipts, id: \.key) { section in
                Section(header: Text(section.key).textStyle(.labelMedium)) {
                    ForEach(section.value) { receipt in
                        NavigationLink(destination: destinationView(for: receipt)) {
                            ReceiptRowView(receipt: receipt)
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .refreshable {
            await viewModel.loadReceipts()
        }
    }
    
    @ViewBuilder
    private func destinationView(for receipt: Receipt) -> some View {
        if let detailView = viewModel.makeReceiptDetailView(for: receipt) {
            detailView
        } else {
            Text("Unable to load receipt details")
        }
    }
}

/// Individual receipt row
struct ReceiptRowView: View {
    let receipt: Receipt
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(receipt.storeName)
                    .textStyle(.bodyLarge)
                    .foregroundColor(AppColors.textPrimary)
                
                HStack {
                    Text(receipt.date, style: .date)
                        .textStyle(.labelSmall)
                        .foregroundColor(AppColors.textSecondary)
                    
                    if receipt.confidence < 0.8 {
                        Label("Low confidence", systemImage: "exclamationmark.triangle.fill")
                            .textStyle(.labelSmall)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                Text("$\(NSDecimalNumber(decimal: receipt.totalAmount).doubleValue, specifier: "%.2f")")
                    .textStyle(.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.primary)
                
                Text("\(receipt.itemIds.count) items")
                    .textStyle(.labelSmall)
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .padding(.vertical, AppSpacing.sm)
    }
}