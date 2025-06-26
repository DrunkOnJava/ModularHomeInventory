//
//  PDFReportGeneratorView.swift
//  Core
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
//  Dependencies: SwiftUI, PDFKit
//  Testing: CoreTests/PDFReportGeneratorViewTests.swift
//
//  Description: View for generating and sharing PDF reports
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import PDFKit

@available(iOS 15.0, *)
public struct PDFReportGeneratorView: View {
    @StateObject private var reportService = PDFReportService()
    @Environment(\.dismiss) private var dismiss
    
    // Data sources
    let items: [Item]
    let locations: [UUID: Core.Location]
    let warranties: [UUID: Core.Warranty]
    
    // State
    @State private var selectedReportType: ReportTypeSelection = .fullInventory
    @State private var reportOptions = PDFReportService.ReportOptions()
    @State private var selectedCategory: ItemCategory = .electronics
    @State private var selectedLocationId: UUID?
    @State private var highValueThreshold: Decimal = 1000
    @State private var customSelectedItems: Set<UUID> = []
    @State private var showingPreview = false
    @State private var showingShareSheet = false
    @State private var generatedReportURL: URL?
    @State private var showingError = false
    
    private enum ReportTypeSelection: String, CaseIterable {
        case fullInventory = "Full Inventory"
        case category = "By Category"
        case location = "By Location"
        case insurance = "Insurance Documentation"
        case warranty = "Warranty Status"
        case highValue = "High Value Items"
        case custom = "Custom Selection"
        
        var icon: String {
            switch self {
            case .fullInventory: return "doc.text.fill"
            case .category: return "folder.fill"
            case .location: return "location.fill"
            case .insurance: return "shield.fill"
            case .warranty: return "clock.badge.checkmark.fill"
            case .highValue: return "dollarsign.circle.fill"
            case .custom: return "checkmark.circle.fill"
            }
        }
        
        var description: String {
            switch self {
            case .fullInventory:
                return "Generate a complete report of all items in your inventory"
            case .category:
                return "Generate a report for items in a specific category"
            case .location:
                return "Generate a report for items in a specific location"
            case .insurance:
                return "Generate a detailed report suitable for insurance documentation"
            case .warranty:
                return "Generate a report focusing on warranty information"
            case .highValue:
                return "Generate a report of items above a specified value"
            case .custom:
                return "Select specific items to include in the report"
            }
        }
    }
    
    public init(items: [Item], locations: [UUID: Core.Location] = [:], warranties: [UUID: Core.Warranty] = [:]) {
        self.items = items
        self.locations = locations
        self.warranties = warranties
    }
    
