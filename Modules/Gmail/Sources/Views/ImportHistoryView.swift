//
//  ImportHistoryView.swift
//  Gmail Module
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
//  Module: Gmail
//  Dependencies: SwiftUI, Core
//  Testing: GmailTests/ImportHistoryViewTests.swift
//
//  Description: View for displaying Gmail import history
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core

/// View displaying Gmail import history
public struct ImportHistoryView: View {
    @StateObject private var historyService = ImportHistoryService()
    @State private var selectedSession: ImportSession?
    @State private var showingDeleteConfirmation = false
    @State private var sessionToDelete: ImportSession?
    @State private var selectedTimeRange: TimeRange = .allTime
    
    enum TimeRange: String, CaseIterable {
        case today = "Today"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case allTime = "All Time"
        
        var startDate: Date {
            let calendar = Calendar.current
            switch self {
            case .today:
                return calendar.startOfDay(for: Date())
            case .thisWeek:
                return calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
            case .thisMonth:
                return calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
            case .allTime:
                return Date.distantPast
            }
        }
    }
    
    var filteredSessions: [ImportSession] {
        historyService.sessions.filter { session in
            session.startDate >= selectedTimeRange.startDate
        }
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Statistics header
                if !historyService.sessions.isEmpty {
                    StatisticsHeader(
                        statistics: historyService.getStatistics(
                            from: selectedTimeRange.startDate,
                            to: Date()
                        )
                    )
                }
                
                // Time range picker
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Sessions list
                if filteredSessions.isEmpty {
                    ContentUnavailableView(
                        "No Import History",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Import history will appear here after you import receipts from Gmail")
                    )
                } else {
                    List {
                        ForEach(filteredSessions) { session in
                            SessionRow(session: session)
                                .onTapGesture {
                                    selectedSession = session
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        sessionToDelete = session
                                        showingDeleteConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Import History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !historyService.sessions.isEmpty {
                        Button("Clear All") {
                            showingDeleteConfirmation = true
                            sessionToDelete = nil
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .sheet(item: $selectedSession) { session in
                SessionDetailView(session: session)
            }
            .confirmationDialog(
                sessionToDelete != nil ? "Delete Session?" : "Clear All History?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let session = sessionToDelete {
                        historyService.deleteSession(session.id)
                    } else {
                        historyService.clearHistory()
                    }
                    sessionToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    sessionToDelete = nil
                }
            } message: {
                if sessionToDelete != nil {
                    Text("This will permanently delete this import session from your history.")
                } else {
                    Text("This will permanently delete all import history. This action cannot be undone.")
                }
            }
        }
    }
}

// MARK: - Statistics Header

struct StatisticsHeader: View {
    let statistics: ImportStatistics
    
    var body: some View {
        VStack(spacing: 16) {
            // Summary stats
            HStack(spacing: 20) {
                StatCard(
                    title: "Total Imports",
                    value: "\(statistics.totalReceiptsImported)",
                    icon: "doc.text.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Success Rate",
                    value: "\(Int(statistics.averageSuccessRate * 100))%",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                StatCard(
                    title: "Total Errors",
                    value: "\(statistics.totalErrors)",
                    icon: "exclamationmark.triangle.fill",
                    color: .red
                )
            }
            
            // Top retailers
            if !statistics.mostCommonRetailers.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Top Retailers")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 8) {
                        ForEach(statistics.mostCommonRetailers.prefix(3), id: \.retailer) { item in
                            RetailerBadge(name: item.retailer, count: item.count)
                        }
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Retailer Badge

struct RetailerBadge: View {
    let name: String
    let count: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Text(name)
                .font(.caption)
                .fontWeight(.medium)
            
            Text("(\(count))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray5))
        .clipShape(Capsule())
    }
}

// MARK: - Session Row

struct SessionRow: View {
    let session: ImportSession
    
    var statusColor: Color {
        switch session.status {
        case .completed:
            return .green
        case .inProgress:
            return .blue
        case .cancelled:
            return .orange
        case .failed:
            return .red
        }
    }
    
    var body: some View {
        HStack {
            // Status icon
            Image(systemName: session.status.iconName)
                .font(.title2)
                .foregroundColor(statusColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                // Date and status
                HStack {
                    Text(session.startDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(session.status.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(statusColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.2))
                        .clipShape(Capsule())
                }
                
                // Summary
                HStack {
                    Label("\(session.successfulImports) imported", systemImage: "checkmark.circle")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    if session.failedImports > 0 {
                        Label("\(session.failedImports) failed", systemImage: "xmark.circle")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    Spacer()
                    
                    if let duration = session.duration {
                        Text(formatDuration(duration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration < 60 {
            return "\(Int(duration))s"
        } else if duration < 3600 {
            return "\(Int(duration / 60))m"
        } else {
            return "\(Int(duration / 3600))h \(Int((duration.truncatingRemainder(dividingBy: 3600)) / 60))m"
        }
    }
}

// MARK: - Session Detail View

struct SessionDetailView: View {
    let session: ImportSession
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                // Overview tab
                SessionOverviewTab(session: session)
                    .tag(0)
                    .tabItem {
                        Label("Overview", systemImage: "chart.bar.fill")
                    }
                
                // Imported receipts tab
                ImportedReceiptsTab(receipts: session.importedReceipts)
                    .tag(1)
                    .tabItem {
                        Label("Receipts (\(session.importedReceipts.count))", systemImage: "doc.text.fill")
                    }
                
                // Errors tab
                if !session.errors.isEmpty {
                    ErrorsTab(errors: session.errors)
                        .tag(2)
                        .tabItem {
                            Label("Errors (\(session.errors.count))", systemImage: "exclamationmark.triangle.fill")
                        }
                }
            }
            .navigationTitle("Import Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Session Overview Tab

struct SessionOverviewTab: View {
    let session: ImportSession
    
    var body: some View {
        List {
            Section("Details") {
                DetailRow(label: "Start Time", value: session.startDate.formatted(date: .complete, time: .standard))
                
                if let endDate = session.endDate {
                    DetailRow(label: "End Time", value: endDate.formatted(date: .complete, time: .standard))
                }
                
                if let duration = session.duration {
                    DetailRow(label: "Duration", value: formatDuration(duration))
                }
                
                DetailRow(label: "Status", value: session.status.rawValue)
            }
            
            Section("Statistics") {
                DetailRow(label: "Total Emails", value: "\(session.totalEmails)")
                DetailRow(label: "Successful Imports", value: "\(session.successfulImports)")
                DetailRow(label: "Failed Imports", value: "\(session.failedImports)")
                DetailRow(label: "Success Rate", value: "\(Int(session.successRate * 100))%")
            }
            
            if !session.importedReceipts.isEmpty {
                Section("Top Retailers") {
                    let retailerCounts = Dictionary(grouping: session.importedReceipts, by: { $0.retailer })
                        .mapValues { $0.count }
                        .sorted { $0.value > $1.value }
                        .prefix(5)
                    
                    ForEach(retailerCounts, id: \.key) { retailer, count in
                        HStack {
                            Text(retailer)
                            Spacer()
                            Text("\(count) receipt\(count == 1 ? "" : "s")")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? ""
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Imported Receipts Tab

struct ImportedReceiptsTab: View {
    let receipts: [ImportedReceipt]
    
    var body: some View {
        List(receipts) { receipt in
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(receipt.retailer)
                        .font(.headline)
                    Spacer()
                    Text("$\(receipt.amount)")
                        .font(.headline)
                        .foregroundColor(.green)
                }
                
                Text(receipt.emailSubject)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack {
                    Text(receipt.emailDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.caption2)
                        Text("\(Int(receipt.confidence * 100))%")
                            .font(.caption2)
                    }
                    .foregroundColor(.green)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Errors Tab

struct ErrorsTab: View {
    let errors: [ImportErrorRecord]
    
    var body: some View {
        List(errors) { error in
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: error.errorType.iconName)
                        .foregroundColor(.red)
                    Text(error.errorType.rawValue)
                        .font(.headline)
                        .foregroundColor(.red)
                }
                
                Text(error.emailSubject)
                    .font(.subheadline)
                    .lineLimit(1)
                
                Text(error.errorMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(error.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
}