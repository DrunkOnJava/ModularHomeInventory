//
//  QuickReportMenu.swift
//  Core
//
//  Quick access menu for generating common reports
//

import SwiftUI

@available(iOS 15.0, *)
public struct QuickReportMenu: View {
    @StateObject private var reportService = PDFReportService()
    
    let items: [Item]
    let locations: [UUID: Core.Location]
    let warranties: [UUID: Core.Warranty]
    
    @State private var showingFullGenerator = false
    @State private var showingShareSheet = false
    @State private var generatedReportURL: URL?
    @State private var isGenerating = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    public init(items: [Item], locations: [UUID: Core.Location] = [:], warranties: [UUID: Core.Warranty] = [:]) {
        self.items = items
        self.locations = locations
        self.warranties = warranties
    }
    
    public var body: some View {
        Menu {
            // Quick Reports
            Section {
                Button(action: generateInsuranceReport) {
                    Label("Insurance Report", systemImage: "shield.fill")
                }
                
                Button(action: generateWarrantyReport) {
                    Label("Warranty Report", systemImage: "clock.badge.checkmark.fill")
                }
                
                Button(action: generateHighValueReport) {
                    Label("High Value Items", systemImage: "dollarsign.circle.fill")
                }
                
                Button(action: generateQuickSummary) {
                    Label("Quick Summary", systemImage: "doc.text")
                }
            }
            
            Divider()
            
            // Custom Report
            Button(action: { showingFullGenerator = true }) {
                Label("Custom Report...", systemImage: "doc.badge.gearshape")
            }
            
            // Recent Reports
            if let lastReport = reportService.lastGeneratedReport {
                Divider()
                
                Button(action: { shareReport(url: lastReport) }) {
                    Label("Share Last Report", systemImage: "square.and.arrow.up")
                }
            }
        } label: {
            if isGenerating {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Label("Reports", systemImage: "doc.fill.badge.plus")
            }
        }
        .disabled(isGenerating || items.isEmpty)
        .sheet(isPresented: $showingFullGenerator) {
            PDFReportGeneratorView(
                items: items,
                locations: locations,
                warranties: warranties
            )
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = generatedReportURL {
                ShareSheet(activityItems: [url])
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
        .overlay {
            if reportService.isGenerating {
                ProgressOverlay(progress: reportService.progress)
            }
        }
    }
    
    // MARK: - Quick Report Actions
    
    private func generateInsuranceReport() {
        generateReport(type: .insurance)
    }
    
    private func generateWarrantyReport() {
        generateReport(type: .warranty)
    }
    
    private func generateHighValueReport() {
        generateReport(type: .highValue(threshold: 500))
    }
    
    private func generateQuickSummary() {
        isGenerating = true
        
        Task {
            do {
                let url = try await reportService.generateQuickSummary(items: items)
                await MainActor.run {
                    generatedReportURL = url
                    showingShareSheet = true
                    isGenerating = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isGenerating = false
                }
            }
        }
    }
    
    private func generateReport(type: PDFReportService.ReportType) {
        isGenerating = true
        
        Task {
            do {
                let options = PDFReportService.ReportOptions()
                let url = try await reportService.generateReport(
                    type: type,
                    items: items,
                    options: options,
                    locations: locations,
                    warranties: warranties
                )
                
                await MainActor.run {
                    generatedReportURL = url
                    showingShareSheet = true
                    isGenerating = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isGenerating = false
                }
            }
        }
    }
    
    private func shareReport(url: URL) {
        generatedReportURL = url
        showingShareSheet = true
    }
}

// MARK: - Progress Overlay

struct ProgressOverlay: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Generating Report")
                    .font(.headline)
                    .foregroundColor(.white)
                
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .white))
                    .frame(width: 200)
                
                Text("\(Int(progress * 100))%")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(24)
            .background(Color.black.opacity(0.8))
            .cornerRadius(16)
        }
    }
}

// MARK: - Report Summary Card

@available(iOS 15.0, *)
public struct ReportSummaryCard: View {
    let reportType: String
    let itemCount: Int
    let lastGenerated: Date?
    let action: () -> Void
    
    public var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(reportType)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(itemCount) items")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let date = lastGenerated {
                        Text("Last: \(date.formatted(.relative(presentation: .named)))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "arrow.down.doc.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}