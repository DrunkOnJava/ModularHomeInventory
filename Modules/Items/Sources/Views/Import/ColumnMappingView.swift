//
//  ColumnMappingView.swift
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
//  Testing: ItemsTests/ColumnMappingViewTests.swift
//
//  Description: View for mapping CSV columns to item fields during import
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core
import SharedUI

/// View for mapping CSV columns to item fields
/// Swift 5.9 - No Swift 6 features
struct ColumnMappingView: View {
    let preview: Core.CSVPreviewData
    @Binding var configuration: Core.CSVImportConfiguration
    let onComplete: () -> Void
    
    @State private var selectedMappings: [Core.CSVExportField: Int] = [:]
    @Environment(\.dismiss) private var dismiss
    
    private let fields: [(Core.CSVExportField, Bool)] = [
        (.name, true),
        (.brand, false),
        (.model, false),
        (.serialNumber, false),
        (.barcode, false),
        (.category, false),
        (.location, false),
        (.storeName, false),
        (.purchaseDate, false),
        (.purchasePrice, false),
        (.quantity, false),
        (.condition, false),
        (.warrantyEndDate, false),
        (.tags, false),
        (.notes, false)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Instructions
            VStack(alignment: .leading, spacing: 8) {
                Text("Map Your Columns")
                    .font(.headline)
                
                Text("Match your CSV columns to inventory fields. Only 'Name' is required.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemGray6))
            
            // Mapping list
            List {
                ForEach(fields, id: \.0) { field, isRequired in
                    MappingRow(
                        field: field,
                        isRequired: isRequired,
                        columns: preview.headers,
                        selectedColumn: binding(for: field),
                        sampleData: sampleData(for: binding(for: field).wrappedValue)
                    )
                }
            }
            
            // Buttons
            HStack(spacing: 16) {
                Button("Auto-Detect") {
                    autoDetectMappings()
                }
                .foregroundStyle(AppColors.primary)
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .foregroundStyle(.secondary)
                
                Button("Done") {
                    applyMappings()
                    onComplete()
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.primary)
                .disabled(!isValid)
            }
            .padding()
            .background(Color(.systemGray6))
        }
        .navigationTitle("Column Mapping")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadCurrentMappings()
        }
    }
    
    // MARK: - Helper Methods
    
    private func binding(for field: Core.CSVExportField) -> Binding<Int?> {
        Binding(
            get: { selectedMappings[field] },
            set: { selectedMappings[field] = $0 }
        )
    }
    
    private func sampleData(for columnIndex: Int?) -> String? {
        guard let index = columnIndex,
              index < preview.headers.count,
              !preview.rows.isEmpty else { return nil }
        
        return preview.rows.first?[index]
    }
    
    private var isValid: Bool {
        // Must have at least name mapped
        return selectedMappings[.name] != nil
    }
    
    private func loadCurrentMappings() {
        let mapping = configuration.columnMapping
        
        if let index = mapping.name { selectedMappings[.name] = index }
        if let index = mapping.brand { selectedMappings[.brand] = index }
        if let index = mapping.model { selectedMappings[.model] = index }
        if let index = mapping.serialNumber { selectedMappings[.serialNumber] = index }
        if let index = mapping.barcode { selectedMappings[.barcode] = index }
        if let index = mapping.category { selectedMappings[.category] = index }
        if let index = mapping.location { selectedMappings[.location] = index }
        if let index = mapping.storeName { selectedMappings[.storeName] = index }
        if let index = mapping.purchaseDate { selectedMappings[.purchaseDate] = index }
        if let index = mapping.purchasePrice { selectedMappings[.purchasePrice] = index }
        if let index = mapping.quantity { selectedMappings[.quantity] = index }
        if let index = mapping.condition { selectedMappings[.condition] = index }
        if let index = mapping.warrantyEndDate { selectedMappings[.warrantyEndDate] = index }
        if let index = mapping.tags { selectedMappings[.tags] = index }
        if let index = mapping.notes { selectedMappings[.notes] = index }
    }
    
