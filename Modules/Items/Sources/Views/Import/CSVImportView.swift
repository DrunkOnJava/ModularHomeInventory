//
//  CSVImportView.swift
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
//  Dependencies: SwiftUI, Core, SharedUI, UniformTypeIdentifiers
//  Testing: ItemsTests/CSVImportViewTests.swift
//
//  Description: View for importing inventory data from CSV files
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core
import SharedUI
import UniformTypeIdentifiers

/// CSV import view for bulk importing items
/// Swift 5.9 - No Swift 6 features
struct CSVImportView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CSVImportViewModel
    @State private var showingFilePicker = false
    @State private var selectedTemplate: Core.CSVImportTemplate?
    @State private var showingMappingView = false
    
    init(
        itemRepository: any ItemRepository,
        locationRepository: any LocationRepository,
        onImportComplete: @escaping (Core.CSVImportResult) -> Void
    ) {
        self._viewModel = StateObject(wrappedValue: CSVImportViewModel(
            importService: Core.CSVImportService(
                itemRepository: itemRepository,
                locationRepository: locationRepository
            ),
            onImportComplete: onImportComplete
        ))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if viewModel.csvData == nil {
                    // File selection view
                    fileSelectionView
                } else if !showingMappingView {
                    // Preview view
                    previewView
                } else {
                    // Column mapping view
                    ColumnMappingView(
                        preview: viewModel.previewData!,
                        configuration: $viewModel.configuration,
                        onComplete: {
                            showingMappingView = false
                        }
                    )
                }
            }
            .navigationTitle("Import from CSV")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if viewModel.csvData != nil && !showingMappingView {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Import") {
                            Task {
                                await viewModel.importCSV()
                            }
                        }
                        .disabled(viewModel.isImporting)
                    }
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.commaSeparatedText],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
            .sheet(item: $selectedTemplate) { template in
                TemplateDetailView(template: template)
            }
            .alert("Import Complete", isPresented: $viewModel.showingResult) {
                Button("OK") {
                    if viewModel.importResult?.failedImports == 0 {
                        dismiss()
                    }
                }
            } message: {
                if let result = viewModel.importResult {
                    Text("""
                    Successfully imported: \(result.successfulImports) items
                    Failed: \(result.failedImports) items
                    Duration: \(String(format: "%.1f", result.duration))s
                    """)
                }
            }
        }
    }
    
    // MARK: - File Selection View
    
    private var fileSelectionView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Upload section
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(AppColors.primary)
                    
                    Text("Select CSV File")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Import your inventory from a CSV file")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button(action: { showingFilePicker = true }) {
                        Label("Choose File", systemImage: "folder")
                            .font(.system(size: 16, weight: .medium))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(AppColors.primary)
                            .foregroundStyle(.white)
                            .cornerRadius(25)
                    }
                }
                .padding(.vertical, 40)
                
                Divider()
                
                // Templates section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Download Templates")
                        .font(.headline)
                    
                    Text("Use these templates to format your data correctly")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    VStack(spacing: 12) {
                        ForEach(Core.CSVImportTemplate.allTemplates) { template in
                            TemplateCard(
                                template: template,
                                onTap: { selectedTemplate = template },
                                onDownload: { viewModel.downloadTemplate(template) }
                            )
                        }
                    }
                }
                
                // Instructions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Import Instructions")
                        .font(.headline)
                    
                    InstructionRow(
                        number: "1",
                        text: "Download a template or prepare your CSV file"
                    )
                    
                    InstructionRow(
                        number: "2",
                        text: "Ensure your file has the correct column headers"
                    )
                    
                    InstructionRow(
                        number: "3",
                        text: "Select your file and map the columns"
                    )
                    
                    InstructionRow(
                        number: "4",
                        text: "Review the preview and import"
                    )
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
        }
    }
    
    // MARK: - Preview View
    
    private var previewView: some View {
        VStack(spacing: 0) {
            // Configuration bar
            VStack(spacing: 12) {
                HStack {
                    Text("File: \(viewModel.fileName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Button("Change File") {
                        viewModel.clearFile()
                    }
                    .font(.subheadline)
                }
                
                HStack(spacing: 16) {
                    Toggle("Has Headers", isOn: Binding(
                        get: { viewModel.configuration.hasHeaders },
                        set: { newValue in
                            viewModel.configuration = Core.CSVImportConfiguration(
                                delimiter: viewModel.configuration.delimiter,
                                hasHeaders: newValue,
                                encoding: viewModel.configuration.encoding,
                                dateFormat: viewModel.configuration.dateFormat,
                                currencySymbol: viewModel.configuration.currencySymbol,
                                columnMapping: viewModel.configuration.columnMapping
                            )
                            Task {
                                await viewModel.loadPreview()
                            }
                        }
                    ))
                        .toggleStyle(SwitchToggleStyle(tint: AppColors.primary))
                    
                    Spacer()
                    
                    Button("Map Columns") {
                        showingMappingView = true
                    }
                    .font(.subheadline)
                    .foregroundStyle(AppColors.primary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            
            if viewModel.isLoadingPreview {
                ProgressView("Loading preview...")
                    .padding(50)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let preview = viewModel.previewData {
                // Preview table
                ScrollView([.horizontal, .vertical]) {
                    VStack(spacing: 0) {
                        // Headers
                        if viewModel.configuration.hasHeaders {
                            HStack(spacing: 0) {
                                ForEach(Array(preview.headers.enumerated()), id: \.offset) { index, header in
                                    Text(header)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .frame(minWidth: 100)
                                        .background(Color(.systemGray5))
                                        .border(Color(.systemGray4), width: 0.5)
                                }
                            }
                        }
                        
                        // Data rows
                        ForEach(Array(preview.rows.enumerated()), id: \.offset) { rowIndex, row in
                            HStack(spacing: 0) {
                                ForEach(Array(row.enumerated()), id: \.offset) { colIndex, value in
                                    Text(value)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .frame(minWidth: 100)
                                        .background(rowIndex % 2 == 0 ? Color.clear : Color(.systemGray6))
                                        .border(Color(.systemGray4), width: 0.5)
                                }
                            }
                        }
                    }
                }
                
                // Summary
                HStack {
                    Label("\(preview.totalRows) rows", systemImage: "tablecells")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if preview.rows.count < preview.totalRows {
                        Text("Showing first \(preview.rows.count) rows")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
            }
            
            // Import progress
            if viewModel.isImporting {
                VStack(spacing: 16) {
                    ProgressView(value: viewModel.importProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: AppColors.primary))
                    
                    Text("Importing... \(Int(viewModel.importProgress * 100))%")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                viewModel.loadCSVFile(from: url)
            }
        case .failure(let error):
            viewModel.errorMessage = error.localizedDescription
            viewModel.showingError = true
        }
    }
}

// MARK: - Supporting Views

struct TemplateCard: View {
    let template: Core.CSVImportTemplate
    let onTap: () -> Void
    let onDownload: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.system(size: 15, weight: .medium))
                
                Text(template.description)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button(action: onDownload) {
                Image(systemName: "arrow.down.circle")
                    .font(.title2)
                    .foregroundStyle(AppColors.primary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onTapGesture(perform: onTap)
    }
}

struct InstructionRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(AppColors.primary)
                .clipShape(Circle())
            
            Text(text)
                .font(.system(size: 14))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct TemplateDetailView: View {
    let template: Core.CSVImportTemplate
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(template.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("Sample Data:")
                        .font(.headline)
                    
                    Text(template.sampleData)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    Text("Configuration:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ConfigRow(label: "Delimiter", value: template.configuration.delimiter)
                        ConfigRow(label: "Has Headers", value: template.configuration.hasHeaders ? "Yes" : "No")
                        ConfigRow(label: "Date Format", value: template.configuration.dateFormat)
                        ConfigRow(label: "Currency Symbol", value: template.configuration.currencySymbol)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .padding()
            }
            .navigationTitle(template.name)
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
}

struct ConfigRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.system(size: 14))
    }
}

// MARK: - View Model

@MainActor
final class CSVImportViewModel: ObservableObject {
    @Published var csvData: Data?
    @Published var fileName = ""
    @Published var configuration = Core.CSVImportConfiguration()
    @Published var previewData: Core.CSVPreviewData?
    @Published var isLoadingPreview = false
    @Published var isImporting = false
    @Published var importProgress: Double = 0
    @Published var importResult: Core.CSVImportResult?
    @Published var showingResult = false
    @Published var showingError = false
    @Published var errorMessage = ""
    
    private let importService: Core.CSVImportService
    private let onImportComplete: (Core.CSVImportResult) -> Void
    
    init(
        importService: Core.CSVImportService,
        onImportComplete: @escaping (Core.CSVImportResult) -> Void
    ) {
        self.importService = importService
        self.onImportComplete = onImportComplete
    }
    
    func loadCSVFile(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            self.csvData = data
            self.fileName = url.lastPathComponent
            
            Task {
                await loadPreview()
            }
        } catch {
            errorMessage = "Failed to load file: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    func clearFile() {
        csvData = nil
        fileName = ""
        previewData = nil
        configuration = Core.CSVImportConfiguration()
    }
    
    func loadPreview() async {
        guard let data = csvData else { return }
        
        isLoadingPreview = true
        defer { isLoadingPreview = false }
        
        do {
            previewData = try importService.previewCSV(
                data: data,
                configuration: configuration
            )
        } catch {
            errorMessage = "Failed to preview CSV: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    func importCSV() async {
        guard let data = csvData else { return }
        
        isImporting = true
        defer { isImporting = false }
        
        do {
            let result = try await importService.importCSV(
                data: data,
                configuration: configuration,
                progressHandler: { progress in
                    Task { @MainActor in
                        self.importProgress = progress
                    }
                }
            )
            
            importResult = result
            showingResult = true
            onImportComplete(result)
            
        } catch {
            errorMessage = "Import failed: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    func downloadTemplate(_ template: Core.CSVImportTemplate) {
        guard importService.exportTemplate(template) != nil else { return }
        
        // In a real app, this would save to Files app or share
        // For now, just show a message
        errorMessage = "Template downloaded: \(template.name).csv"
        showingError = true
    }
}