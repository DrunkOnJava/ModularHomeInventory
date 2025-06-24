import SwiftUI
import Core
import SharedUI

public struct WarrantyTransferView: View {
    @StateObject private var viewModel: WarrantyTransferViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    
    public init(
        warranty: Warranty,
        item: Item,
        warrantyRepository: any WarrantyRepository
    ) {
        self._viewModel = StateObject(wrappedValue: WarrantyTransferViewModel(
            warranty: warranty,
            item: item,
            warrantyRepository: warrantyRepository
        ))
    }
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                TransferProgressIndicator(
                    currentStep: currentStep,
                    totalSteps: 5
                )
                .appPadding()
                .background(AppColors.secondaryBackground)
                
                // Step content
                TabView(selection: $currentStep) {
                    // Step 1: Check Eligibility
                    transferEligibilityView
                        .tag(0)
                    
                    // Step 2: Transfer Details
                    transferDetailsView
                        .tag(1)
                    
                    // Step 3: New Owner Information
                    newOwnerInfoView
                        .tag(2)
                    
                    // Step 4: Documentation
                    documentationView
                        .tag(3)
                    
                    // Step 5: Review & Submit
                    reviewView
                        .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Navigation buttons
                navigationButtons
            }
            .navigationTitle("Transfer Warranty")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Transfer Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
    
    // MARK: - Step Views
    
