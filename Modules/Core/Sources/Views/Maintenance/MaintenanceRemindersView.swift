//
//  MaintenanceRemindersView.swift
//  Core
//
//  Main view for managing maintenance reminders
//

import SwiftUI

@available(iOS 15.0, *)
public struct MaintenanceRemindersView: View {
    @StateObject private var reminderService = MaintenanceReminderService.shared
    @State private var selectedTab = 0
    @State private var showingCreateReminder = false
    @State private var showingReminderDetail: MaintenanceReminderService.MaintenanceReminder?
    @State private var searchText = ""
    @State private var showingPermissionAlert = false
    
    private var filteredReminders: [MaintenanceReminderService.MaintenanceReminder] {
        let reminders: [MaintenanceReminderService.MaintenanceReminder]
        
        switch selectedTab {
        case 0: // Upcoming
            reminders = reminderService.upcomingReminders
        case 1: // Overdue
            reminders = reminderService.overdueReminders
        case 2: // All
            reminders = reminderService.reminders
        default:
            reminders = []
        }
        
        if searchText.isEmpty {
            return reminders
        } else {
            return reminders.filter { reminder in
                reminder.title.localizedCaseInsensitiveContains(searchText) ||
                reminder.itemName.localizedCaseInsensitiveContains(searchText) ||
                (reminder.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab selector
                Picker("View", selection: $selectedTab) {
                    Label("Upcoming", systemImage: "clock.fill")
                        .tag(0)
                    Label("Overdue", systemImage: "exclamationmark.triangle.fill")
                        .tag(1)
                    Label("All", systemImage: "list.bullet")
                        .tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content
                if filteredReminders.isEmpty {
                    emptyStateView
                } else {
                    remindersList
                }
            }
            .navigationTitle("Maintenance")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search reminders")
            .toolbar {
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
            .alert("Notification Permission Required", isPresented: $showingPermissionAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please enable notifications in Settings to receive maintenance reminders.")
            }
            .onAppear {
                checkNotificationPermissions()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: selectedTab == 1 ? "checkmark.circle.fill" : "wrench.and.screwdriver")
                .font(.system(size: 60))
                .foregroundColor(selectedTab == 1 ? .green : .secondary)
            
            VStack(spacing: 8) {
                Text(emptyStateTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(emptyStateMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if selectedTab != 1 {
                Button(action: { showingCreateReminder = true }) {
                    Label("Create Reminder", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
        }
        .padding(40)
    }
    
    private var emptyStateTitle: String {
        switch selectedTab {
        case 0: return "No Upcoming Maintenance"
        case 1: return "No Overdue Items"
        case 2: return "No Maintenance Reminders"
        default: return ""
        }
    }
    
    private var emptyStateMessage: String {
        switch selectedTab {
        case 0: return "Your items are all up to date"
        case 1: return "Great job keeping up with maintenance!"
        case 2: return "Create reminders to track maintenance for your items"
        default: return ""
        }
    }
    
    private var remindersList: some View {
        List {
            ForEach(filteredReminders) { reminder in
                MaintenanceReminderRow(
                    reminder: reminder,
                    onTap: {
                        showingReminderDetail = reminder
                    },
                    onToggle: {
                        Task {
                            try? await reminderService.toggleReminder(reminder.id)
                        }
                    },
                    onComplete: {
                        showingReminderDetail = reminder
                    }
                )
            }
            .onDelete { indexSet in
                deleteReminders(at: indexSet)
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    private func deleteReminders(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let reminder = filteredReminders[index]
                try? await reminderService.deleteReminder(reminder.id)
            }
        }
    }
    
    private func checkNotificationPermissions() {
        Task {
            do {
                _ = try await reminderService.requestNotificationPermission()
            } catch MaintenanceReminderService.MaintenanceError.notificationPermissionDenied {
                showingPermissionAlert = true
            } catch {
                // Handle other errors
            }
        }
    }
}

// MARK: - Reminder Row

struct MaintenanceReminderRow: View {
    let reminder: MaintenanceReminderService.MaintenanceReminder
    let onTap: () -> Void
    let onToggle: () -> Void
    let onComplete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Status indicator
                Image(systemName: reminder.status.icon)
                    .font(.title2)
                    .foregroundColor(reminder.status.color)
                    .frame(width: 36)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(reminder.itemName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        Label(reminder.type.rawValue, systemImage: reminder.type.icon)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if reminder.isOverdue {
                            Text("Overdue by \(abs(reminder.daysUntilDue)) days")
                                .font(.caption)
                                .foregroundColor(.red)
                        } else {
                            Text("Due in \(reminder.daysUntilDue) days")
                                .font(.caption)
                                .foregroundColor(reminder.daysUntilDue <= 7 ? .orange : .secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Actions
                VStack(spacing: 8) {
                    Toggle("", isOn: .constant(reminder.isEnabled))
                        .labelsHidden()
                        .scaleEffect(0.8)
                        .onTapGesture {
                            onToggle()
                        }
                    
                    if reminder.isEnabled && (reminder.isOverdue || reminder.daysUntilDue <= 7) {
                        Button(action: onComplete) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}