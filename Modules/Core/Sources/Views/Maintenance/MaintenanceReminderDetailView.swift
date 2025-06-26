//
//  MaintenanceReminderDetailView.swift
//  Core
//
//  Detailed view for a maintenance reminder
//

import SwiftUI

@available(iOS 15.0, *)
public struct MaintenanceReminderDetailView: View {
    @StateObject private var reminderService = MaintenanceReminderService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State var reminder: MaintenanceReminderService.MaintenanceReminder
    @State private var isEditing = false
    @State private var showingCompleteSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var showingHistory = false
    
    // Completion form
    @State private var completionCost: Decimal?
    @State private var completionProvider = ""
    @State private var completionNotes = ""
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // Status
                    statusSection
                    
                    // Details
                    detailsSection
                    
                    // Schedule
                    scheduleSection
                    
                    // Service Information
                    if reminder.cost != nil || reminder.provider != nil {
                        serviceInfoSection
                    }
                    
                    // Notification Settings
                    notificationSection
                    
                    // History
                    if !reminder.completionHistory.isEmpty {
                        historySection
                    }
                    
                    // Actions
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("Maintenance Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { isEditing = true }) {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(action: {}) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $isEditing) {
                EditMaintenanceReminderView(reminder: $reminder)
            }
            .sheet(isPresented: $showingCompleteSheet) {
                completeReminderSheet
            }
            .sheet(isPresented: $showingHistory) {
                MaintenanceHistoryView(history: reminder.completionHistory)
            }
            .alert("Delete Reminder", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    deleteReminder()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this maintenance reminder? This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: reminder.type.icon)
                .font(.system(size: 50))
                .foregroundColor(reminder.status.color)
            