    private var transferEligibilityView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Warranty Transfer Eligibility")
                        .textStyle(.headlineMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Text("Let's check if this warranty can be transferred")
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                // Warranty info
                WarrantyInfoCard(warranty: viewModel.warranty, item: viewModel.item)
                
                // Transferability status
                if viewModel.isCheckingEligibility {
                    HStack {
                        ProgressView()
                        Text("Checking transferability...")
                            .textStyle(.bodyMedium)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .appPadding()
                } else {
                    TransferabilityStatusCard(
                        transferability: viewModel.transferability,
                        validationResult: viewModel.validationResult
                    )
                }
                
                // Transfer conditions
                if let transferability = viewModel.transferability,
                   transferability.isTransferable {
                    TransferConditionsCard(conditions: transferability.transferConditions)
                }
                
                // Previous transfers
                if let history = viewModel.transferability?.transferHistory,
                   !history.isEmpty {
                    PreviousTransfersCard(transfers: history)
                }
            }
            .appPadding()
        }
    }
    
    private var transferDetailsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Transfer Details")
                        .textStyle(.headlineMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Text("Provide information about the transfer")
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                // Transfer type
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Transfer Type")
                        .textStyle(.labelMedium)
                        .foregroundStyle(AppColors.textSecondary)
                    
                    ForEach(TransferType.allCases, id: \.self) { type in
                        TransferTypeOption(
                            type: type,
                            isSelected: viewModel.transferType == type
                        ) {
                            viewModel.transferType = type
                        }
                    }
                }
                
                // Transfer date
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Transfer Date")
                        .textStyle(.labelMedium)
                        .foregroundStyle(AppColors.textSecondary)
                    
                    DatePicker(
                        "Transfer Date",
                        selection: $viewModel.transferDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .datePickerStyle(.graphical)
                    .appPadding()
                    .background(AppColors.surface)
                    .cornerRadius(AppCornerRadius.medium)
                }
                
                // Current owner info
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Your Information (Current Owner)")
                        .textStyle(.labelMedium)
                        .foregroundStyle(AppColors.textSecondary)
                    
                    VStack(spacing: AppSpacing.sm) {
                        TextField("Your Name", text: $viewModel.fromOwnerName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("Email", text: $viewModel.fromOwnerEmail)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        
                        TextField("Phone", text: $viewModel.fromOwnerPhone)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.phonePad)
                    }
                }
            }
            .appPadding()
        }
    }
    
    private var newOwnerInfoView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("New Owner Information")
                        .textStyle(.headlineMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Text("Enter the details of the new owner")
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                // New owner details
                VStack(spacing: AppSpacing.sm) {
                    TextField("New Owner Name", text: $viewModel.toOwnerName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Email", text: $viewModel.toOwnerEmail)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    TextField("Phone", text: $viewModel.toOwnerPhone)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.phonePad)
                    
                    TextField("Address", text: $viewModel.toOwnerAddress, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(2...4)
                }
                
                // Transfer fee (if applicable)
                if let conditions = viewModel.transferability?.transferConditions,
                   conditions.requiresFee,
                   let feeAmount = conditions.feeAmount {
                    TransferFeeCard(amount: feeAmount, isPaid: $viewModel.transferFeePaid)
                }
                
                // Additional notes
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Additional Notes (Optional)")
                        .textStyle(.labelMedium)
                        .foregroundStyle(AppColors.textSecondary)
                    
                    TextEditor(text: $viewModel.transferNotes)
                        .frame(minHeight: 100)
                        .padding(AppSpacing.sm)
                        .background(AppColors.surface)
                        .cornerRadius(AppCornerRadius.small)
                }
            }
            .appPadding()
        }
    }
    
    private var documentationView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Documentation")
                        .textStyle(.headlineMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Text("Complete the transfer checklist")
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                // Transfer checklist
                if let checklist = viewModel.transferChecklist {
                    VStack(spacing: AppSpacing.md) {
                        ForEach(checklist.items) { item in
                            ChecklistItemRow(
                                item: item,
                                isCompleted: viewModel.completedChecklistItems.contains(item.id)
                            ) {
                                viewModel.toggleChecklistItem(item.id)
                            }
                        }
                    }
                    
                    // Estimated completion time
                    HStack {
                        Image(systemName: "clock")
                            .foregroundStyle(AppColors.textSecondary)
                        Text("Estimated completion: \(checklist.estimatedCompletionTime)")
                            .textStyle(.bodySmall)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .appPadding()
                    .background(AppColors.surface)
                    .cornerRadius(AppCornerRadius.medium)
                }
                
                // Generate documents
                VStack(spacing: AppSpacing.sm) {
                    Button {
                        viewModel.generateTransferAgreement()
                    } label: {
                        Label("Generate Transfer Agreement", systemImage: "doc.text")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.textSecondary)
                    
                    if let conditions = viewModel.transferability?.transferConditions,
                       conditions.requiresNotification {
                        Button {
                            viewModel.generateProviderNotification()
                        } label: {
                            Label("Generate Provider Notification", systemImage: "envelope")
                        }
                        .buttonStyle(.borderedProminent)
                    .tint(AppColors.textSecondary)
                    }
                }
            }
            .appPadding()
        }
    }
    
    private var reviewView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Review Transfer")
                        .textStyle(.headlineMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Text("Review all details before submitting")
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                // Transfer summary
                TransferSummaryCard(
                    warranty: viewModel.warranty,
                    item: viewModel.item,
                    transferType: viewModel.transferType,
                    transferDate: viewModel.transferDate,
                    fromOwner: viewModel.getFromOwner(),
                    toOwner: viewModel.getToOwner()
                )
                
                // Adjusted warranty terms (if applicable)
                if let adjustedEndDate = viewModel.validationResult?.adjustedEndDate {
                    AdjustedTermsCard(
                        originalEndDate: viewModel.warranty.endDate,
                        adjustedEndDate: adjustedEndDate
                    )
                }
                
                // Warnings
                if let issues = viewModel.validationResult?.issues.filter({ $0.severity == .warning }),
                   !issues.isEmpty {
                    WarningsCard(issues: issues)
                }
                
                // Submit button
                PrimaryButton(title: "Submit Transfer") {
                    Task {
                        await viewModel.submitTransfer()
                        dismiss()
                    }
                }
                .disabled(!viewModel.canSubmitTransfer)
            }
            .appPadding()
        }
    }
    
    // MARK: - Navigation
    
    private var navigationButtons: some View {
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
            
            if currentStep < 4 {
                PrimaryButton(title: "Next") {
                    withAnimation {
                        currentStep += 1
                    }
                }
                .disabled(!viewModel.canProceedFromStep(currentStep))
            }
        }
        .appPadding()
        .background(AppColors.secondaryBackground)
    }
}

