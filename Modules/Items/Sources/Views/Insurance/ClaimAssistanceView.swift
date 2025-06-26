//
//  ClaimAssistanceView.swift
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
//  Module: Items
//  Dependencies: SwiftUI, Core, SharedUI
//  Testing: ItemsTests/Insurance/ClaimAssistanceViewTests.swift
//
//  Description: Insurance claim assistance wizard providing step-by-step guidance for filing
//  claims, documenting losses, and managing claim processes with automated report generation
//  and comprehensive claim tracking features.
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import Core
import SharedUI

public struct ClaimAssistanceView: View {
    @StateObject private var viewModel: ClaimAssistanceViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    
    public init(
        policy: InsurancePolicy? = nil,
        items: [Item] = [],
        insuranceRepository: InsurancePolicyRepository,
        itemRepository: any ItemRepository
    ) {
        self._viewModel = StateObject(wrappedValue: ClaimAssistanceViewModel(
            policy: policy,
            preselectedItems: items,
            insuranceRepository: insuranceRepository,
            itemRepository: itemRepository
        ))
    }
    
    public var body: some View {
        NavigationView {
            if viewModel.selectedTemplate == nil {
                templateSelectionView
            } else {
                claimWizardView
            }
        }
    }
    
    // MARK: - Template Selection
    
    private var templateSelectionView: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Header
                VStack(spacing: AppSpacing.sm) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(AppColors.primary)
                    
                    Text("What type of claim?")
                        .textStyle(.headlineLarge)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Text("Select the type of claim you need to file")
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .appPadding(.bottom, AppSpacing.xl)
                