            Text(reminder.title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text(reminder.itemName)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical)
    }
    
    private var statusSection: some View {
        HStack(spacing: 20) {
            StatusCard(
                title: "Status",
                value: reminder.status == .overdue ? "Overdue" :
                       reminder.status == .upcoming ? "Due Soon" :
                       reminder.status == .scheduled ? "Scheduled" : "Disabled",
                color: reminder.status.color,
                icon: reminder.status.icon
            )
            
            StatusCard(
                title: "Days Until Due",
                value: reminder.isOverdue ? "-\(abs(reminder.daysUntilDue))" : "\(reminder.daysUntilDue)",
                color: reminder.status.color,
                icon: "calendar"
            )
        }
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            MaintenanceSectionHeader(title: "Details")
            
            MaintenanceDetailRow(label: "Type", value: reminder.type.rawValue, icon: reminder.type.icon)
            
            if let description = reminder.description {
                MaintenanceDetailRow(label: "Description", value: description, icon: "text.alignleft")
            }
            
            if let notes = reminder.notes {
                MaintenanceDetailRow(label: "Notes", value: notes, icon: "note.text")
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            MaintenanceSectionHeader(title: "Schedule")
            
            MaintenanceDetailRow(
                label: "Frequency",
                value: reminder.frequency.displayName,
                icon: "arrow.clockwise"
            )
            
            MaintenanceDetailRow(
                label: "Next Service",
                value: dateFormatter.string(from: reminder.nextServiceDate),
                icon: "calendar.circle"
            )
            
            if let lastService = reminder.lastServiceDate {
                MaintenanceDetailRow(
                    label: "Last Service",
                    value: dateFormatter.string(from: lastService),
                    icon: "clock.arrow.circlepath"
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var serviceInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            MaintenanceSectionHeader(title: "Service Information")
            
            if let cost = reminder.cost {
                MaintenanceDetailRow(
                    label: "Estimated Cost",
                    value: cost.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")),
                    icon: "dollarsign.circle"
                )
            }
            
            if let provider = reminder.provider {
                MaintenanceDetailRow(
                    label: "Service Provider",
                    value: provider,
                    icon: "person.crop.circle"
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            MaintenanceSectionHeader(title: "Notifications")
            
            HStack {
                Image(systemName: reminder.notificationSettings.enabled ? "bell.fill" : "bell.slash.fill")
                    .foregroundColor(reminder.notificationSettings.enabled ? .green : .gray)
                
                Text(reminder.notificationSettings.enabled ? "Enabled" : "Disabled")
                
                Spacer()
                
                Toggle("", isOn: .constant(reminder.notificationSettings.enabled))
                    .labelsHidden()
                    .onTapGesture {
                        toggleNotifications()
                    }
            }
            
            if reminder.notificationSettings.enabled {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Remind me:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        ForEach(reminder.notificationSettings.daysBeforeReminder.sorted(by: >), id: \.self) { days in
                            Text("\(days) day\(days == 1 ? "" : "s") before")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(15)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("at \(reminder.notificationSettings.timeOfDay.formatted(date: .omitted, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                MaintenanceSectionHeader(title: "History")
                Spacer()
                Button("View All") {
                    showingHistory = true
                }
                .font(.caption)
            }
            
            // Show last 3 completions
            ForEach(reminder.completionHistory.prefix(3)) { record in
                CompletionRecordRow(record: record)
            }
            
            if reminder.completionHistory.count > 3 {
                Text("+ \(reminder.completionHistory.count - 3) more")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if reminder.isEnabled {
                Button(action: { showingCompleteSheet = true }) {
                    Label("Mark as Completed", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }
                
                Button(action: snoozeReminder) {
                    Label("Snooze (7 days)", systemImage: "clock.arrow.circlepath")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                }
            } else {
                Button(action: enableReminder) {
                    Label("Enable Reminder", systemImage: "bell.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Complete Sheet
    
    private var completeReminderSheet: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Text("Service Cost")
                        Spacer()
                        TextField("Amount", value: $completionCost, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            .multilineTextAlignment(.trailing)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 120)
                            .keyboardType(.decimalPad)
                    }
                    
                    TextField("Service Provider", text: $completionProvider)
                } header: {
                    Text("Service Details")
                }
                
                Section {
                    TextField("Notes", text: $completionNotes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Notes")
                }
            }
            .navigationTitle("Complete Maintenance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingCompleteSheet = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Complete") {
                        completeReminder()
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func toggleNotifications() {
        reminder.notificationSettings.enabled.toggle()
        Task {
            try? await reminderService.updateReminder(reminder)
        }
    }
    
    private func completeReminder() {
        Task {
            try? await reminderService.completeReminder(
                reminder.id,
                cost: completionCost,
                provider: completionProvider.isEmpty ? nil : completionProvider,
                notes: completionNotes.isEmpty ? nil : completionNotes
            )
            
            // Refresh reminder
            if let updated = reminderService.reminders.first(where: { $0.id == reminder.id }) {
                reminder = updated
            }
            
            showingCompleteSheet = false
            
            // Clear form
            completionCost = nil
            completionProvider = ""
            completionNotes = ""
        }
    }
    
    private func snoozeReminder() {
        reminder.nextServiceDate = Calendar.current.date(
            byAdding: .day,
            value: 7,
            to: reminder.nextServiceDate
        ) ?? reminder.nextServiceDate
        
        Task {
            try? await reminderService.updateReminder(reminder)
        }
    }
    
    private func enableReminder() {
        reminder.isEnabled = true
        Task {
            try? await reminderService.updateReminder(reminder)
        }
    }
    
    private func deleteReminder() {
        Task {
            try? await reminderService.deleteReminder(reminder.id)
            dismiss()
        }
    }
}

// MARK: - Supporting Views

struct StatusCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct MaintenanceSectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.primary)
    }
}

struct MaintenanceDetailRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct CompletionRecordRow: View {
    let record: MaintenanceReminderService.CompletionRecord
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            
            VStack(alignment: .leading) {
                Text(dateFormatter.string(from: record.completedDate))
                    .font(.subheadline)
                
                if let cost = record.cost {
                    Text(cost.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let provider = record.provider {
                Text(provider)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}