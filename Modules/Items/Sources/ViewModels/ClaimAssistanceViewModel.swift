//
//  ClaimAssistanceViewModel.swift
//  Items Module
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
//  Module: Items
//  Dependencies: SwiftUI, Core, SharedUI, Combine
//  Testing: ItemsTests/ClaimAssistanceViewModelTests.swift
//
//  Description: View model for managing insurance claim assistance and wizard flows
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation
import SwiftUI
import Core
import SharedUI
import Combine

// MARK: - Wizard Step Types

enum WizardStepType {
    case policySelection
    case itemSelection
    case incidentDetails
    case documentation
    case review
    case templateStep(ClaimStep)
}

struct WizardStep {
    let type: WizardStepType
    let title: String
    let description: String
    let tips: [String]
}

// MARK: - View Model

@MainActor
final class ClaimAssistanceViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedTemplate: ClaimTemplate?
    @Published var selectedPolicy: InsurancePolicy?
    @Published var selectedItems = Set<UUID>()
    @Published var incidentDate = Date()
    @Published var incidentDescription = ""
    @Published var incidentLocation = ""
    @Published var hasPoliceReport = false
    @Published var policeReportNumber = ""
    @Published var collectedDocuments = Set<UUID>()
    @Published var availablePolicies: [InsurancePolicy] = []
    @Published var availableItems: [Item] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    // MARK: - Properties
    private let insuranceRepository: InsurancePolicyRepository
    private let itemRepository: any ItemRepository
    private let preselectedItems: [Item]
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var wizardSteps: [WizardStep] {
        guard let template = selectedTemplate else { return [] }
        
        var steps: [WizardStep] = []
        
        // Add policy selection step if not preselected
        if selectedPolicy == nil {
            steps.append(WizardStep(
                type: .policySelection,
                title: "Select Policy",
                description: "Choose the insurance policy for this claim",
                tips: ["Make sure the policy was active on the date of loss"]
            ))
        }
        
        // Add item selection step
        steps.append(WizardStep(
            type: .itemSelection,
            title: "Select Items",
            description: "Choose which items are affected by this claim",
            tips: ["Include all damaged, lost, or stolen items", "The total value will be calculated automatically"]
        ))
        
        // Add incident details step
        steps.append(WizardStep(
            type: .incidentDetails,
            title: "Incident Details",
            description: "Provide information about what happened",
            tips: template.type == .theft ? ["File police report within 24-48 hours"] : []
        ))
        
        // Add template-specific steps
        for claimStep in template.steps {
            steps.append(WizardStep(
                type: .templateStep(claimStep),
                title: claimStep.title,
                description: claimStep.description,
                tips: claimStep.actionItems
            ))
        }
        
        // Add documentation step
        steps.append(WizardStep(
            type: .documentation,
            title: "Gather Documents",
            description: "Collect all required documentation for your claim",
            tips: ["Keep copies of all documents", "Take clear photos of physical documents"]
        ))
        
        // Add review step
        steps.append(WizardStep(
            type: .review,
            title: "Review & Submit",
            description: "Review your claim information and generate submission documents",
            tips: ["Double-check all information is accurate", "Save copies of all generated documents"]
        ))
        
        return steps
    }
    
    var documentChecklist: DocumentChecklist {
        guard let template = selectedTemplate,
              let policy = selectedPolicy else {
            return ClaimAssistanceService.generateDocumentChecklist(
                template: ClaimTemplate.defaultTemplates.first { $0.type == .damage }!,
                policy: InsurancePolicy.preview,
                items: []
            )
        }
        
        return ClaimAssistanceService.generateDocumentChecklist(
            template: template,
            policy: policy,
            items: getSelectedItems()
        )
    }
    
    var totalSelectedValue: Decimal {
        getSelectedItems().reduce(0) { sum, item in
            sum + (item.value ?? 0) * Decimal(item.quantity)
        }
    }
    
    // MARK: - Initialization
    init(
        policy: InsurancePolicy? = nil,
        preselectedItems: [Item] = [],
        insuranceRepository: InsurancePolicyRepository,
        itemRepository: any ItemRepository
    ) {
        self.selectedPolicy = policy
        self.preselectedItems = preselectedItems
        self.insuranceRepository = insuranceRepository
        self.itemRepository = itemRepository
        
        // Preselect items if provided
        for item in preselectedItems {
            selectedItems.insert(item.id)
        }
        
        Task {
            await loadData()
        }
    }
    
    // MARK: - Data Loading
    private func loadData() async {
        isLoading = true
        
        do {
            // Load policies if not preselected
            if selectedPolicy == nil {
                availablePolicies = try await insuranceRepository.fetchActivePolicies()
            }
            
            // Load all items
            let allItems = try await itemRepository.fetchAll()
            
            // Filter items based on selected policy if available
            if let policy = selectedPolicy {
                availableItems = allItems.filter { policy.itemIds.contains($0.id) }
            } else {
                availableItems = allItems
            }
            
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
    
    // MARK: - Template Selection
    func selectTemplate(_ template: ClaimTemplate) {
        selectedTemplate = template
        
        // Auto-select police report for theft claims
        if template.type == .theft {
            hasPoliceReport = true
        }
    }
    
    // MARK: - Item Management
    func toggleItem(_ item: Item) {
        if selectedItems.contains(item.id) {
            selectedItems.remove(item.id)
        } else {
            selectedItems.insert(item.id)
        }
    }
    
    func getSelectedItems() -> [Item] {
        availableItems.filter { selectedItems.contains($0.id) }
    }
    
    // MARK: - Document Management
    func toggleDocument(_ documentId: UUID) {
        if collectedDocuments.contains(documentId) {
            collectedDocuments.remove(documentId)
        } else {
            collectedDocuments.insert(documentId)
        }
    }
    
    // MARK: - Validation
    func canProceedFromStep(_ stepIndex: Int) -> Bool {
        guard stepIndex < wizardSteps.count else { return false }
        
        let step = wizardSteps[stepIndex]
        
        switch step.type {
        case .policySelection:
            return selectedPolicy != nil
            
        case .itemSelection:
            return !selectedItems.isEmpty
            
        case .incidentDetails:
            return !incidentDescription.isEmpty && !incidentLocation.isEmpty &&
                   (!hasPoliceReport || !policeReportNumber.isEmpty)
            
        case .documentation:
            let requiredDocs = documentChecklist.items.filter { $0.isRequired }
            let collectedRequired = requiredDocs.filter { collectedDocuments.contains($0.id) }
            return collectedRequired.count == requiredDocs.count
            
        case .review:
            return true
            
        case .templateStep:
            return true // Template steps are informational
        }
    }
    
    // MARK: - Claim Generation
    func generateClaimEmail() -> String {
        guard let template = selectedTemplate,
              let policy = selectedPolicy else { return "" }
        
        let claim = InsuranceClaim(
            claimNumber: "PENDING-\(UUID().uuidString.prefix(8))",
            dateOfLoss: incidentDate,
            dateReported: Date(),
            itemIds: selectedItems,
            description: incidentDescription,
            claimAmount: totalSelectedValue
        )
        
        // In a real app, this would come from user profile
        let personalInfo = (name: "User Name", phone: nil as String?, email: nil as String?, address: incidentLocation)
        
        // Generate claim email content
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        var emailContent = "Subject: Insurance Claim - \(template.title)\n\n"
        emailContent += "To: \(policy.contactInfo.claimsEmail ?? "claims@insurance.com")\n\n"
        emailContent += "Policy Number: \(policy.policyNumber)\n"
        emailContent += "Claim Date: \(dateFormatter.string(from: Date()))\n"
        emailContent += "Date of Loss: \(dateFormatter.string(from: incidentDate))\n\n"
        emailContent += "Dear Claims Department,\n\n"
        emailContent += "I am filing a claim for \(template.type.displayName.lowercased()) under policy \(policy.policyNumber).\n\n"
        emailContent += "Incident Details:\n"
        emailContent += "Date: \(dateFormatter.string(from: incidentDate))\n"
        emailContent += "Location: \(incidentLocation)\n"
        emailContent += "Description: \(incidentDescription)\n"
        
        if hasPoliceReport {
            emailContent += "\n\nPolice Report Number: \(policeReportNumber)"
        }
        
        emailContent += "\n\nAffected Items:\n"
        for item in getSelectedItems() {
            emailContent += "- \(item.name): \(item.value?.formatted(.currency(code: "USD")) ?? "N/A")\n"
        }
        
        emailContent += "\n\nTotal Claim Amount: \(totalSelectedValue.formatted(.currency(code: "USD")))"
        emailContent += "\n\nPlease contact me at your earliest convenience to process this claim."
        emailContent += "\n\nSincerely,\n\(personalInfo.name)"
        
        return emailContent
    }
    
    func exportClaimSummary() {
        // Export claim summary as PDF or share sheet
        // Implementation would generate a document with all claim details
    }
    
    func completeClaim() async {
        // Save claim progress and create a claim record
        guard let policy = selectedPolicy,
              let template = selectedTemplate else { return }
        
        let claim = InsuranceClaim(
            claimNumber: "PENDING-\(UUID().uuidString.prefix(8))",
            dateOfLoss: incidentDate,
            dateReported: Date(),
            status: .filed,
            itemIds: selectedItems,
            description: incidentDescription,
            claimAmount: totalSelectedValue,
            adjustorName: nil,
            adjustorPhone: nil,
            notes: hasPoliceReport ? "Police Report #: \(policeReportNumber)" : nil
        )
        
        do {
            try await insuranceRepository.addClaim(claim, to: policy.id)
        } catch {
            self.error = error
        }
    }
}

// MARK: - Helper Views

struct ClaimStepView: View {
    let step: ClaimStep
    @ObservedObject var viewModel: ClaimAssistanceViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            // Action items
            if !step.actionItems.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("Action Items")
                        .textStyle(.labelMedium)
                        .foregroundStyle(AppColors.textSecondary)
                    
                    ForEach(Array(step.actionItems.enumerated()), id: \.offset) { index, item in
                        HStack(alignment: .top, spacing: AppSpacing.sm) {
                            Text("\(index + 1).")
                                .textStyle(.bodyMedium)
                                .foregroundStyle(AppColors.primary)
                                .frame(width: 20)
                            
                            Text(item)
                                .textStyle(.bodyMedium)
                                .foregroundStyle(AppColors.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Spacer()
                        }
                    }
                }
            }
            
            // Warning message
            if let warning = step.warningMessage {
                HStack(alignment: .top, spacing: AppSpacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(AppColors.warning)
                    
                    Text(warning)
                        .textStyle(.bodySmall)
                        .foregroundStyle(AppColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .appPadding()
                .background(AppColors.warningMuted)
                .cornerRadius(AppCornerRadius.medium)
            }
            
            // Estimated time
            if let time = step.estimatedTime {
                HStack {
                    Image(systemName: "clock")
                        .foregroundStyle(AppColors.textSecondary)
                    Text("Estimated time: \(time)")
                        .textStyle(.bodySmall)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
    }
}

struct SelectedPolicyCard: View {
    let policy: InsurancePolicy
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Selected Policy")
                    .textStyle(.labelSmall)
                    .foregroundStyle(AppColors.textSecondary)
                
                Text(policy.provider)
                    .textStyle(.bodyLarge)
                    .foregroundStyle(AppColors.textPrimary)
                
                Text(policy.policyNumber)
                    .textStyle(.bodySmall)
                    .foregroundStyle(AppColors.textSecondary)
            }
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
        .appPadding()
        .background(AppColors.primaryMuted)
        .cornerRadius(AppCornerRadius.medium)
    }
}

struct PolicySummaryCard: View {
    let policy: InsurancePolicy
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text(policy.provider)
                    .textStyle(.bodyLarge)
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                StatusBadge(status: policy.status)
            }
            
            Text(policy.policyNumber)
                .textStyle(.bodySmall)
                .foregroundStyle(AppColors.textSecondary)
            
            HStack {
                Label("Coverage", systemImage: "shield")
                    .textStyle(.labelSmall)
                Spacer()
                Text(policy.coverageAmount, format: .currency(code: "USD"))
                    .textStyle(.bodyMedium)
                    .foregroundStyle(AppColors.primary)
            }
            
            HStack {
                Label("Deductible", systemImage: "minus.circle")
                    .textStyle(.labelSmall)
                Spacer()
                Text(policy.deductible, format: .currency(code: "USD"))
                    .textStyle(.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
            }
        }
        .appPadding()
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.medium)
    }
}