                // Claim type options
                ForEach(ClaimTemplate.defaultTemplates, id: \.id) { template in
                    ClaimTypeCard(
                        template: template,
                        isSelected: viewModel.selectedTemplate?.id == template.id
                    ) {
                        viewModel.selectTemplate(template)
                    }
                }
            }
            .appPadding()
        }
        .background(AppColors.background)
        .navigationTitle("Claim Assistance")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - Claim Wizard
    
    private var claimWizardView: some View {
        VStack(spacing: 0) {
            // Progress indicator
            ProgressIndicator(
                steps: viewModel.selectedTemplate?.steps.count ?? 0,
                currentStep: currentStep
            )
            .appPadding()
            
            // Current step content
            TabView(selection: $currentStep) {
                ForEach(Array(viewModel.wizardSteps.enumerated()), id: \.offset) { index, step in
                    WizardStepView(
                        step: step,
                        viewModel: viewModel,
                        onNext: {
                            withAnimation {
                                if index < viewModel.wizardSteps.count - 1 {
                                    currentStep = index + 1
                                }
                            }
                        },
                        onPrevious: {
                            withAnimation {
                                if index > 0 {
                                    currentStep = index - 1
                                }
                            }
                        }
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Navigation buttons
            HStack(spacing: AppSpacing.md) {
                if currentStep > 0 {
                    Button("Previous") {
                        withAnimation {
                            currentStep -= 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.textSecondary)
                }
                
                Spacer()
                
                if currentStep < viewModel.wizardSteps.count - 1 {
                    PrimaryButton(title: "Next") {
                        withAnimation {
                            currentStep += 1
                        }
                    }
                    .disabled(!viewModel.canProceedFromStep(currentStep))
                } else {
                    PrimaryButton(title: "Complete") {
                        Task {
                            await viewModel.completeClaim()
                            dismiss()
                        }
                    }
                }
            }
            .appPadding()
            .background(AppColors.secondaryBackground)
        }
        .navigationTitle(viewModel.selectedTemplate?.title ?? "Claim Assistance")
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

// MARK: - Supporting Views

struct ClaimTypeCard: View {
    let template: ClaimTemplate
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: template.type.icon)
                    .font(.title2)
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 50, height: 50)
                    .background(AppColors.primaryMuted)
                    .cornerRadius(AppCornerRadius.medium)
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(template.type.displayName)
                        .textStyle(.bodyLarge)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Text(template.description)
                        .textStyle(.bodySmall)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(AppColors.textTertiary)
            }
            .appPadding()
            .background(isSelected ? AppColors.primaryMuted : AppColors.surface)
            .cornerRadius(AppCornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ProgressIndicator: View {
    let steps: Int
    let currentStep: Int
    
    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            ForEach(0..<steps, id: \.self) { index in
                if index > 0 {
                    Rectangle()
                        .fill(index <= currentStep ? AppColors.primary : AppColors.surface)
                        .frame(height: 2)
                }
                
                Circle()
                    .fill(index <= currentStep ? AppColors.primary : AppColors.surface)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Text("\(index + 1)")
                            .textStyle(.labelSmall)
                            .foregroundStyle(index <= currentStep ? .white : AppColors.textSecondary)
                    )
            }
        }
    }
}

struct WizardStepView: View {
    let step: WizardStep
    @ObservedObject var viewModel: ClaimAssistanceViewModel
    let onNext: () -> Void
    let onPrevious: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                // Step header
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(step.title)
                        .textStyle(.headlineMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Text(step.description)
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Step content
                switch step.type {
                case .policySelection:
                    PolicySelectionView(viewModel: viewModel)
                    
                case .itemSelection:
                    ItemSelectionView(viewModel: viewModel)
                    
                case .incidentDetails:
                    IncidentDetailsView(viewModel: viewModel)
                    
                case .documentation:
                    DocumentationView(viewModel: viewModel)
                    
                case .review:
                    ClaimReviewView(viewModel: viewModel)
                    
                case .templateStep(let claimStep):
                    ClaimStepView(step: claimStep, viewModel: viewModel)
                }
                
                // Tips if available
                if !step.tips.isEmpty {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Label("Tips", systemImage: "lightbulb")
                            .textStyle(.labelMedium)
                            .foregroundStyle(AppColors.primary)
                        
                        ForEach(step.tips, id: \.self) { tip in
                            HStack(alignment: .top, spacing: AppSpacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(AppColors.success)
                                    .padding(.top, 2)
                                
                                Text(tip)
                                    .textStyle(.bodySmall)
                                    .foregroundStyle(AppColors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .appPadding()
                    .background(AppColors.primaryMuted)
                    .cornerRadius(AppCornerRadius.medium)
                }
            }
            .appPadding()
        }
    }
}

// MARK: - Step Views

struct PolicySelectionView: View {
    @ObservedObject var viewModel: ClaimAssistanceViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            if viewModel.selectedPolicy == nil {
                Text("Select the insurance policy for this claim:")
                    .textStyle(.bodyMedium)
                    .foregroundStyle(AppColors.textSecondary)
                
                ForEach(viewModel.availablePolicies) { policy in
                    PolicySelectionCard(
                        policy: policy,
                        isSelected: viewModel.selectedPolicy?.id == policy.id
                    ) {
                        viewModel.selectedPolicy = policy
                    }
                }
            } else if let policy = viewModel.selectedPolicy {
                SelectedPolicyCard(policy: policy) {
                    viewModel.selectedPolicy = nil
                }
            }
        }
    }
}

struct ItemSelectionView: View {
    @ObservedObject var viewModel: ClaimAssistanceViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Select items affected by this claim:")
                .textStyle(.bodyMedium)
                .foregroundStyle(AppColors.textSecondary)
            
            ForEach(viewModel.availableItems) { item in
                ItemSelectionCard(
                    item: item,
                    isSelected: viewModel.selectedItems.contains(item.id)
                ) {
                    viewModel.toggleItem(item)
                }
            }
            
            if !viewModel.selectedItems.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Total Value: \(viewModel.totalSelectedValue, format: .currency(code: "USD"))")
                        .textStyle(.bodyLarge)
                        .foregroundStyle(AppColors.primary)
                    
                    Text("\(viewModel.selectedItems.count) items selected")
                        .textStyle(.bodySmall)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .appPadding()
                .background(AppColors.primaryMuted)
                .cornerRadius(AppCornerRadius.medium)
            }
        }
    }
}

