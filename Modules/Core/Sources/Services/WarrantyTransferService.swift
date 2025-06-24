import Foundation

/// Service for managing warranty transfers
public final class WarrantyTransferService {
    
    // MARK: - Transfer Process
    
    /// Initiate a warranty transfer
    public static func initiateTransfer(
        warranty: Warranty,
        item: Item,
        fromOwner: OwnerInfo,
        toOwner: OwnerInfo,
        transferType: TransferType,
        transferDate: Date = Date()
    ) -> WarrantyTransfer {
        WarrantyTransfer(
            warrantyId: warranty.id,
            itemId: item.id,
            transferDate: transferDate,
            transferType: transferType,
            fromOwner: fromOwner,
            toOwner: toOwner,
            transferStatus: .pending,
            originalWarrantyStartDate: warranty.startDate,
            originalWarrantyEndDate: warranty.endDate
        )
    }
    
    /// Get transferability information for a warranty
    public static func getTransferability(
        for warranty: Warranty,
        provider: WarrantyProvider? = nil
    ) -> WarrantyTransferability {
        // Determine transfer conditions based on warranty type and provider
        let conditions = determineTransferConditions(warranty: warranty, provider: provider)
        
        // Check for existing transfers (would come from repository in real implementation)
        let transferHistory: [WarrantyTransfer] = []
        
        // Calculate remaining transfers
        let remainingTransfers: Int? = conditions.requiresNotification ? nil : 1
        
        return WarrantyTransferability(
            warrantyId: warranty.id,
            isTransferable: warranty.type != .insurance, // Insurance warranties typically non-transferable
            transferConditions: conditions,
            remainingTransfers: remainingTransfers,
            transferHistory: transferHistory
        )
    }
    
    // MARK: - Transfer Documentation
    
    /// Generate transfer documentation
    public static func generateTransferDocumentation(
        transfer: WarrantyTransfer,
        warranty: Warranty,
        item: Item
    ) -> TransferDocumentation {
        let documentation = TransferDocumentation(
            transferId: transfer.id,
            documentType: .transferAgreement,
            title: "Warranty Transfer Agreement",
            content: generateTransferAgreement(
                transfer: transfer,
                warranty: warranty,
                item: item
            ),
            requiredSignatures: [
                SignatureRequirement(
                    signatory: .fromOwner,
                    name: transfer.fromOwner.name,
                    signed: false
                ),
                SignatureRequirement(
                    signatory: .toOwner,
                    name: transfer.toOwner.name,
                    signed: false
                )
            ]
        )
        
        return documentation
    }
    
    /// Generate notification letter for warranty provider
    public static func generateProviderNotification(
        transfer: WarrantyTransfer,
        warranty: Warranty,
        item: Item,
        provider: WarrantyProvider
    ) -> String {
        """
        Date: \(formatDate(Date()))
        
        To: \(provider.name)
        Warranty Department
        
        RE: WARRANTY TRANSFER NOTIFICATION
        Policy/Warranty #: \(warranty.registrationNumber ?? warranty.id.uuidString)
        
        Dear \(provider.name),
        
        This letter serves as formal notification of warranty transfer for the following:
        
        ITEM DETAILS:
        - Description: \(item.name)
        - Brand: \(item.brand ?? "N/A")
        - Model: \(item.model ?? "N/A")
        - Serial Number: \(item.serialNumber ?? "N/A")
        
        TRANSFER DETAILS:
        - Transfer Date: \(formatDate(transfer.transferDate))
        - Transfer Type: \(transfer.transferType.displayName)
        
        FROM:
        - Name: \(transfer.fromOwner.name)
        - Contact: \(transfer.fromOwner.email ?? transfer.fromOwner.phone ?? "N/A")
        
        TO:
        - Name: \(transfer.toOwner.name)
        - Contact: \(transfer.toOwner.email ?? transfer.toOwner.phone ?? "N/A")
        - Address: \(transfer.toOwner.address ?? "N/A")
        
        WARRANTY INFORMATION:
        - Original Start Date: \(formatDate(warranty.startDate))
        - Original End Date: \(formatDate(warranty.endDate))
        - Coverage Type: \(warranty.type.displayName)
        
        Please update your records accordingly and send confirmation to the new owner.
        
        Sincerely,
        \(transfer.fromOwner.name)
        """
    }
    
    // MARK: - Transfer Checklist
    
    /// Generate a checklist for warranty transfer
    public static func generateTransferChecklist(
        warranty: Warranty,
        transferability: WarrantyTransferability
    ) -> TransferChecklist {
        var items: [TransferChecklistItem] = []
        let conditions = transferability.transferConditions
        
        // Basic documentation
        items.append(TransferChecklistItem(
            title: "Gather warranty documentation",
            description: "Original warranty certificate, receipts, and registration",
            isRequired: true,
            isCompleted: false
        ))
        
        items.append(TransferChecklistItem(
            title: "Proof of ownership",
            description: "Documentation proving current ownership",
            isRequired: true,
            isCompleted: false
        ))
        
        // Notification requirement
        if conditions.requiresNotification {
            items.append(TransferChecklistItem(
                title: "Notify warranty provider",
                description: "Submit transfer notification at least \(conditions.notificationDays) days before transfer",
                isRequired: true,
                isCompleted: false,
                deadline: Calendar.current.date(
                    byAdding: .day,
                    value: -conditions.notificationDays,
                    to: Date()
                )
            ))
        }
        
        // Fee requirement
        if conditions.requiresFee, let fee = conditions.feeAmount {
            items.append(TransferChecklistItem(
                title: "Pay transfer fee",
                description: "Transfer fee of \(fee) required",
                isRequired: true,
                isCompleted: false
            ))
        }
        
        // Inspection requirement
        if conditions.requiresInspection {
            items.append(TransferChecklistItem(
                title: "Complete inspection",
                description: "Item must pass inspection before transfer",
                isRequired: true,
                isCompleted: false
            ))
        }
        
        // Transfer agreement
        items.append(TransferChecklistItem(
            title: "Complete transfer agreement",
            description: "Both parties must sign the warranty transfer agreement",
            isRequired: true,
            isCompleted: false
        ))
        
        // Update registration
        items.append(TransferChecklistItem(
            title: "Update warranty registration",
            description: "New owner must update registration with their information",
            isRequired: false,
            isCompleted: false
        ))
        
        return TransferChecklist(
            warrantyId: warranty.id,
            items: items,
            estimatedCompletionTime: "2-4 weeks"
        )
    }
    
