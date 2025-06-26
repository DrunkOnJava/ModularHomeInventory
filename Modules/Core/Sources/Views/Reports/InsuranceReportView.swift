//
//  InsuranceReportView.swift
//  Core
//
//  Specialized view for insurance documentation reports
//

import SwiftUI

@available(iOS 15.0, *)
public struct InsuranceReportView: View {
    @StateObject private var reportService = PDFReportService()
    @Environment(\.dismiss) private var dismiss
    
    let items: [Item]
    let locations: [UUID: Core.Location]
    let warranties: [UUID: Core.Warranty]
    
    @State private var includePhotos = true
    @State private var includeReceipts = true
    @State private var includeAppraisals = false
    @State private var groupByLocation = true
    @State private var minimumValue: Decimal = 0
    @State private var policyNumber = ""
    @State private var policyHolder = ""
    @State private var generatedReportURL: URL?
    @State private var showingPreview = false
    @State private var showingShareSheet = false
    
    private var totalValue: Decimal {
        items.reduce(0) { $0 + ($1.value ?? 0) }
    }
    
    private var itemsByCategory: [(ItemCategory, [Item])] {
        let grouped = Dictionary(grouping: items) { $0.category }
        return grouped.sorted { $0.key.rawValue < $1.key.rawValue }
    }
    
    private var highValueItems: [Item] {
        items.filter { ($0.value ?? 0) >= 1000 }.sorted { ($0.value ?? 0) > ($1.value ?? 0) }
    }
    
    public init(items: [Item], locations: [UUID: Core.Location] = [:], warranties: [UUID: Core.Warranty] = [:]) {
        self.items = items
        self.locations = locations
        self.warranties = warranties
    }
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary Card
                    summaryCard
                    
                    // Policy Information
                    policyInfoSection
                    
                    // Categories Breakdown
                    categoriesBreakdown
                    
                    // High Value Items
                    if !highValueItems.isEmpty {
                        highValueItemsSection
                    }
                    
                    // Report Options
                    reportOptionsSection
                    
                    // Generate Button
                    generateButton
                }
                .padding()
            }
            .navigationTitle("Insurance Report")
            .navigationBarTitleDisplayMode(.large)
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
        }
    }
    
    // MARK: - Sections
    
    private var summaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Inventory Value")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(totalValue, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                Image(systemName: "shield.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
            }
            
            HStack(spacing: 40) {
                VStack {
                    Text("\(items.count)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Total Items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(itemsByCategory.count)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Categories")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(highValueItems.count)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("High Value")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var policyInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Policy Information")
                .font(.headline)
            
            VStack(spacing: 12) {
                TextField("Policy Number (Optional)", text: $policyNumber)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Policy Holder Name (Optional)", text: $policyHolder)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            Text("This information will be included in the report header")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
    
    private var categoriesBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories Breakdown")
                .font(.headline)
            
            ForEach(itemsByCategory, id: \.0) { category, categoryItems in
                let categoryValue = categoryItems.reduce(0) { $0 + ($1.value ?? 0) }
                
                HStack {
                    Label(category.rawValue, systemImage: category.icon)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text(categoryValue, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("\(categoryItems.count) items")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
                
                if category != itemsByCategory.last?.0 {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
    
    private var highValueItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("High Value Items")
                    .font(.headline)
                
                Spacer()
                
                Text("≥ $1,000")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ForEach(highValueItems.prefix(5)) { item in
                HStack {
                    VStack(alignment: .leading) {
                        Text(item.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if let brand = item.brand {
                            Text(brand)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Text(item.value ?? 0, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                .padding(.vertical, 4)
            }
            
            if highValueItems.count > 5 {
                Text("+ \(highValueItems.count - 5) more items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
    
    private var reportOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Report Options")
                .font(.headline)
            
            Toggle("Include Item Photos", isOn: $includePhotos)
            Toggle("Include Purchase Receipts", isOn: $includeReceipts)
            Toggle("Include Appraisals (if available)", isOn: $includeAppraisals)
            Toggle("Group by Location", isOn: $groupByLocation)
            
            HStack {
                Text("Minimum Value to Include")
                Spacer()
                TextField("0", value: $minimumValue, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 120)
                    .keyboardType(.decimalPad)
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
    
    private var generateButton: some View {
        Button(action: generateReport) {
            if reportService.isGenerating {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Generating... \(Int(reportService.progress * 100))%")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.5))
                .foregroundColor(.white)
                .cornerRadius(12)
            } else {
                Label("Generate Insurance Report", systemImage: "doc.fill.badge.plus")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .disabled(reportService.isGenerating)
    }
    
    // MARK: - Actions
    
    private func generateReport() {
        Task {
            do {
                var options = PDFReportService.ReportOptions()
                options.includePhotos = includePhotos
                options.includeReceipts = includeReceipts
                options.includeWarrantyInfo = true
                options.includePurchaseInfo = true
                options.includeSerialNumbers = true
                options.includeTotalValue = true
                options.groupByCategory = !groupByLocation
                options.sortBy = .value
                
                // Filter items by minimum value
                let filteredItems = items.filter { ($0.value ?? 0) >= minimumValue }
                
                let url = try await reportService.generateReport(
                    type: .insurance,
                    items: filteredItems,
                    options: options,
                    locations: locations,
                    warranties: warranties
                )
                
                generatedReportURL = url
                showingPreview = true
                
            } catch {
                // Handle error
                print("Failed to generate report: \(error)")
            }
        }
    }
    
    private func shareReport(url: URL) {
        generatedReportURL = url
        showingShareSheet = true
    }
}