// MARK: - Supporting Views

struct TransferProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    
    private let stepTitles = [
        "Eligibility",
        "Details",
        "New Owner",
        "Documents",
        "Review"
    ]
    
    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack(spacing: 0) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    if index > 0 {
                        Rectangle()
                            .fill(index <= currentStep ? AppColors.primary : AppColors.surface)
                            .frame(height: 2)
                    }
                    
                    VStack(spacing: AppSpacing.xs) {
                        Circle()
                            .fill(index <= currentStep ? AppColors.primary : AppColors.surface)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Text("\(index + 1)")
                                    .textStyle(.labelSmall)
                                    .foregroundStyle(index <= currentStep ? .white : AppColors.textSecondary)
                            )
                        
                        if index < stepTitles.count {
                            Text(stepTitles[index])
                                .textStyle(.labelSmall)
                                .foregroundStyle(index <= currentStep ? AppColors.primary : AppColors.textTertiary)
                        }
                    }
                }
            }
        }
    }
}

struct WarrantyInfoCard: View {
    let warranty: Warranty
    let item: Item
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Image(systemName: warranty.type.icon)
                    .font(.title2)
                    .foregroundStyle(AppColors.primary)
                
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(warranty.provider)
                        .textStyle(.bodyLarge)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Text(warranty.type.displayName)
                        .textStyle(.bodySmall)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                Spacer()
                
                // Show warranty status
                Text(warranty.status.rawValue.capitalized)
                    .textStyle(.labelSmall)
                    .foregroundStyle(warranty.status == .active ? AppColors.success : AppColors.textSecondary)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xxs)
                    .background(warranty.status == .active ? AppColors.successMuted : AppColors.surface)
                    .cornerRadius(AppCornerRadius.small)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack {
                    Text("Item:")
                        .textStyle(.labelSmall)
                        .foregroundStyle(AppColors.textSecondary)
                    Text(item.name)
                        .textStyle(.bodySmall)
                        .foregroundStyle(AppColors.textPrimary)
                }
                
                HStack {
                    Text("Expires:")
                        .textStyle(.labelSmall)
                        .foregroundStyle(AppColors.textSecondary)
                    Text(warranty.endDate, format: .dateTime.month().day().year())
                        .textStyle(.bodySmall)
                        .foregroundStyle(AppColors.textPrimary)
                }
            }
        }
        .appPadding()
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.medium)
    }
}

struct TransferabilityStatusCard: View {
    let transferability: WarrantyTransferability?
    let validationResult: TransferValidationResult?
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: transferability?.isTransferable == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(transferability?.isTransferable == true ? AppColors.success : AppColors.error)
                
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(transferability?.isTransferable == true ? "Transferable" : "Non-Transferable")
                        .textStyle(.headlineSmall)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    if let remaining = transferability?.remainingTransfers {
                        Text("\(remaining) transfers remaining")
                            .textStyle(.bodySmall)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                
                Spacer()
            }
            
            if let issues = validationResult?.issues.filter({ $0.severity == .error }),
               !issues.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    ForEach(issues, id: \.message) { issue in
                        HStack(alignment: .top, spacing: AppSpacing.sm) {
                            Image(systemName: "exclamationmark.circle")
                                .foregroundStyle(AppColors.error)
                            
                            Text(issue.message)
                                .textStyle(.bodySmall)
                                .foregroundStyle(AppColors.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .appPadding()
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.medium)
    }
}

struct TransferConditionsCard: View {
    let conditions: TransferConditions
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Transfer Conditions")
                .textStyle(.labelMedium)
                .foregroundStyle(AppColors.textSecondary)
            
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                if conditions.requiresNotification {
                    ConditionRow(
                        icon: "bell",
                        text: "\(conditions.notificationDays) days advance notice required"
                    )
                }
                
                if conditions.requiresFee, let fee = conditions.feeAmount {
                    ConditionRow(
                        icon: "dollarsign.circle",
                        text: "Transfer fee: \(fee.formatted(.currency(code: "USD")))"
                    )
                }
                