    // MARK: - Helper Functions
    
    private static func determineTransferConditions(
        warranty: Warranty,
        provider: WarrantyProvider?
    ) -> TransferConditions {
        // Check for provider-specific conditions
        if let provider = provider,
           let specificConditions = getProviderSpecificConditions(provider: provider) {
            return specificConditions
        }
        
        // Fall back to warranty type defaults
        switch warranty.type {
        case .manufacturer:
            return warranty.isExtended ? .extendedWarrantyDefault : .manufacturerDefault
        case .extended, .protection:
            return .extendedWarrantyDefault
        case .service:
            return TransferConditions(
                requiresNotification: true,
                notificationDays: 14,
                requiresFee: true,
                feeAmount: 25
            )
        case .insurance:
            return .nonTransferable
        case .retailer:
            return TransferConditions(
                requiresNotification: true,
                notificationDays: 7,
                requiresFee: false
            )
        }
    }
    
    private static func getProviderSpecificConditions(provider: WarrantyProvider) -> TransferConditions? {
        // Provider-specific transfer conditions
        switch provider.name.lowercased() {
        case "apple", "applecare":
            return TransferConditions(
                requiresNotification: false, // Transfer happens automatically with device
                notificationDays: 0,
                requiresFee: false,
                reducedCoverage: false,
                additionalTerms: "AppleCare+ transfers automatically with device ownership"
            )
            
        case "best buy", "geek squad":
            return TransferConditions(
                requiresNotification: true,
                notificationDays: 30,
                requiresFee: true,
                feeAmount: 49.99,
                reducedCoverage: false,
                additionalTerms: "Protection plan transfers with proof of purchase and transfer fee"
            )
            
        case "squaretrade", "allstate":
            return TransferConditions(
                requiresNotification: true,
                notificationDays: 30,
                requiresFee: false,
                reducedCoverage: false,
                additionalTerms: "Plan transfers one time to new owner with item sale"
            )
            
        default:
            return nil
        }
    }
    
    private static func generateTransferAgreement(
        transfer: WarrantyTransfer,
        warranty: Warranty,
        item: Item
    ) -> String {
        """
        WARRANTY TRANSFER AGREEMENT
        
        This agreement is entered into on \(formatDate(Date())) between:
        
        TRANSFEROR (Current Owner):
        Name: \(transfer.fromOwner.name)
        Contact: \(transfer.fromOwner.email ?? transfer.fromOwner.phone ?? "N/A")
        
        TRANSFEREE (New Owner):
        Name: \(transfer.toOwner.name)
        Contact: \(transfer.toOwner.email ?? transfer.toOwner.phone ?? "N/A")
        
        WHEREAS, Transferor is the current owner of the following item and its associated warranty:
        
        Item: \(item.name) - \(item.brand ?? "") \(item.model ?? "")
        Serial Number: \(item.serialNumber ?? "N/A")
        Warranty Provider: \(warranty.provider)
        Warranty Period: \(formatDate(warranty.startDate)) to \(formatDate(warranty.endDate))
        
        NOW THEREFORE, the parties agree as follows:
        
        1. TRANSFER: Transferor hereby transfers all rights and benefits under the warranty to Transferee.
        
        2. EFFECTIVE DATE: This transfer shall be effective as of \(formatDate(transfer.transferDate)).
        
        3. CONDITION: The item is transferred in its current condition with warranty coverage subject to original terms.
        
        4. OBLIGATIONS: Transferee agrees to comply with all warranty terms and conditions.
        
        5. REPRESENTATIONS: Transferor represents that the warranty is valid and no claims are pending.
        
        SIGNATURES:
        
        _______________________               _______________________
        \(transfer.fromOwner.name)            \(transfer.toOwner.name)
        Transferor                            Transferee
        
        Date: _________________               Date: _________________
        """
    }
    
    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Types

public struct TransferDocumentation {
    public let transferId: UUID
    public let documentType: DocumentType
    public let title: String
    public let content: String
    public var requiredSignatures: [SignatureRequirement]
    
    public enum DocumentType {
        case transferAgreement
        case providerNotification
        case proofOfTransfer
    }
}

public struct SignatureRequirement: Identifiable {
    public let id = UUID()
    public let signatory: Signatory
    public let name: String
    public var signed: Bool
    public var signatureDate: Date?
    
    public enum Signatory {
        case fromOwner
        case toOwner
        case witness
    }
}

public struct TransferChecklist {
    public let warrantyId: UUID
    public let items: [TransferChecklistItem]
    public let estimatedCompletionTime: String
}

public struct TransferChecklistItem: Identifiable {
    public let id = UUID()
    public let title: String
    public let description: String
    public let isRequired: Bool
    public var isCompleted: Bool
    public let deadline: Date?
    
    public init(
        title: String,
        description: String,
        isRequired: Bool,
        isCompleted: Bool,
        deadline: Date? = nil
    ) {
        self.title = title
        self.description = description
        self.isRequired = isRequired
        self.isCompleted = isCompleted
        self.deadline = deadline
    }
}