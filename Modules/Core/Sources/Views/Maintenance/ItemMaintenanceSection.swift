//
//  ItemMaintenanceSection.swift
//  Core
//
//  Maintenance section for item detail view
//

import SwiftUI

@available(iOS 15.0, *)
public struct ItemMaintenanceSection: View {
    let itemId: UUID
    let itemName: String
    
    @StateObject private var reminderService = MaintenanceReminderService.shared
    @State private var showingCreateReminder = false
    @State private var showingReminderDetail: MaintenanceReminderService.MaintenanceReminder?
    @State private var showingAllReminders = false
    
    private var itemReminders: [MaintenanceReminderService.MaintenanceReminder] {
        reminderService.reminders(for: itemId)
            .sorted { $0.nextServiceDate < $1.nextServiceDate }
    }
    
    private var upcomingReminders: [MaintenanceReminderService.MaintenanceReminder] {
        itemReminders.filter { $0.isEnabled && !$0.isOverdue }
    }
    
    private var overdueReminders: [MaintenanceReminderService.MaintenanceReminder] {
        itemReminders.filter { $0.isEnabled && $0.isOverdue }
    }
    
    public init(itemId: UUID, itemName: String) {
        self.itemId = itemId
        self.itemName = itemName
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Label("Maintenance", systemImage: "wrench.and.screwdriver")
                    .font(.headline)
                
                Spacer()
                
                if !itemReminders.isEmpty {
                    Button(action: { showingAllReminders = true }) {
                        Text("See All")
                            .font(.caption)
                    }
                }
                
                Button(action: { showingCreateReminder = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            
            if itemReminders.isEmpty {
                emptyState
            } else {
                remindersList
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .sheet(isPresented: $showingCreateReminder) {
            CreateMaintenanceReminderView()
                .onAppear {
                    // Pre-fill item selection
                    // This would need to be passed through the view
                }
        }
        .sheet(item: $showingReminderDetail) { reminder in
            MaintenanceReminderDetailView(reminder: reminder)
        }
        .sheet(isPresented: $showingAllReminders) {
            ItemMaintenanceListView(
                itemId: itemId,
                itemName: itemName,
                reminders: itemReminders
            )
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.badge.plus")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("No maintenance reminders")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: { showingCreateReminder = true }) {
                Text("Add Reminder")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical)
    }
    
    private var remindersList: some View {
        VStack(spacing: 12) {
            // Overdue reminders
            if !overdueReminders.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Overdue")
                        .font(.caption)
                        .foregroundColor(.red)
                        .textCase(.uppercase)
                    
                    ForEach(overdueReminders.prefix(2)) { reminder in
                        CompactReminderRow(
                            reminder: reminder,
                            onTap: { showingReminderDetail = reminder }
                        )
                    }
                }
            }
            
            // Upcoming reminders
            if !upcomingReminders.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    if !overdueReminders.isEmpty {
                        Divider()
                    }
                    
                    Text("Upcoming")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    ForEach(upcomingReminders.prefix(3)) { reminder in
                        CompactReminderRow(
                            reminder: reminder,
                            onTap: { showingReminderDetail = reminder }
                        )
                    }
                }
            }
            
            // Show more indicator
            let totalShown = min(2, overdueReminders.count) + min(3, upcomingReminders.count)
            if itemReminders.count > totalShown {
                Text("+ \(itemReminders.count - totalShown) more")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
    }
}

// MARK: - Compact Reminder Row

struct CompactReminderRow: View {
    let reminder: MaintenanceReminderService.MaintenanceReminder
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: reminder.type.icon)
                    .font(.subheadline)
                    .foregroundColor(reminder.status.color)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(reminder.title)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(dueText)
                        .font(.caption)
                        .foregroundColor(reminder.status.color)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var dueText: String {
        if reminder.isOverdue {
            return "Overdue by \(abs(reminder.daysUntilDue)) day\(abs(reminder.daysUntilDue) == 1 ? "" : "s")"
        } else if reminder.daysUntilDue == 0 {
            return "Due today"
        } else if reminder.daysUntilDue == 1 {
            return "Due tomorrow"
        } else {
            return "Due in \(reminder.daysUntilDue) days"
        }
    }
}

// MARK: - Item Maintenance List View

struct ItemMaintenanceListView: View {
    let itemId: UUID
    let itemName: String
    let reminders: [MaintenanceReminderService.MaintenanceReminder]
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingCreateReminder = false
    @State private var showingReminderDetail: MaintenanceReminderService.MaintenanceReminder?
    
    var body: some View {
        NavigationView {
            List(reminders) { reminder in
                MaintenanceReminderRow(
                    reminder: reminder,
                    onTap: { showingReminderDetail = reminder },
                    onToggle: {
                        Task {
                            try? await MaintenanceReminderService.shared.toggleReminder(reminder.id)
                        }
                    },
                    onComplete: { showingReminderDetail = reminder }
                )
            }
            .navigationTitle("\(itemName) Maintenance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateReminder = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingCreateReminder) {
                CreateMaintenanceReminderView()
            }
            .sheet(item: $showingReminderDetail) { reminder in
                MaintenanceReminderDetailView(reminder: reminder)
            }
        }
    }
}