                if conditions.requiresInspection {
                    ConditionRow(
                        icon: "magnifyingglass",
                        text: "Inspection required"
                    )
                }
                
                if conditions.reducedCoverage,
                   let percent = conditions.coverageReductionPercent {
                    ConditionRow(
                        icon: "arrow.down.circle",
                        text: "Coverage reduced by \(percent)% after transfer"
                    )
                }
                
                if let terms = conditions.additionalTerms {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Additional Terms")
                            .textStyle(.labelSmall)
                            .foregroundStyle(AppColors.textSecondary)
                        
                        Text(terms)
                            .textStyle(.bodySmall)
                            .foregroundStyle(AppColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(AppSpacing.sm)
                    .background(AppColors.secondaryBackground)
                    .cornerRadius(AppCornerRadius.small)
                }
            }
        }
        .appPadding()
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.medium)
    }
}

struct ConditionRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(AppColors.primary)
                .frame(width: 20)
            
            Text(text)
                .textStyle(.bodySmall)
                .foregroundStyle(AppColors.textPrimary)
            
            Spacer()
        }
    }
}

struct TransferTypeOption: View {
    let type: TransferType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: type.icon)
                    .foregroundStyle(isSelected ? AppColors.primary : AppColors.textSecondary)
                
                Text(type.displayName)
                    .textStyle(.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
                
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

struct ChecklistItemRow: View {
    let item: TransferChecklistItem
    let isCompleted: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack(alignment: .top) {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isCompleted ? AppColors.success : AppColors.textTertiary)
                    
                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        HStack {
                            Text(item.title)
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
                        
                        if let deadline = item.deadline {
                            HStack {
                                Image(systemName: "calendar")
                                    .font(.caption)
                                Text("Due by \(deadline, format: .dateTime.month().day())")
                                    .textStyle(.labelSmall)
                            }
                            .foregroundStyle(AppColors.warning)
                        }
                    }
                    
                    Spacer()
                }
            }
            .appPadding()
            .background(AppColors.surface)
            .cornerRadius(AppCornerRadius.medium)
        }
    }
}

struct TransferSummaryCard: View {
    let warranty: Warranty
    let item: Item
    let transferType: TransferType
    let transferDate: Date
    let fromOwner: OwnerInfo
    let toOwner: OwnerInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Transfer Summary")
                .textStyle(.labelMedium)
                .foregroundStyle(AppColors.textSecondary)
            
            VStack(spacing: AppSpacing.sm) {
                // Item and warranty
                HStack {
                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        Text("Item")
                            .textStyle(.labelSmall)
                            .foregroundStyle(AppColors.textSecondary)
                        Text(item.name)
                            .textStyle(.bodyMedium)
                            .foregroundStyle(AppColors.textPrimary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: AppSpacing.xxs) {
                        Text("Warranty")
                            .textStyle(.labelSmall)
                            .foregroundStyle(AppColors.textSecondary)
                        Text(warranty.provider)
                            .textStyle(.bodyMedium)
                            .foregroundStyle(AppColors.textPrimary)
                    }
                }
                
                Divider()
                
                // Transfer details
                HStack {
                    Label(transferType.displayName, systemImage: transferType.icon)
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.primary)
                    
                    Spacer()
                    
                    Text(transferDate, format: .dateTime.month().day().year())
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.textPrimary)
                }
                
                Divider()
                
                // From/To
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("From")
                            .textStyle(.labelSmall)
                            .foregroundStyle(AppColors.textSecondary)
                        Text(fromOwner.name)
                            .textStyle(.bodyMedium)
                            .foregroundStyle(AppColors.textPrimary)
                        if let contact = fromOwner.email ?? fromOwner.phone {
                            Text(contact)
                                .textStyle(.bodySmall)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                    
                    Image(systemName: "arrow.right")
                        .foregroundStyle(AppColors.textTertiary)
                        .frame(maxWidth: .infinity)
                    
                    VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                        Text("To")
                            .textStyle(.labelSmall)
                            .foregroundStyle(AppColors.textSecondary)
                        Text(toOwner.name)
                            .textStyle(.bodyMedium)
                            .foregroundStyle(AppColors.textPrimary)
                        if let contact = toOwner.email ?? toOwner.phone {
                            Text(contact)
                                .textStyle(.bodySmall)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                }
            }
            .appPadding()
            .background(AppColors.surface)
            .cornerRadius(AppCornerRadius.medium)
        }
    }
}