struct IncidentDetailsView: View {
    @ObservedObject var viewModel: ClaimAssistanceViewModel
    @State private var showingDatePicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Date of incident
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Date of Incident")
                    .textStyle(.labelMedium)
                    .foregroundStyle(AppColors.textSecondary)
                
                Button(action: { showingDatePicker = true }) {
                    HStack {
                        Text(viewModel.incidentDate, format: .dateTime.month().day().year())
                            .foregroundStyle(AppColors.textPrimary)
                        Spacer()
                        Image(systemName: "calendar")
                            .foregroundStyle(AppColors.primary)
                    }
                    .appPadding()
                    .background(AppColors.surface)
                    .cornerRadius(AppCornerRadius.small)
                }
            }
            
            // Description
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Description of Incident")
                    .textStyle(.labelMedium)
                    .foregroundStyle(AppColors.textSecondary)
                
                TextEditor(text: $viewModel.incidentDescription)
                    .frame(minHeight: 100)
                    .padding(AppSpacing.sm)
                    .background(AppColors.surface)
                    .cornerRadius(AppCornerRadius.small)
            }
            
            // Location
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Location")
                    .textStyle(.labelMedium)
                    .foregroundStyle(AppColors.textSecondary)
                
                TextField("Where did this occur?", text: $viewModel.incidentLocation)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Police report (if applicable)
            if viewModel.selectedTemplate?.type == .theft {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Toggle("Police Report Filed", isOn: $viewModel.hasPoliceReport)
                    
                    if viewModel.hasPoliceReport {
                        TextField("Report Number", text: $viewModel.policeReportNumber)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                .appPadding()
                .background(AppColors.surface)
                .cornerRadius(AppCornerRadius.medium)
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            ClaimDatePickerSheet(
                date: $viewModel.incidentDate,
                maxDate: Date()
            )
        }
    }
}

struct DocumentationView: View {
    @ObservedObject var viewModel: ClaimAssistanceViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Required Documents")
                .textStyle(.headlineSmall)
                .foregroundStyle(AppColors.textPrimary)
            
            ForEach(viewModel.documentChecklist.items) { item in
                DocumentChecklistRow(
                    item: item,
                    isCollected: viewModel.collectedDocuments.contains(item.id)
                ) {
                    viewModel.toggleDocument(item.id)
                }
            }
            
            // Progress summary
            let collected = viewModel.collectedDocuments.count
            let required = viewModel.documentChecklist.items.filter { $0.isRequired }.count
            
            VStack(spacing: AppSpacing.sm) {
                HStack {
                    Text("\(collected) of \(required) required documents collected")
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Spacer()
                    
                    if collected >= required {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppColors.success)
                    }
                }
                
                ProgressView(value: Double(collected), total: Double(required))
                    .tint(AppColors.primary)
            }
            .appPadding()
            .background(AppColors.surface)
            .cornerRadius(AppCornerRadius.medium)
        }
    }
}

struct ClaimReviewView: View {
    @ObservedObject var viewModel: ClaimAssistanceViewModel
    @State private var showingEmail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            // Summary sections
            if let policy = viewModel.selectedPolicy {
                ReviewSection(title: "Policy") {
                    PolicySummaryCard(policy: policy)
                }
            }
            
            ReviewSection(title: "Affected Items") {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    ForEach(viewModel.getSelectedItems()) { item in
                        HStack {
                            Text(item.name)
                                .textStyle(.bodyMedium)
                            Spacer()
                            Text(item.value ?? 0, format: .currency(code: "USD"))
                                .textStyle(.bodyMedium)
                                .foregroundStyle(AppColors.primary)
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Total Value")
                            .textStyle(.bodyLarge)
                        Spacer()
                        Text(viewModel.totalSelectedValue, format: .currency(code: "USD"))
                            .textStyle(.bodyLarge)
                            .foregroundStyle(AppColors.primary)
                    }
                }
                .appPadding()
                .background(AppColors.surface)
                .cornerRadius(AppCornerRadius.medium)
            }
            