struct ClaimEmailView: View {
    let emailContent: String
    let recipientEmail: String?
    @Environment(\.dismiss) private var dismiss
    @State private var copiedToClipboard = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Recipient info
                    if let email = recipientEmail {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("Send to:")
                                .textStyle(.labelMedium)
                                .foregroundStyle(AppColors.textSecondary)
                            Text(email)
                                .textStyle(.bodyMedium)
                                .foregroundStyle(AppColors.primary)
                        }
                        .appPadding()
                        .background(AppColors.surface)
                        .cornerRadius(AppCornerRadius.medium)
                    }
                    
                    // Email content
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        HStack {
                            Text("Email Content")
                                .textStyle(.labelMedium)
                                .foregroundStyle(AppColors.textSecondary)
                            
                            Spacer()
                            
                            Button {
                                UIPasteboard.general.string = emailContent
                                copiedToClipboard = true
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    copiedToClipboard = false
                                }
                            } label: {
                                Label(
                                    copiedToClipboard ? "Copied!" : "Copy",
                                    systemImage: copiedToClipboard ? "checkmark" : "doc.on.doc"
                                )
                                .textStyle(.labelSmall)
                                .foregroundStyle(AppColors.primary)
                            }
                        }
                        
                        Text(emailContent)
                            .textStyle(.bodySmall)
                            .foregroundStyle(AppColors.textPrimary)
                            .font(.system(.body, design: .monospaced))
                            .appPadding()
                            .background(AppColors.secondaryBackground)
                            .cornerRadius(AppCornerRadius.small)
                    }
                }
                .appPadding()
            }
            .background(AppColors.background)
            .navigationTitle("Claim Email")
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

struct ClaimDatePickerSheet: View {
    @Binding var date: Date
    let maxDate: Date
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            DatePicker(
                "Select Date",
                selection: $date,
                in: ...maxDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .appPadding()
            .navigationTitle("Select Date")
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