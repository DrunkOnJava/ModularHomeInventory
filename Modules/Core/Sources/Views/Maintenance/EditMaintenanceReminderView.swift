//
//  EditMaintenanceReminderView.swift
//  Core
//
//  View for editing a maintenance reminder
//

import SwiftUI

@available(iOS 15.0, *)
public struct EditMaintenanceReminderView: View {
    @Binding var reminder: MaintenanceReminderService.MaintenanceReminder
    @StateObject private var reminderService = MaintenanceReminderService.shared
    @Environment(\.dismiss) private var dismiss
    
    // Form state - initialized from reminder
    @State private var title: String
    @State private var description: String
    @State private var type: MaintenanceReminderService.MaintenanceType
    @State private var frequency: MaintenanceReminderService.MaintenanceFrequency
    @State private var nextServiceDate: Date
    @State private var cost: Decimal?
    @State private var provider: String
    @State private var notes: String
    @State private var isEnabled: Bool
    @State private var notificationSettings: MaintenanceReminderService.NotificationSettings
    
    @State private var showingError = false
    @State private var errorMessage = ""
    
    public init(reminder: Binding<MaintenanceReminderService.MaintenanceReminder>) {
        self._reminder = reminder
        let r = reminder.wrappedValue
        self._title = State(initialValue: r.title)
        self._description = State(initialValue: r.description ?? "")
        self._type = State(initialValue: r.type)
        self._frequency = State(initialValue: r.frequency)
        self._nextServiceDate = State(initialValue: r.nextServiceDate)
        self._cost = State(initialValue: r.cost)
        self._provider = State(initialValue: r.provider ?? "")
        self._notes = State(initialValue: r.notes ?? "")
        self._isEnabled = State(initialValue: r.isEnabled)
        self._notificationSettings = State(initialValue: r.notificationSettings)
    }
    
    public var body: some View {
        NavigationView {
            editForm
        }
    }
    
    private var editForm: some View {
        Form {
            // Basic info
            Section {
                TextField("Title", text: $title)
                
                TextField("Description", text: $description, axis: .vertical)
                    .lineLimit(2...4)
                
                Picker("Type", selection: $type) {
                    ForEach(MaintenanceReminderService.MaintenanceType.allCases, id: \.self) { type in
                        Label(type.rawValue, systemImage: type.icon)
                            .tag(type)
                    }
                }
            } header: {
                Text("Details")
            }
            
            // Schedule
            Section {
                Picker("Frequency", selection: $frequency) {
                    ForEach(MaintenanceReminderService.MaintenanceFrequency.allCases, id: \.self) { freq in
                        Text(freq.displayName).tag(freq)
                    }
                }
                
                DatePicker("Next Service Date", selection: $nextServiceDate, displayedComponents: .date)
            } header: {
                Text("Schedule")
            }
            
            // Service info
            Section {
                HStack {
                    Text("Estimated Cost")
                    Spacer()
                    TextField("Amount", value: $cost, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        .multilineTextAlignment(.trailing)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 120)
                        .keyboardType(.decimalPad)
                }
                
                TextField("Service Provider", text: $provider)
            } header: {
                Text("Service Information")
            }
            
            // Notifications
            Section {
                Toggle("Enable Notifications", isOn: $notificationSettings.enabled)
                
                if notificationSettings.enabled {
                    HStack {
                        Text("Remind me")
                        Spacer()
                        ForEach([30, 14, 7, 3, 1], id: \.self) { days in
                            Toggle("\(days)d", isOn: Binding(
                                get: { notificationSettings.daysBeforeReminder.contains(days) },
                                set: { enabled in
                                    if enabled {
                                        notificationSettings.daysBeforeReminder.append(days)
                                    } else {
                                        notificationSettings.daysBeforeReminder.removeAll { $0 == days }
                                    }
                                }
                            ))
                            .toggleStyle(ChipToggleStyle())
                        }
                    }
                }
            } header: {
                Text("Notifications")
            }
            
            // Status
            Section {
                Toggle("Reminder Enabled", isOn: $isEnabled)
            }
            
            // Notes
            Section {
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            } header: {
                Text("Notes")
            }
        }
        .navigationTitle("Edit Reminder")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveChanges()
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func saveChanges() {
        // Update reminder with new values
        reminder.title = title
        reminder.description = description.isEmpty ? nil : description
        reminder.type = type
        reminder.frequency = frequency
        reminder.nextServiceDate = nextServiceDate
        reminder.cost = cost
        reminder.provider = provider.isEmpty ? nil : provider
        reminder.notes = notes.isEmpty ? nil : notes
        reminder.isEnabled = isEnabled
        reminder.notificationSettings = notificationSettings
        
        Task {
            do {
                try await reminderService.updateReminder(reminder)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}