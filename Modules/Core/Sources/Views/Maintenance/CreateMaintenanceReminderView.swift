//
//  CreateMaintenanceReminderView.swift
//  Core
//
//  View for creating a new maintenance reminder
//

import SwiftUI

@available(iOS 15.0, *)
public struct CreateMaintenanceReminderView: View {
    @StateObject private var reminderService = MaintenanceReminderService.shared
    @Environment(\.dismiss) private var dismiss
    
    // Form state
    @State private var selectedItemId: UUID?
    @State private var selectedItemName = ""
    @State private var title = ""
    @State private var description = ""
    @State private var type: MaintenanceReminderService.MaintenanceType = .service
    @State private var frequency: MaintenanceReminderService.MaintenanceFrequency = .monthly
    @State private var customFrequencyDays = 30
    @State private var showCustomFrequency = false
    @State private var nextServiceDate = Date()
    @State private var estimatedCost: Decimal?
    @State private var provider = ""
    @State private var notes = ""
    @State private var notificationsEnabled = true
    @State private var notificationDaysBefore = [7, 1]
    @State private var notificationTime = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    
    // UI state
    @State private var showingItemPicker = false
    @State private var showingTemplatePicker = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // Mock items - in real app would come from item repository
    @State private var availableItems: [Item] = []
    
    private var isValid: Bool {
        selectedItemId != nil && !title.isEmpty
    }
    
