//
//  ScannerTabView.swift
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
//  Dependencies: SwiftUI, UIKit, Core, SharedUI, AppSettings
//  Testing: Modules/BarcodeScanner/Tests/ScannerTests/ScannerTabViewTests.swift
//
//  Description: Main scanner tab view with options for barcode and document scanning,
//               including scan history and offline queue access
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import UIKit
import Core
import SharedUI
import AppSettings

/// Main scanner tab view with options for barcode and document scanning
/// Swift 5.9 - No Swift 6 features
public struct ScannerTabView: View {
    @State private var scanMode: ScanMode = .barcode
    @State private var showingScanner = false
    @State private var showingHistory = false
    @State private var showingOfflineQueue = false
    @State private var lastScannedCode: String?
    @State private var lastScannedImage: UIImage?
    
    private let scanHistoryRepository: any ScanHistoryRepository
    private let itemRepository: any ItemRepository
    private let offlineScanService: OfflineScanService?
    
    public init(
        scanHistoryRepository: any ScanHistoryRepository,
        itemRepository: any ItemRepository,
        offlineScanService: OfflineScanService? = nil
    ) {
        self.scanHistoryRepository = scanHistoryRepository
        self.itemRepository = itemRepository
        self.offlineScanService = offlineScanService
    }
    
    enum ScanMode: String, CaseIterable {
        case barcode = "Barcode"
        case document = "Document"
        
        var icon: String {
            switch self {
            case .barcode: return "barcode"
            case .document: return "doc.text.viewfinder"
            }
        }
        
        var description: String {
            switch self {
            case .barcode: return "Scan product barcodes to quickly add items"
            case .document: return "Scan receipts and documents"
            }
        }
    }
    
    public var body: some View {
        VStack(spacing: AppSpacing.lg) {
                // Mode selector
                Picker("Scan Mode", selection: $scanMode) {
                    ForEach(ScanMode.allCases, id: \.self) { mode in
                        Label(mode.rawValue, systemImage: mode.icon)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .appPadding(.horizontal)
                
                // Mode description
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: scanMode.icon)
                        .font(.system(size: 80))
                        .foregroundStyle(AppColors.primary)
                    
                    Text(scanMode.description)
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .appPadding(.horizontal)
                }
                .appPadding(.vertical, AppSpacing.xl)
                
                // Scan button
                PrimaryButton(title: "Start Scanning") {
                    showingScanner = true
                }
                .frame(maxWidth: 300)
                
                // Last scanned result
                if lastScannedCode != nil || lastScannedImage != nil {
                    lastScannedResultView
                        .appPadding()
                }
                
                Spacer()
            }
            .navigationTitle("Scanner")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingHistory = true }) {
                            Label("Scan History", systemImage: "clock.arrow.circlepath")
                        }
                        
                        if offlineScanService != nil {
                            Button(action: { showingOfflineQueue = true }) {
                                Label("Offline Queue", systemImage: "wifi.slash")
                                if let count = offlineScanService?.pendingCount, count > 0 {
                                    Text("\(count)")
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingScanner) {
                scannerSheet
            }
            .sheet(isPresented: $showingHistory) {
                ScanHistoryView(
                    scanHistoryRepository: scanHistoryRepository,
                    itemRepository: itemRepository
                )
            }
            .sheet(isPresented: $showingOfflineQueue) {
                if let offlineScanService = offlineScanService {
                    OfflineScanQueueView(offlineScanService: offlineScanService)
                }
            }
        }
    
    @ViewBuilder
    private var scannerSheet: some View {
        switch scanMode {
        case .barcode:
            BarcodeScannerView(viewModel: BarcodeScannerViewModel(
                soundService: SoundFeedbackService(settingsStorage: UserDefaultsSettingsStorage()),
                settingsStorage: UserDefaultsSettingsStorage(),
                scanHistoryRepository: scanHistoryRepository,
                completion: { code in
                    lastScannedCode = code
                    showingScanner = false
                }
            ))
        case .document:
            // For now, show a placeholder
            DocumentScannerPlaceholder { image in
                lastScannedImage = image
                showingScanner = false
            }
        }
    }
    
    @ViewBuilder
    private var lastScannedResultView: some View {
        VStack(spacing: AppSpacing.sm) {
            Text("Last Scanned")
                .textStyle(.labelLarge)
                .foregroundStyle(AppColors.textSecondary)
            
            if let code = lastScannedCode {
                HStack {
                    Image(systemName: "barcode")
                    Text(code)
                        .textStyle(.bodyMedium)
                        .fontDesign(.monospaced)
                }
                .appPadding()
                .background(AppColors.surface)
                .cornerRadius(8)
            }
            
            if let image = lastScannedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(8)
            }
        }
    }
}

// MARK: - Placeholder Views

struct BarcodeScannerPlaceholder: View {
    let completion: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.lg) {
                FeatureUnavailableView(
                    feature: "Barcode Scanner",
                    reason: "Camera integration coming soon",
                    icon: "barcode.viewfinder"
                )
                
                // Simulate a scan for testing
                PrimaryButton(title: "Simulate Scan") {
                    completion("123456789012")
                }
                .frame(maxWidth: 200)
            }
            .navigationTitle("Scan Barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DocumentScannerPlaceholder: View {
    let completion: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.lg) {
                FeatureUnavailableView(
                    feature: "Document Scanner",
                    reason: "Document scanning coming soon",
                    icon: "doc.text.viewfinder"
                )
                
                // Simulate a scan for testing
                PrimaryButton(title: "Simulate Scan") {
                    // Create a placeholder image
                    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 400))
                    let image = renderer.image { context in
                        UIColor.systemGray5.setFill()
                        context.fill(CGRect(origin: .zero, size: CGSize(width: 300, height: 400)))
                        
                        let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20)]
                        let text = "Receipt Placeholder"
                        let textSize = text.size(withAttributes: attributes)
                        let textRect = CGRect(
                            x: (300 - textSize.width) / 2,
                            y: (400 - textSize.height) / 2,
                            width: textSize.width,
                            height: textSize.height
                        )
                        text.draw(in: textRect, withAttributes: attributes)
                    }
                    completion(image)
                }
                .frame(maxWidth: 200)
            }
            .navigationTitle("Scan Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}