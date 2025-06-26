//
//  ItemShareView.swift
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
//  Testing: ItemsTests/ItemShareViewTests.swift
//
//  Description: View for sharing item information with others
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core
import SharedUI

/// View for sharing an item
/// Swift 5.9 - No Swift 6 features
struct ItemShareView: View {
    let item: Item
    let sharingService: ItemSharingService
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFormat = ItemSharingService.ShareFormat.text
    @State private var isGenerating = false
    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Format selection
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("Choose Share Format")
                        .textStyle(.headlineMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    ForEach(ItemSharingService.ShareFormat.allCases, id: \.self) { format in
                        ShareFormatRow(
                            format: format,
                            isSelected: selectedFormat == format,
                            action: { selectedFormat = format }
                        )
                    }
                }
                .appPadding()
                
                Spacer()
                
                // Preview section
                SharePreviewSection(
                    item: item,
                    format: selectedFormat,
                    sharingService: sharingService
                )
                
                // Share button
                PrimaryButton(
                    title: "Share",
                    isLoading: isGenerating,
                    action: shareItem
                )
                .appPadding()
            }
            .background(AppColors.background)
            .navigationTitle("Share Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if !shareItems.isEmpty {
                    ShareSheet(items: shareItems)
                }
            }
            .alert("Share Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func shareItem() {
        isGenerating = true
        
        Task {
            do {
                let content = try await sharingService.generateShareContent(
                    for: item,
                    format: selectedFormat
                )
                
                // For QR codes, we need to wrap in a share sheet
                if selectedFormat == .qrCode {
                    shareItems = [content]
                } else if let fileURL = try? await sharingService.createShareFile(
                    for: item,
                    format: selectedFormat
                ) {
                    shareItems = [fileURL]
                } else {
                    shareItems = [content]
                }
                
                await MainActor.run {
                    isGenerating = false
                    showingShareSheet = true
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct ShareFormatRow: View {
    let format: ItemSharingService.ShareFormat
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: format.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? AppColors.primary : AppColors.textSecondary)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(format.rawValue)
                        .textStyle(.bodyLarge)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Text(format.description)
                        .textStyle(.bodySmall)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppColors.primary)
                }
            }
            .appPadding()
            .background(isSelected ? AppColors.primaryMuted : AppColors.surface)
            .cornerRadius(AppCornerRadius.medium)
        }
        .buttonStyle(.plain)
    }
}

struct SharePreviewSection: View {
    let item: Item
    let format: ItemSharingService.ShareFormat
    let sharingService: ItemSharingService
    @State private var previewContent: String = ""
    @State private var previewImage: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Preview")
                .textStyle(.labelLarge)
                .foregroundStyle(AppColors.textSecondary)
                .appPadding(.horizontal)
            
            ScrollView {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if format == .qrCode, let image = previewImage {
                    Image(uiImage: image)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(maxWidth: 300, maxHeight: 300)
                        .frame(maxWidth: .infinity)
                        .appPadding()
                } else {
                    Text(previewContent)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .appPadding()
                        .background(AppColors.secondaryBackground)
                        .appPadding(.horizontal)
                }
            }
            .frame(maxHeight: 300)
        }
        .task(id: format) {
            await loadPreview()
        }
    }
    
    private func loadPreview() async {
        isLoading = true
        previewContent = ""
        previewImage = nil
        
        do {
            let content = try await sharingService.generateShareContent(
                for: item,
                format: format
            )
            
            await MainActor.run {
                if let text = content as? String {
                    previewContent = text
                } else if let image = content as? UIImage {
                    previewImage = image
                }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                previewContent = "Preview generation failed"
                isLoading = false
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        
        // Exclude certain activities
        controller.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList,
            .openInIBooks
        ]
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}