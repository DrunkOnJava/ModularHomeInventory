import Foundation
import SwiftUI
import Core
import Combine

@MainActor
final class WarrantyTransferViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var transferability: WarrantyTransferability?
    @Published var validationResult: TransferValidationResult?
    @Published var isCheckingEligibility = true
    @Published var transferType: TransferType = .sale
    @Published var transferDate = Date()
    @Published var fromOwnerName = ""
    @Published var fromOwnerEmail = ""
    @Published var fromOwnerPhone = ""
    @Published var toOwnerName = ""
    @Published var toOwnerEmail = ""
    @Published var toOwnerPhone = ""
    @Published var toOwnerAddress = ""
    @Published var transferNotes = ""
    @Published var transferFeePaid = false
    @Published var completedChecklistItems = Set<UUID>()
    @Published var transferChecklist: TransferChecklist?
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var isSubmitting = false
    
    // MARK: - Properties
    let warranty: Warranty
    let item: Item
    private let warrantyRepository: WarrantyRepository
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var canProceedFromStep(_ step: Int) -> Bool {
        switch step {
        case 0: // Eligibility
            return transferability?.isTransferable == true
        case 1: // Transfer details
            return !fromOwnerName.isEmpty && (!fromOwnerEmail.isEmpty || !fromOwnerPhone.isEmpty)
        case 2: // New owner info
            let hasRequiredInfo = !toOwnerName.isEmpty && (!toOwnerEmail.isEmpty || !toOwnerPhone.isEmpty)
            let hasPaidFee = !(transferability?.transferConditions.requiresFee == true) || transferFeePaid
            return hasRequiredInfo && hasPaidFee
        case 3: // Documentation
            let requiredItems = transferChecklist?.items.filter { $0.isRequired } ?? []
            let completedRequired = requiredItems.filter { completedChecklistItems.contains($0.id) }
            return completedRequired.count == requiredItems.count
        case 4: // Review
            return true
        default:
            return false
        }
    }
    
    var canSubmitTransfer: Bool {
        canProceedFromStep(0) &&
        canProceedFromStep(1) &&
        canProceedFromStep(2) &&
        canProceedFromStep(3) &&
        !isSubmitting
    }
    
    // MARK: - Initialization
    init(warranty: Warranty, item: Item, warrantyRepository: WarrantyRepository) {
        self.warranty = warranty
        self.item = item
        self.warrantyRepository = warrantyRepository
        
        Task {
            await checkTransferability()
        }
    }
    
    // MARK: - Methods
    private func checkTransferability() async {
        isCheckingEligibility = true
        
        // Get warranty provider info
        let provider = WarrantyProviderDatabase.providers.first { 
            $0.name.lowercased() == warranty.provider.lowercased() 
        }
        
        // Get transferability
        transferability = WarrantyTransferService.getTransferability(
            for: warranty,
            provider: provider
        )
        
        // Create proposed transfer for validation
        let proposedTransfer = WarrantyTransfer(
            warrantyId: warranty.id,
            itemId: item.id,
            transferDate: transferDate,
            transferType: transferType,
            fromOwner: getFromOwner(),
            toOwner: getToOwner(),
            originalWarrantyStartDate: warranty.startDate,
            originalWarrantyEndDate: warranty.endDate
        )
        
        // Validate transfer
        if let transferability = transferability {
            validationResult = WarrantyTransferValidation.validate(
                warranty: warranty,
                transferability: transferability,
                proposedTransfer: proposedTransfer
            )
            
            // Generate checklist
            transferChecklist = WarrantyTransferService.generateTransferChecklist(
                warranty: warranty,
                transferability: transferability
            )
        }
        
        isCheckingEligibility = false
    }
    
    func getFromOwner() -> OwnerInfo {
        OwnerInfo(
            name: fromOwnerName,
            email: fromOwnerEmail.isEmpty ? nil : fromOwnerEmail,
            phone: fromOwnerPhone.isEmpty ? nil : fromOwnerPhone
        )
    }
    
    func getToOwner() -> OwnerInfo {
        OwnerInfo(
            name: toOwnerName,
            email: toOwnerEmail.isEmpty ? nil : toOwnerEmail,
            phone: toOwnerPhone.isEmpty ? nil : toOwnerPhone,
            address: toOwnerAddress.isEmpty ? nil : toOwnerAddress
        )
    }
    
    func toggleChecklistItem(_ itemId: UUID) {
        if completedChecklistItems.contains(itemId) {
            completedChecklistItems.remove(itemId)
        } else {
            completedChecklistItems.insert(itemId)
        }
    }
    
    func generateTransferAgreement() {
        let transfer = createTransfer()
        let documentation = WarrantyTransferService.generateTransferDocumentation(
            transfer: transfer,
            warranty: warranty,
            item: item
        )
        
        // In a real app, this would save the document and allow sharing
        shareDocument(documentation.content, title: documentation.title)
    }
    
    func generateProviderNotification() {
        guard let provider = WarrantyProviderDatabase.providers.first(where: {
            $0.name.lowercased() == warranty.provider.lowercased()
        }) else { return }
        
        let transfer = createTransfer()
        let notification = WarrantyTransferService.generateProviderNotification(
            transfer: transfer,
            warranty: warranty,
            item: item,
            provider: provider
        )
        
        // In a real app, this would save the document and allow sharing
        shareDocument(notification, title: "Warranty Transfer Notification")
    }
    
    private func createTransfer() -> WarrantyTransfer {
        var transfer = WarrantyTransferService.initiateTransfer(
            warranty: warranty,
            item: item,
            fromOwner: getFromOwner(),
            toOwner: getToOwner(),
            transferType: transferType,
            transferDate: transferDate
        )
        
        // Add fee if applicable
        if let conditions = transferability?.transferConditions,
           conditions.requiresFee,
           let fee = conditions.feeAmount {
            transfer.transferFee = fee
        }
        
        // Add notes
        if !transferNotes.isEmpty {
            transfer.notes = transferNotes
        }
        
        // Add adjusted end date if applicable
        if let adjustedDate = validationResult?.adjustedEndDate {
            transfer.adjustedEndDate = adjustedDate
        }
        
        return transfer
    }
    
    func submitTransfer() async {
        isSubmitting = true
        
        do {
            let transfer = createTransfer()
            
            // In a real app, this would:
            // 1. Save the transfer record
            // 2. Update the warranty with new owner info
            // 3. Send notifications
            // 4. Generate and save documents
            
            // For now, we'll just update the warranty status
            var updatedWarranty = warranty
            updatedWarranty.notes = "Transferred to \(toOwnerName) on \(transferDate.formatted())"
            updatedWarranty.updatedAt = Date()
            
            try await warrantyRepository.save(updatedWarranty)
            
            isSubmitting = false
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            isSubmitting = false
        }
    }
    
    private func shareDocument(_ content: String, title: String) {
        // In a real app, this would create a PDF and show share sheet
        UIPasteboard.general.string = content
        
        // Show a temporary success message
        errorMessage = "\(title) copied to clipboard"
        showError = true
    }
}

// MARK: - Helper Views

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