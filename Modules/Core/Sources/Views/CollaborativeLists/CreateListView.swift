//
//  CreateListView.swift
//  Core
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
//  Module: Core
//  Dependencies: SwiftUI
//  Testing: CoreTests/CreateListViewTests.swift
//
//  Description: View for creating a new collaborative list with templates, collaborator invitations, and settings
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI

@available(iOS 15.0, *)
public struct CreateListView: View {
    @ObservedObject var listService: CollaborativeListService
    @Environment(\.dismiss) private var dismiss
    
    @State private var listName = ""
    @State private var listDescription = ""
    @State private var selectedType: CollaborativeListService.CollaborativeList.ListType = .custom
    @State private var selectedTemplate: Template?
    @State private var inviteEmails: [String] = []
    @State private var newEmail = ""
    @State private var showingSettings = false
    @State private var settings = CollaborativeListService.ListSettings()
    @State private var isCreating = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    struct Template: Identifiable {
        let id = UUID()
        let name: String
        let type: CollaborativeListService.CollaborativeList.ListType
        let items: [String]
        let description: String
    }
    
    private let templates: [Template] = [
        Template(
            name: "Grocery Shopping",
            type: .shopping,
            items: ["Milk", "Bread", "Eggs", "Fruits", "Vegetables"],
            description: "Common grocery items"
        ),
        Template(
            name: "Party Planning",
            type: .project,
            items: ["Send invitations", "Order cake", "Buy decorations", "Plan menu", "Set up playlist"],
            description: "Everything for a perfect party"
        ),
        Template(
            name: "Home Renovation",
            type: .project,
            items: ["Get quotes", "Choose contractor", "Select materials", "Schedule work", "Final inspection"],
            description: "Track your renovation project"
        ),
        Template(
            name: "Moving Checklist",
            type: .moving,
            items: ["Pack boxes", "Label items", "Hire movers", "Change address", "Transfer utilities"],
            description: "Don't forget anything when moving"
        ),
        Template(
            name: "Vacation Packing",
            type: .custom,
            items: ["Passport", "Tickets", "Clothes", "Toiletries", "Chargers", "Medications"],
            description: "Essential items for travel"
        )
    ]
    
    public var body: some View {
        NavigationView {
            Form {
                // List Details
                Section {
                    TextField("List Name", text: $listName)
                        .font(.headline)
                    
                    TextField("Description (Optional)", text: $listDescription, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("List Details")
                }
                
                // List Type
                Section {
                    Picker("Type", selection: $selectedType) {
                        ForEach(CollaborativeListService.CollaborativeList.ListType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                } header: {
                    Text("List Type")
                } footer: {
                    Text("Choose a type to help organize your lists")
                }
                
                // Templates
                Section {
                    if selectedTemplate == nil {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(templates) { template in
                                    TemplateCard(template: template) {
                                        applyTemplate(template)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    } else {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Template applied: \(selectedTemplate?.name ?? "")")
                            Spacer()
                            Button("Clear") {
                                selectedTemplate = nil
                                listName = ""
                                listDescription = ""
                            }
                            .foregroundColor(.blue)
                        }
                    }
                } header: {
                    Text("Start from Template")
                }
                
                // Collaborators
                Section {
                    if inviteEmails.isEmpty {
                        Text("No collaborators added yet")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(inviteEmails, id: \.self) { email in
                            HStack {
                                Image(systemName: "person.circle")
                                    .foregroundColor(.blue)
                                Text(email)
                                Spacer()
                                Button(action: { inviteEmails.removeAll { $0 == email } }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    HStack {
                        TextField("Email address", text: $newEmail)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                        
                        Button("Add") {
                            addEmail()
                        }
                        .disabled(newEmail.isEmpty || !newEmail.contains("@"))
                    }
                } header: {
                    Text("Invite Collaborators")
                } footer: {
                    Text("You can also invite people after creating the list")
                }
                
                // Settings
                Section {
                    Button(action: { showingSettings = true }) {
                        HStack {
                            Label("List Settings", systemImage: "gearshape")
                            Spacer()
                            Text(settingsSummary)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("New List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createList()
                    }
                    .disabled(listName.isEmpty || isCreating)
                }
            }
            .sheet(isPresented: $showingSettings) {
                ListSettingsView(settings: $settings)
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .disabled(isCreating)
            .overlay {
                if isCreating {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    ProgressView("Creating list...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var settingsSummary: String {
        var summary: [String] = []
        
        if settings.requireApproval {
            summary.append("Approval required")
        }
        
        if settings.autoArchiveCompleted {
            summary.append("Auto-archive")
        }
        
        switch settings.sortOrder {
        case .priority:
            summary.append("Priority sort")
        case .alphabetical:
            summary.append("A-Z sort")
        default:
            break
        }
        
        return summary.isEmpty ? "Default" : summary.joined(separator: ", ")
    }
    
    // MARK: - Actions
    
    private func applyTemplate(_ template: Template) {
        selectedTemplate = template
        listName = template.name
        listDescription = template.description
        selectedType = template.type
    }
    
    private func addEmail() {
        let trimmedEmail = newEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !trimmedEmail.isEmpty && 
           trimmedEmail.contains("@") && 
           !inviteEmails.contains(trimmedEmail) {
            inviteEmails.append(trimmedEmail)
            newEmail = ""
        }
    }
    
    private func createList() {
        isCreating = true
        
        Task {
            do {
                let list = try await listService.createList(
                    name: listName,
                    type: selectedType,
                    description: listDescription.isEmpty ? nil : listDescription
                )
                
                // Add template items if selected
                if let template = selectedTemplate {
                    for itemTitle in template.items {
                        try await listService.addItem(to: list, title: itemTitle)
                    }
                }
                
                // Send invitations
                for email in inviteEmails {
                    try await listService.inviteCollaborator(
                        to: list,
                        email: email,
                        role: .editor
                    )
                }
                
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
                isCreating = false
            }
        }
    }
}

// MARK: - Template Card

private struct TemplateCard: View {
    let template: CreateListView.Template
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: template.type.icon)
                    .font(.title2)
                    .foregroundColor(Color(template.type.color))
                    .frame(width: 40, height: 40)
                    .background(Color(template.type.color).opacity(0.2))
                    .cornerRadius(8)
                
                Text(template.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("\(template.items.count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(width: 140)
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - List Settings View

@available(iOS 15.0, *)
struct ListSettingsView: View {
    @Binding var settings: CollaborativeListService.ListSettings
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("Allow Guest Viewers", isOn: $settings.allowGuests)
                    Toggle("Require Approval for Changes", isOn: $settings.requireApproval)
                    Toggle("Notify on Changes", isOn: $settings.notifyOnChanges)
                } header: {
                    Text("Collaboration")
                }
                
                Section {
                    Toggle("Auto-archive Completed Lists", isOn: $settings.autoArchiveCompleted)
                    Toggle("Show Completed Items", isOn: $settings.showCompletedItems)
                } header: {
                    Text("Display")
                }
                
                Section {
                    Picker("Sort Order", selection: $settings.sortOrder) {
                        ForEach(CollaborativeListService.ListSettings.SortOrder.allCases, id: \.self) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }
                    
                    Picker("Group By", selection: $settings.groupBy) {
                        ForEach(CollaborativeListService.ListSettings.GroupBy.allCases, id: \.self) { grouping in
                            Text(grouping.rawValue).tag(grouping)
                        }
                    }
                } header: {
                    Text("Organization")
                }
            }
            .navigationTitle("List Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}