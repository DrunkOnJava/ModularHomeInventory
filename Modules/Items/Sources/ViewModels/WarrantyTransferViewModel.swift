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
    private let warrantyRepository: any WarrantyRepository
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    func canProceedFromStep(_ step: Int) -> Bool {
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
    init(warranty: Warranty, item: Item, warrantyRepository: any WarrantyRepository) {
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
        _ = WarrantyProviderDatabase.providers.first { 
            $0.name.lowercased() == warranty.provider.lowercased() 
        }
        
        // Get transferability
        transferability = WarrantyTransferService.getTransferability(
            for: warranty,
            provider: nil // Provider info not needed for basic transferability
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
        // Generate provider notification
        let notification = """
        To: \(warranty.provider)
        Re: Warranty Transfer Notification
        
        Policy Number: \(warranty.registrationNumber ?? "N/A")
        Item: \(item.name)
        Transfer Date: \(transferDate.formatted())
        
        This is to notify you of a warranty transfer from \(fromOwnerName) to \(toOwnerName).
        
        Please update your records accordingly.
        """
        
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
            // Transfer fee would be set during creation
            // transfer.transferFee = fee
        }
        
        // Add notes
        if !transferNotes.isEmpty {
            // Notes would be set during creation
            // transfer.notes = transferNotes
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