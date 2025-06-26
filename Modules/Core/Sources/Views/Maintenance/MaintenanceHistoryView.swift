//
//  MaintenanceHistoryView.swift
//  Core
//
//  View for displaying maintenance history
//

import SwiftUI

@available(iOS 15.0, *)
public struct MaintenanceHistoryView: View {
    let history: [MaintenanceReminderService.CompletionRecord]
    @Environment(\.dismiss) private var dismiss
    
    @State private var sortOrder: SortOrder = .dateDescending
    @State private var showingExport = false
    
    private enum SortOrder: String, CaseIterable {
        case dateDescending = "Newest First"
        case dateAscending = "Oldest First"
        case costHighest = "Highest Cost"
        case costLowest = "Lowest Cost"
        
        var icon: String {
            switch self {
            case .dateDescending: return "calendar"
            case .dateAscending: return "calendar"
            case .costHighest: return "dollarsign.circle"
            case .costLowest: return "dollarsign.circle"
            }
        }
    }
    
    private var sortedHistory: [MaintenanceReminderService.CompletionRecord] {
        switch sortOrder {
        case .dateDescending:
            return history.sorted { $0.completedDate > $1.completedDate }
        case .dateAscending:
            return history.sorted { $0.completedDate < $1.completedDate }
        case .costHighest:
            return history.sorted { ($0.cost ?? 0) > ($1.cost ?? 0) }
        case .costLowest:
            return history.sorted { ($0.cost ?? 0) < ($1.cost ?? 0) }
        }
    }
    
    private var totalCost: Decimal {
        history.reduce(0) { $0 + ($1.cost ?? 0) }
    }
    
    private var averageCost: Decimal {
        let recordsWithCost = history.filter { $0.cost != nil }
        guard !recordsWithCost.isEmpty else { return 0 }
        return totalCost / Decimal(recordsWithCost.count)
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Summary
                summarySection
                
                // Sort options
                Picker("Sort by", selection: $sortOrder) {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Label(order.rawValue, systemImage: order.icon)
                            .tag(order)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                
                // History list
                if sortedHistory.isEmpty {
                    emptyState
                } else {
                    historyList
                }
            }
            .navigationTitle("Maintenance History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: exportHistory) {
                            Label("Export as CSV", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(action: {}) {
                            Label("Print", systemImage: "printer")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
    
    private var summarySection: some View {
        HStack(spacing: 20) {
            VStack {
                Text("\(history.count)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Services")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .frame(height: 40)
            
            VStack {
                Text(totalCost, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Total Cost")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .frame(height: 40)
            
            VStack {
                Text(averageCost, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Average")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No History Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Completed maintenance will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var historyList: some View {
        List(sortedHistory) { record in
            HistoryRecordRow(record: record)
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    private func exportHistory() {
        // Export history as CSV
        var csv = "Date,Cost,Provider,Notes\n"
        
        for record in sortedHistory {
            let date = dateFormatter.string(from: record.completedDate)
            let cost = record.cost?.description ?? ""
            let provider = record.provider ?? ""
            let notes = record.notes?.replacingOccurrences(of: ",", with: ";") ?? ""
            
            csv += "\"\(date)\",\"\(cost)\",\"\(provider)\",\"\(notes)\"\n"
        }
        
        // Save to file and share
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("maintenance_history.csv")
        
        do {
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
            showingExport = true
        } catch {
            // Handle error
        }
    }
}

// MARK: - History Record Row

struct HistoryRecordRow: View {
    let record: MaintenanceReminderService.CompletionRecord
    @State private var isExpanded = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dateFormatter.string(from: record.completedDate))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if let provider = record.provider {
                        Text(provider)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if let cost = record.cost {
                    Text(cost, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if isExpanded {
                if let notes = record.notes {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                
                if !record.attachmentIds.isEmpty {
                    HStack {
                        Image(systemName: "paperclip")
                            .font(.caption)
                        Text("\(record.attachmentIds.count) attachment\(record.attachmentIds.count == 1 ? "" : "s")")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        }
    }
}