//
//  OfflineScanQueueView.swift
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
//  Module: BarcodeScanner
//  Dependencies: SwiftUI, Core, SharedUI
//  Testing: Modules/BarcodeScanner/Tests/ScannerTests/OfflineScanQueueViewTests.swift
//
//  Description: View for displaying and managing offline scan queue with processing
//               status and retry capabilities
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core
import SharedUI

/// View for displaying and managing offline scan queue
/// Swift 5.9 - No Swift 6 features
public struct OfflineScanQueueView: View {
    @StateObject private var offlineScanService: OfflineScanService
    @State private var showingClearAlert = false
    
    public init(offlineScanService: OfflineScanService) {
        self._offlineScanService = StateObject(wrappedValue: offlineScanService)
    }
    
    public var body: some View {
        NavigationView {
            Group {
                if offlineScanService.pendingScans.isEmpty {
                    emptyView
                } else {
                    queueList
                }
            }
            .navigationTitle("Offline Queue")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !offlineScanService.pendingScans.isEmpty {
                        Menu {
                            Button(action: { Task { await offlineScanService.processQueue() } }) {
                                Label("Process Queue", systemImage: "arrow.clockwise")
                            }
                            .disabled(offlineScanService.isProcessing)
                            
                            Button(action: { showingClearAlert = true }) {
                                Label("Clear Completed", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .alert("Clear Completed Scans", isPresented: $showingClearAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    Task {
                        try? await offlineScanService.clearCompleted()
                    }
                }
            } message: {
                Text("Remove all completed scans from the queue?")
            }
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 60))
                .foregroundStyle(AppColors.textSecondary)
            
            Text("No Offline Scans")
                .textStyle(.headlineMedium)
            
            Text("Scans will be queued here when you're offline")
                .textStyle(.bodyMedium)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .appPadding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var queueList: some View {
        List {
            if offlineScanService.isProcessing {
                Section {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Processing queue...")
                            .textStyle(.bodyMedium)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .appPadding(.vertical, AppSpacing.xs)
                }
            }
            
            ForEach(offlineScanService.pendingScans) { entry in
                OfflineScanQueueRow(
                    entry: entry,
                    onRetry: {
                        Task {
                            await offlineScanService.retryScan(id: entry.id)
                        }
                    }
                )
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Queue Row View
struct OfflineScanQueueRow: View {
    let entry: OfflineScanQueueEntry
    let onRetry: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                Image(systemName: "barcode")
                    .foregroundStyle(statusColor)
                
                Text(entry.barcode)
                    .textStyle(.bodyLarge)
                    .fontDesign(.monospaced)
                
                Spacer()
                
                statusView
            }
            
            HStack {
                Text(entry.scanDate, style: .relative)
                    .textStyle(.bodySmall)
                    .foregroundStyle(AppColors.textSecondary)
                
                if entry.retryCount > 0 {
                    Text("•")
                        .foregroundStyle(AppColors.textSecondary)
                    Text("Retries: \(entry.retryCount)")
                        .textStyle(.bodySmall)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            
            if let error = entry.errorMessage {
                Text(error)
                    .textStyle(.bodySmall)
                    .foregroundStyle(AppColors.error)
                    .lineLimit(2)
            }
        }
        .appPadding(.vertical, AppSpacing.xs)
        .swipeActions(edge: .trailing) {
            if entry.status == .failed {
                Button("Retry") {
                    onRetry()
                }
                .tint(AppColors.primary)
            }
        }
    }
    
    private var statusColor: Color {
        switch entry.status {
        case .pending:
            return AppColors.textSecondary
        case .processing:
            return AppColors.primary
        case .completed:
            return AppColors.success
        case .failed:
            return AppColors.error
        }
    }
    
    @ViewBuilder
    private var statusView: some View {
        switch entry.status {
        case .pending:
            Image(systemName: "clock")
                .foregroundStyle(AppColors.textSecondary)
        case .processing:
            ProgressView()
                .scaleEffect(0.7)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppColors.success)
        case .failed:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(AppColors.error)
        }
    }
}