            ReviewSection(title: "Incident Details") {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    LabeledText(label: "Date", value: viewModel.incidentDate.formatted(date: .abbreviated, time: .omitted))
                    LabeledText(label: "Location", value: viewModel.incidentLocation)
                    if viewModel.hasPoliceReport {
                        LabeledText(label: "Police Report", value: viewModel.policeReportNumber)
                    }
                }
                .appPadding()
                .background(AppColors.surface)
                .cornerRadius(AppCornerRadius.medium)
            }
            
            // Actions
            VStack(spacing: AppSpacing.sm) {
                Button {
                    showingEmail = true
                } label: {
                    Label("Generate Claim Email", systemImage: "envelope")
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.textSecondary)
                
                Button {
                    viewModel.exportClaimSummary()
                } label: {
                    Label("Export Summary", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.textSecondary)
            }
        }
        .sheet(isPresented: $showingEmail) {
            ClaimEmailView(
                emailContent: viewModel.generateClaimEmail(),
                recipientEmail: viewModel.selectedPolicy?.contactInfo.claimsEmail
            )
        }
    }
}

// MARK: - Helper Views

struct PolicySelectionCard: View {
    let policy: InsurancePolicy
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(policy.provider)
                        .textStyle(.bodyLarge)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(policy.policyNumber)
                        .textStyle(.bodySmall)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppColors.primary)
                }
            }
            .appPadding()
            .background(isSelected ? AppColors.primaryMuted : AppColors.surface)
            .cornerRadius(AppCornerRadius.medium)
        }
    }
}

struct ItemSelectionCard: View {
    let item: Item
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: item.category.icon)
                    .font(.title3)
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 40, height: 40)
                    .background(AppColors.primaryMuted)
                    .cornerRadius(AppCornerRadius.small)
                
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(item.name)
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    if let brand = item.brand {
                        Text(brand)
                            .textStyle(.bodySmall)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                
                Spacer()
                
                if let value = item.value {
                    Text(value, format: .currency(code: "USD"))
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.primary)
                }
                
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isSelected ? AppColors.primary : AppColors.textTertiary)
            }
            .appPadding()
            .background(AppColors.surface)
            .cornerRadius(AppCornerRadius.medium)
        }
    }
}

struct DocumentChecklistRow: View {
    let item: DocumentChecklistItem
    let isCollected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Image(systemName: isCollected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isCollected ? AppColors.success : AppColors.textTertiary)
                    
                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        HStack {
                            Text(item.name)
                                .textStyle(.bodyMedium)
                                .foregroundStyle(AppColors.textPrimary)
                            
                            if item.isRequired {
                                Text("Required")
                                    .textStyle(.labelSmall)
                                    .foregroundStyle(AppColors.error)
                            }
                        }
                        
                        Text(item.description)
                            .textStyle(.bodySmall)
                            .foregroundStyle(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                }
                
                if let tips = item.tips {
                    HStack(alignment: .top, spacing: AppSpacing.sm) {
                        Image(systemName: "lightbulb")
                            .font(.caption)
                            .foregroundStyle(AppColors.warning)
                        
                        Text(tips)
                            .textStyle(.labelSmall)
                            .foregroundStyle(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(AppSpacing.sm)
                    .background(AppColors.warningMuted)
                    .cornerRadius(AppCornerRadius.small)
                }
            }
            .appPadding()
            .background(AppColors.surface)
            .cornerRadius(AppCornerRadius.medium)
        }
    }
}

struct LabeledText: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .textStyle(.bodyMedium)
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
            Text(value)
                .textStyle(.bodyMedium)
                .foregroundStyle(AppColors.textPrimary)
        }
    }
}

struct ReviewSection<Content: View>: View {
    let title: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .textStyle(.labelMedium)
                .foregroundStyle(AppColors.textSecondary)
            
            content()
        }
    }
}