    public var body: some View {
        NavigationView {
            Form {
                // Item selection
                Section {
                    Button(action: { showingItemPicker = true }) {
                        HStack {
                            Text("Select Item")
                            Spacer()
                            if selectedItemId != nil {
                                Text(selectedItemName)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Required")
                                    .foregroundColor(.red)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Item")
                } footer: {
                    if selectedItemId == nil {
                        Label("Please select an item to create a reminder for", systemImage: "info.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Reminder details
                Section {
                    TextField("Reminder Title", text: $title)
                    
                    TextField("Description (Optional)", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                    
                    Picker("Type", selection: $type) {
                        ForEach(MaintenanceReminderService.MaintenanceType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    
                    if type == .custom {
                        TextField("Custom Type", text: $title)
                    }
                } header: {
                    Text("Details")
                }
                
                // Schedule
                Section(header: Text("Schedule")) {
                    if showCustomFrequency {
                        HStack {
                            Text("Every")
                            TextField("Days", value: $customFrequencyDays, format: .number)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 80)
                            Text("days")
                            Spacer()
                            Button("Cancel") {
                                showCustomFrequency = false
                                frequency = .monthly
                            }
                            .font(.caption)
                        }
                    } else {
                        Picker("Frequency", selection: $frequency) {
                            ForEach(MaintenanceReminderService.MaintenanceFrequency.allCases, id: \.self) { freq in
                                Text(freq.displayName).tag(freq)
                            }
                            Text("Custom...").tag(MaintenanceReminderService.MaintenanceFrequency.custom(days: 30))
                        }
                        .onChange(of: frequency) { newValue in
                            if case .custom = newValue {
                                showCustomFrequency = true
                            }
                        }
                    }
                    
                    DatePicker("Next Service Date", selection: $nextServiceDate, displayedComponents: .date)
                }
                
                // Cost & Provider
                Section {
                    HStack {
                        Text("Estimated Cost")
                        Spacer()
                        TextField("Amount", value: $estimatedCost, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            .multilineTextAlignment(.trailing)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 120)
                            .keyboardType(.decimalPad)
                    }
                    
                    TextField("Service Provider (Optional)", text: $provider)
                } header: {
                    Text("Service Information")
                }
                
                // Notifications
                Section {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    
                    if notificationsEnabled {
                        HStack {
                            Text("Remind me")
                            Spacer()
                            ForEach([30, 14, 7, 3, 1], id: \.self) { days in
                                Toggle("\(days)d", isOn: Binding(
                                    get: { notificationDaysBefore.contains(days) },
                                    set: { enabled in
                                        if enabled {
                                            notificationDaysBefore.append(days)
                                        } else {
                                            notificationDaysBefore.removeAll { $0 == days }
                                        }
                                    }
                                ))
                                .toggleStyle(ChipToggleStyle())
                            }
                        }
                        
                        DatePicker("Notification Time", selection: $notificationTime, displayedComponents: .hourAndMinute)
                    }
                } header: {
                    Text("Notifications")
                }
                
                // Notes
                Section {
                    TextField("Additional Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Notes")
                }
                
                // Templates
                Section {
                    Button(action: { showingTemplatePicker = true }) {
                        Label("Use Template", systemImage: "doc.text")
                    }
                }
            }
            .navigationTitle("New Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createReminder()
                    }
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showingItemPicker) {
                ItemPickerView(
                    selectedItemId: $selectedItemId,
                    selectedItemName: $selectedItemName
                )
            }
            .sheet(isPresented: $showingTemplatePicker) {
                TemplatePickerView(
                    onSelect: applyTemplate
                )
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func createReminder() {
        guard let itemId = selectedItemId else { return }
        
        Task {
            do {
                let finalFrequency = showCustomFrequency 
                    ? MaintenanceReminderService.MaintenanceFrequency.custom(days: customFrequencyDays)
                    : frequency
                
                let notificationSettings = MaintenanceReminderService.NotificationSettings(
                    enabled: notificationsEnabled,
                    daysBeforeReminder: notificationDaysBefore.sorted(by: >),
                    timeOfDay: notificationTime
                )
                
                let reminder = MaintenanceReminderService.MaintenanceReminder(
                    itemId: itemId,
                    itemName: selectedItemName,
                    title: title,
                    description: description.isEmpty ? nil : description,
                    type: type,
                    frequency: finalFrequency,
                    nextServiceDate: nextServiceDate,
                    cost: estimatedCost,
                    provider: provider.isEmpty ? nil : provider,
                    notes: notes.isEmpty ? nil : notes,
                    notificationSettings: notificationSettings
                )
                
                try await reminderService.createReminder(reminder)
                dismiss()
                
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func applyTemplate(_ template: MaintenanceReminderService.MaintenanceTemplate) {
        title = template.title
        description = template.description
        type = template.type
        frequency = template.frequency
        
        if let cost = template.estimatedCost {
            estimatedCost = cost
        }
        
        if let provider = template.recommendedProvider {
            self.provider = provider
        }
        
        // Calculate next service date based on frequency
        nextServiceDate = Calendar.current.date(
            byAdding: .day,
            value: template.frequency.days,
            to: Date()
        ) ?? Date()
        
        showingTemplatePicker = false
    }
}

// MARK: - Supporting Views

struct ChipToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: { configuration.isOn.toggle() }) {
            configuration.label
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(configuration.isOn ? Color.blue : Color.secondary.opacity(0.2))
                .foregroundColor(configuration.isOn ? .white : .primary)
                .cornerRadius(15)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ItemPickerView: View {
    @Binding var selectedItemId: UUID?
    @Binding var selectedItemName: String
    @Environment(\.dismiss) private var dismiss
    
    // Mock items - would come from repository
    let items: [(id: UUID, name: String, category: String)] = [
        (UUID(), "MacBook Pro", "Electronics"),
        (UUID(), "Refrigerator", "Appliances"),
        (UUID(), "Car", "Vehicles"),
        (UUID(), "Washing Machine", "Appliances"),
        (UUID(), "HVAC System", "Appliances")
    ]
    
    var body: some View {
        NavigationView {
            List(items, id: \.id) { item in
                Button(action: {
                    selectedItemId = item.id
                    selectedItemName = item.name
                    dismiss()
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.name)
                                .font(.headline)
                            Text(item.category)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedItemId == item.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .foregroundColor(.primary)
            }
            .navigationTitle("Select Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TemplatePickerView: View {
    let onSelect: (MaintenanceReminderService.MaintenanceTemplate) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(MaintenanceReminderService.MaintenanceTemplate.commonTemplates, id: \.id) { template in
                Button(action: {
                    onSelect(template)
                    dismiss()
                }) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: template.type.icon)
                                .foregroundColor(.blue)
                            Text(template.title)
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        Text(template.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Label(template.frequency.displayName, systemImage: "clock")
                                .font(.caption)
                            
                            if let cost = template.estimatedCost {
                                Label(cost.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")), systemImage: "dollarsign.circle")
                                    .font(.caption)
                            }
                        }
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}