    private func applyMappings() {
        var mapping = Core.CSVColumnMapping()
        
        mapping.name = selectedMappings[.name]
        mapping.brand = selectedMappings[.brand]
        mapping.model = selectedMappings[.model]
        mapping.serialNumber = selectedMappings[.serialNumber]
        mapping.barcode = selectedMappings[.barcode]
        mapping.category = selectedMappings[.category]
        mapping.location = selectedMappings[.location]
        mapping.storeName = selectedMappings[.storeName]
        mapping.purchaseDate = selectedMappings[.purchaseDate]
        mapping.purchasePrice = selectedMappings[.purchasePrice]
        mapping.quantity = selectedMappings[.quantity]
        mapping.condition = selectedMappings[.condition]
        mapping.warrantyEndDate = selectedMappings[.warrantyEndDate]
        mapping.tags = selectedMappings[.tags]
        mapping.notes = selectedMappings[.notes]
        
        configuration = Core.CSVImportConfiguration(
            delimiter: configuration.delimiter,
            hasHeaders: configuration.hasHeaders,
            encoding: configuration.encoding,
            dateFormat: configuration.dateFormat,
            currencySymbol: configuration.currencySymbol,
            columnMapping: mapping
        )
    }
    
    private func autoDetectMappings() {
        selectedMappings.removeAll()
        
        for (index, header) in preview.headers.enumerated() {
            let normalized = header.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Try to match common variations
            switch normalized {
            case "name", "item name", "product name", "item", "product":
                selectedMappings[.name] = index
                
            case "brand", "manufacturer", "make":
                selectedMappings[.brand] = index
                
            case "model", "model number", "model no":
                selectedMappings[.model] = index
                
            case "serial", "serial number", "serial no", "sn":
                selectedMappings[.serialNumber] = index
                
            case "barcode", "upc", "ean", "bar code":
                selectedMappings[.barcode] = index
                
            case "category", "type", "item type", "product category":
                selectedMappings[.category] = index
                
            case "location", "room", "place", "stored at":
                selectedMappings[.location] = index
                
            case "store", "store name", "retailer", "vendor", "purchased from":
                selectedMappings[.storeName] = index
                
            case "purchase date", "bought date", "date purchased", "date":
                selectedMappings[.purchaseDate] = index
                
            case "price", "cost", "purchase price", "amount", "value":
                selectedMappings[.purchasePrice] = index
                
            case "quantity", "qty", "count", "amount":
                if selectedMappings[.purchasePrice] == nil || !normalized.contains("amount") {
                    selectedMappings[.quantity] = index
                }
                
            case "condition", "status", "state":
                selectedMappings[.condition] = index
                
            case "warranty", "warranty end", "warranty expiry", "warranty date":
                selectedMappings[.warrantyEndDate] = index
                
            case "tags", "labels", "keywords":
                selectedMappings[.tags] = index
                
            case "notes", "description", "comments", "remarks":
                selectedMappings[.notes] = index
                
            default:
                break
            }
        }
    }
}

// MARK: - Supporting Views

struct MappingRow: View {
    let field: Core.CSVExportField
    let isRequired: Bool
    let columns: [String]
    @Binding var selectedColumn: Int?
    let sampleData: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label {
                    Text(field.displayName)
                        .font(.system(size: 15, weight: .medium))
                    if isRequired {
                        Text("(Required)")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                } icon: {
                    Image(systemName: iconForField(field))
                        .foregroundStyle(AppColors.primary)
                }
                
                Spacer()
                
                Menu {
                    Button("None") {
                        selectedColumn = nil
                    }
                    
                    Divider()
                    
                    ForEach(Array(columns.enumerated()), id: \.offset) { index, column in
                        Button(column) {
                            selectedColumn = index
                        }
                    }
                } label: {
                    HStack {
                        if let index = selectedColumn {
                            Text(columns[index])
                                .font(.system(size: 14))
                        } else {
                            Text("Select column")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                        
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
                }
            }
            
            if let sample = sampleData {
                HStack {
                    Text("Sample:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(sample)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func iconForField(_ field: Core.CSVExportField) -> String {
        switch field {
        case .name: return "tag"
        case .brand: return "building.2"
        case .model: return "number"
        case .serialNumber: return "number.square"
        case .barcode: return "barcode"
        case .category: return "folder"
        case .location: return "location"
        case .storeName: return "storefront"
        case .purchaseDate: return "calendar"
        case .purchasePrice: return "dollarsign.circle"
        case .quantity: return "number.circle"
        case .condition: return "star"
        case .warrantyEndDate: return "shield"
        case .tags: return "tag.circle"
        case .notes: return "note.text"
        case .createdAt: return "clock"
        case .updatedAt: return "clock.arrow.circlepath"
        }
    }
}