    public var body: some View {
        NavigationView {
            Form {
                // Report Type Selection
                Section {
                    Picker("Report Type", selection: $selectedReportType) {
                        ForEach(ReportTypeSelection.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Text(selectedReportType.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Report Type")
                }
                
                // Type-specific options
                Group {
                    switch selectedReportType {
                    case .category:
                        categorySelectionSection
                    case .location:
                        locationSelectionSection
                    case .highValue:
                        highValueSection
                    case .custom:
                        customSelectionSection
                    default:
                        EmptyView()
                    }
                }
                
                // Report Options
                reportOptionsSection
                
                // Preview
                Section {
                    HStack {
                        Image(systemName: "doc.text.magnifyingglass")
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text("Estimated Pages: \(estimatedPageCount)")
                                .font(.subheadline)
                            Text("Items to Include: \(itemsToInclude.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Preview")
                }
                
                // Generate Button
                Section {
                    Button(action: generateReport) {
                        if reportService.isGenerating {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Generating... \(Int(reportService.progress * 100))%")
                            }
                        } else {
                            Label("Generate Report", systemImage: "arrow.down.doc.fill")
                        }
                    }
                    .disabled(reportService.isGenerating || itemsToInclude.isEmpty)
                }
            }
            .navigationTitle("Generate Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let url = reportService.lastGeneratedReport {
                        Button(action: { shareReport(url: url) }) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingPreview) {
                if let url = generatedReportURL {
                    PDFPreviewView(url: url)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = generatedReportURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(reportService.error?.localizedDescription ?? "An error occurred")
            }
        }
    }
    
    // MARK: - Sections
    
    private var categorySelectionSection: some View {
        Section {
            Picker("Category", selection: $selectedCategory) {
                ForEach(ItemCategory.allCases, id: \.self) { category in
                    Label(category.rawValue, systemImage: category.icon)
                        .tag(category)
                }
            }
            
            Text("\(itemsInCategory(selectedCategory).count) items in this category")
                .font(.caption)
                .foregroundColor(.secondary)
        } header: {
            Text("Select Category")
        }
    }
    
    private var locationSelectionSection: some View {
        Section {
            if locations.isEmpty {
                Text("No locations available")
                    .foregroundColor(.secondary)
            } else {
                Picker("Location", selection: $selectedLocationId) {
                    Text("Select a location").tag(nil as UUID?)
                    ForEach(Array(locations.values), id: \.id) { location in
                        Text(location.name).tag(location.id as UUID?)
                    }
                }
                
                if let locationId = selectedLocationId {
                    Text("\(itemsInLocation(locationId).count) items in this location")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("Select Location")
        }
    }
    
    private var highValueSection: some View {
        Section {
            HStack {
                Text("Minimum Value")
                Spacer()
                TextField("Amount", value: $highValueThreshold, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 120)
                    .keyboardType(.decimalPad)
            }
            
            Text("\(itemsAboveValue(highValueThreshold).count) items above this value")
                .font(.caption)
                .foregroundColor(.secondary)
        } header: {
            Text("Value Threshold")
        }
    }
    
    private var customSelectionSection: some View {
        Section {
            NavigationLink(destination: ItemSelectionView(items: items, selectedItems: $customSelectedItems)) {
                HStack {
                    Text("Select Items")
                    Spacer()
                    Text("\(customSelectedItems.count) selected")
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("Custom Selection")
        }
    }
    
    private var reportOptionsSection: some View {
        Section {
            Toggle("Include Photos", isOn: $reportOptions.includePhotos)
            Toggle("Include Receipts", isOn: $reportOptions.includeReceipts)
            Toggle("Include Warranty Info", isOn: $reportOptions.includeWarrantyInfo)
            Toggle("Include Purchase Info", isOn: $reportOptions.includePurchaseInfo)
            Toggle("Include Serial Numbers", isOn: $reportOptions.includeSerialNumbers)
            Toggle("Include Total Value", isOn: $reportOptions.includeTotalValue)
            Toggle("Group by Category", isOn: $reportOptions.groupByCategory)
            
            Picker("Sort By", selection: $reportOptions.sortBy) {
                Text("Name").tag(PDFReportService.ReportOptions.SortOption.name)
                Text("Value").tag(PDFReportService.ReportOptions.SortOption.value)
                Text("Purchase Date").tag(PDFReportService.ReportOptions.SortOption.purchaseDate)
                Text("Category").tag(PDFReportService.ReportOptions.SortOption.category)
            }
        } header: {
            Text("Report Options")
        }
    }
    
    // MARK: - Computed Properties
    
    private var itemsToInclude: [Item] {
        switch selectedReportType {
        case .fullInventory:
            return items
        case .category:
            return itemsInCategory(selectedCategory)
        case .location:
            return selectedLocationId.flatMap { itemsInLocation($0) } ?? []
        case .insurance:
            return items.filter { ($0.value ?? 0) > 0 }
        case .warranty:
            return items.filter { $0.warrantyId != nil }
        case .highValue:
            return itemsAboveValue(highValueThreshold)
        case .custom:
            return items.filter { customSelectedItems.contains($0.id) }
        }
    }
    
    private var estimatedPageCount: Int {
        let itemsPerPage = reportOptions.includePhotos ? 3 : 6
        let pageCount = (itemsToInclude.count + itemsPerPage - 1) / itemsPerPage
        return max(1, pageCount + 2) // Cover + content + appendix
    }
    
    // MARK: - Helper Methods
    
    private func itemsInCategory(_ category: ItemCategory) -> [Item] {
        items.filter { $0.category == category }
    }
    
    private func itemsInLocation(_ locationId: UUID) -> [Item] {
        items.filter { $0.locationId == locationId }
    }
    
    private func itemsAboveValue(_ value: Decimal) -> [Item] {
        items.filter { ($0.value ?? 0) >= value }
    }
    
    // MARK: - Actions
    
    private func generateReport() {
        Task {
            do {
                let reportType: PDFReportService.ReportType
                
                switch selectedReportType {
                case .fullInventory:
                    reportType = .fullInventory
                case .category:
                    reportType = .category(selectedCategory)
                case .location:
                    guard let locationId = selectedLocationId else { return }
                    reportType = .location(locationId)
                case .insurance:
                    reportType = .insurance
                case .warranty:
                    reportType = .warranty
                case .highValue:
                    reportType = .highValue(threshold: highValueThreshold)
                case .custom:
                    let selectedItems = items.filter { customSelectedItems.contains($0.id) }
                    reportType = .custom(items: selectedItems)
                }
                
                let url = try await reportService.generateReport(
                    type: reportType,
                    items: items,
                    options: reportOptions,
                    locations: locations,
                    warranties: warranties
                )
                
                generatedReportURL = url
                showingPreview = true
                
            } catch {
                reportService.error = error as? PDFReportError ?? .unknown(error.localizedDescription)
                showingError = true
            }
        }
    }
    
    private func shareReport(url: URL) {
        generatedReportURL = url
        showingShareSheet = true
    }
}

// MARK: - Item Selection View

struct ItemSelectionView: View {
    let items: [Item]
    @Binding var selectedItems: Set<UUID>
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    private var filteredItems: [Item] {
        if searchText.isEmpty {
            return items
        } else {
            return items.filter { item in
                item.name.localizedCaseInsensitiveContains(searchText) ||
                (item.brand?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        List {
            ForEach(filteredItems) { item in
                ItemSelectionRow(
                    item: item,
                    isSelected: selectedItems.contains(item.id)
                ) {
                    if selectedItems.contains(item.id) {
                        selectedItems.remove(item.id)
                    } else {
                        selectedItems.insert(item.id)
                    }
                }
            }
        }
        .searchable(text: $searchText)
        .navigationTitle("Select Items")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

struct ItemSelectionRow: View {
    let item: Item
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text(item.category.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let value = item.value {
                            Text("• \(value, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - PDF Preview View

struct PDFPreviewView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            PDFKitView(url: url)
                .navigationTitle("Report Preview")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingShareSheet = true }) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
                .sheet(isPresented: $showingShareSheet) {
                    ShareSheet(activityItems: [url])
                }
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        
        if let document = PDFDocument(url: url) {
            pdfView.document = document
        }
        
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        if let document = PDFDocument(url: url) {
            uiView.document = document
        }
    }
}

// ShareSheet is defined in BackupCodesView.swift