struct AdjustedTermsCard: View {
    let originalEndDate: Date
    let adjustedEndDate: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(AppColors.warning)
                Text("Adjusted Warranty Terms")
                    .textStyle(.labelMedium)
                    .foregroundStyle(AppColors.textPrimary)
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack {
                    Text("Original End Date:")
                        .textStyle(.bodySmall)
                        .foregroundStyle(AppColors.textSecondary)
                    Text(originalEndDate, format: .dateTime.month().day().year())
                        .textStyle(.bodySmall)
                        .foregroundStyle(AppColors.textPrimary)
                        .strikethrough()
                }
                
                HStack {
                    Text("New End Date:")
                        .textStyle(.bodySmall)
                        .foregroundStyle(AppColors.textSecondary)
                    Text(adjustedEndDate, format: .dateTime.month().day().year())
                        .textStyle(.bodySmall)
                        .foregroundStyle(AppColors.warning)
                }
                
                let daysReduced = Calendar.current.dateComponents([.day], from: adjustedEndDate, to: originalEndDate).day ?? 0
                Text("Coverage reduced by \(daysReduced) days")
                    .textStyle(.labelSmall)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .appPadding()
        .background(AppColors.warningMuted)
        .cornerRadius(AppCornerRadius.medium)
    }
}

struct WarningsCard: View {
    let issues: [TransferValidationIssue]
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Label("Warnings", systemImage: "exclamationmark.triangle")
                .textStyle(.labelMedium)
                .foregroundStyle(AppColors.warning)
            
            ForEach(issues, id: \.message) { issue in
                HStack(alignment: .top, spacing: AppSpacing.sm) {
                    Circle()
                        .fill(AppColors.warning)
                        .frame(width: 6, height: 6)
                        .padding(.top, 6)
                    
                    Text(issue.message)
                        .textStyle(.bodySmall)
                        .foregroundStyle(AppColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .appPadding()
        .background(AppColors.warningMuted)
        .cornerRadius(AppCornerRadius.medium)
    }
}

struct TransferFeeCard: View {
    let amount: Decimal
    @Binding var isPaid: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "dollarsign.circle")
                    .foregroundStyle(AppColors.primary)
                Text("Transfer Fee Required")
                    .textStyle(.labelMedium)
                    .foregroundStyle(AppColors.textPrimary)
            }
            
            HStack {
                Text("Amount:")
                    .textStyle(.bodyMedium)
                    .foregroundStyle(AppColors.textSecondary)
                
                Spacer()
                
                Text(amount, format: .currency(code: "USD"))
                    .textStyle(.bodyLarge)
                    .foregroundStyle(AppColors.primary)
            }
            
            Toggle("Fee has been paid", isOn: $isPaid)
                .toggleStyle(SwitchToggleStyle(tint: AppColors.primary))
        }
        .appPadding()
        .background(AppColors.primaryMuted)
        .cornerRadius(AppCornerRadius.medium)
    }
}

struct PreviousTransfersCard: View {
    let transfers: [WarrantyTransfer]
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Transfer History")
                .textStyle(.labelMedium)
                .foregroundStyle(AppColors.textSecondary)
            
            ForEach(transfers, id: \.id) { transfer in
                HStack {
                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        Text("\(transfer.fromOwner.name) → \(transfer.toOwner.name)")
                            .textStyle(.bodySmall)
                            .foregroundStyle(AppColors.textPrimary)
                        
                        Text(transfer.transferDate, format: .dateTime.month().day().year())
                            .textStyle(.labelSmall)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: transfer.transferType.icon)
                        .foregroundStyle(AppColors.textTertiary)
                }
                
                if transfer.id != transfers.last?.id {
                    Divider()
                }
            }
        }
        .appPadding()
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.medium)
    }
}