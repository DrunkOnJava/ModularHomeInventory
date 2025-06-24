import Foundation

/// Represents a warranty transfer record
public struct WarrantyTransfer: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let warrantyId: UUID
    public let itemId: UUID
    public let transferDate: Date
    public let transferType: TransferType
    public let fromOwner: OwnerInfo
    public let toOwner: OwnerInfo
    public var transferStatus: TransferStatus
    public let originalWarrantyStartDate: Date
    public let originalWarrantyEndDate: Date
    public var adjustedEndDate: Date? // Some warranties reduce coverage after transfer
    public let transferFee: Decimal?
    public let transferConditions: String?
    public let documentIds: [UUID]
    public let notes: String?
    public let createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        warrantyId: UUID,
        itemId: UUID,
        transferDate: Date = Date(),
        transferType: TransferType,
        fromOwner: OwnerInfo,
        toOwner: OwnerInfo,
        transferStatus: TransferStatus = .pending,
        originalWarrantyStartDate: Date,
        originalWarrantyEndDate: Date,
        adjustedEndDate: Date? = nil,
        transferFee: Decimal? = nil,
        transferConditions: String? = nil,
        documentIds: [UUID] = [],
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.warrantyId = warrantyId
        self.itemId = itemId
        self.transferDate = transferDate
        self.transferType = transferType
        self.fromOwner = fromOwner
        self.toOwner = toOwner
        self.transferStatus = transferStatus
        self.originalWarrantyStartDate = originalWarrantyStartDate
        self.originalWarrantyEndDate = originalWarrantyEndDate
        self.adjustedEndDate = adjustedEndDate
        self.transferFee = transferFee
        self.transferConditions = transferConditions
        self.documentIds = documentIds
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Supporting Types

public enum TransferType: String, Codable, CaseIterable, Hashable, Sendable {
    case sale = "sale"
    case gift = "gift"
    case inheritance = "inheritance"
    case trade = "trade"
    case other = "other"
    
    public var displayName: String {
        switch self {
        case .sale: return "Sale"
        case .gift: return "Gift"
        case .inheritance: return "Inheritance"
        case .trade: return "Trade"
        case .other: return "Other"
        }
    }
    
    public var icon: String {
        switch self {
        case .sale: return "dollarsign.circle"
        case .gift: return "gift"
        case .inheritance: return "person.2"
        case .trade: return "arrow.left.arrow.right"
        case .other: return "ellipsis.circle"
        }
    }
}

public enum TransferStatus: String, Codable, CaseIterable, Hashable, Sendable {
    case pending = "pending"
    case inProgress = "in_progress"
    case completed = "completed"
    case rejected = "rejected"
    case cancelled = "cancelled"
    
    public var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .rejected: return "Rejected"
        case .cancelled: return "Cancelled"
        }
    }
    
    public var icon: String {
        switch self {
        case .pending: return "clock"
        case .inProgress: return "arrow.triangle.2.circlepath"
        case .completed: return "checkmark.circle"
        case .rejected: return "xmark.circle"
        case .cancelled: return "minus.circle"
        }
    }
    
    public var color: String {
        switch self {
        case .pending: return "orange"
        case .inProgress: return "blue"
        case .completed: return "green"
        case .rejected: return "red"
        case .cancelled: return "gray"
        }
    }
}

public struct OwnerInfo: Codable, Hashable, Sendable {
    public let name: String
    public let email: String?
    public let phone: String?
    public let address: String?
    public let proofOfOwnership: [UUID] // Document IDs
    
    public init(
        name: String,
        email: String? = nil,
        phone: String? = nil,
        address: String? = nil,
        proofOfOwnership: [UUID] = []
    ) {
        self.name = name
        self.email = email
        self.phone = phone
        self.address = address
        self.proofOfOwnership = proofOfOwnership
    }
}

// MARK: - Warranty Transferability

public struct WarrantyTransferability: Codable, Hashable, Sendable {
    public let warrantyId: UUID
    public let isTransferable: Bool
    public let transferConditions: TransferConditions
    public let remainingTransfers: Int? // nil means unlimited
    public let transferHistory: [WarrantyTransfer]
    
    public init(
        warrantyId: UUID,
        isTransferable: Bool,
        transferConditions: TransferConditions,
        remainingTransfers: Int? = nil,
        transferHistory: [WarrantyTransfer] = []
    ) {
        self.warrantyId = warrantyId
        self.isTransferable = isTransferable
        self.transferConditions = transferConditions
        self.remainingTransfers = remainingTransfers
        self.transferHistory = transferHistory
    }
}

public struct TransferConditions: Codable, Hashable, Sendable {
    public let requiresNotification: Bool
    public let notificationDays: Int // Days before transfer to notify
    public let requiresFee: Bool
    public let feeAmount: Decimal?
    public let requiresInspection: Bool
    public let reducedCoverage: Bool
    public let coverageReductionPercent: Int? // Percentage reduction
    public let excludedAfterTransfer: [String] // List of excluded coverage items
    public let additionalTerms: String?
    
    public init(
        requiresNotification: Bool = true,
        notificationDays: Int = 30,
        requiresFee: Bool = false,
        feeAmount: Decimal? = nil,
        requiresInspection: Bool = false,
        reducedCoverage: Bool = false,
        coverageReductionPercent: Int? = nil,
        excludedAfterTransfer: [String] = [],
        additionalTerms: String? = nil
    ) {
        self.requiresNotification = requiresNotification
        self.notificationDays = notificationDays
        self.requiresFee = requiresFee
        self.feeAmount = feeAmount
        self.requiresInspection = requiresInspection
        self.reducedCoverage = reducedCoverage
        self.coverageReductionPercent = coverageReductionPercent
        self.excludedAfterTransfer = excludedAfterTransfer
        self.additionalTerms = additionalTerms
    }
}

// MARK: - Common Transfer Conditions by Warranty Type

extension TransferConditions {
    public static let manufacturerDefault = TransferConditions(
        requiresNotification: true,
        notificationDays: 30,
        requiresFee: false,
        reducedCoverage: true,
        coverageReductionPercent: 50,
        additionalTerms: "Warranty coverage limited to manufacturing defects only after transfer"
    )
    
    public static let extendedWarrantyDefault = TransferConditions(
        requiresNotification: true,
        notificationDays: 30,
        requiresFee: true,
        feeAmount: 50,
        requiresInspection: false,
        reducedCoverage: false,
        additionalTerms: "Transfer fee required. Coverage continues as originally purchased."
    )
    
    public static let homeWarrantyDefault = TransferConditions(
        requiresNotification: true,
        notificationDays: 7,
        requiresFee: true,
        feeAmount: 75,
        requiresInspection: true,
        reducedCoverage: false,
        additionalTerms: "Property inspection may be required. Coverage transfers with property sale."
    )
    
    public static let nonTransferable = TransferConditions(
        requiresNotification: false,
        notificationDays: 0,
        requiresFee: false,
        reducedCoverage: true,
        coverageReductionPercent: 100,
        additionalTerms: "This warranty is non-transferable and void upon change of ownership"
    )
}

// MARK: - Warranty Transfer Validation

public struct WarrantyTransferValidation {
    public static func validate(
        warranty: Warranty,
        transferability: WarrantyTransferability,
        proposedTransfer: WarrantyTransfer
    ) -> TransferValidationResult {
        var issues: [TransferValidationIssue] = []
        
        // Check if warranty is transferable
        if !transferability.isTransferable {
            issues.append(TransferValidationIssue(
                severity: .error,
                code: .nonTransferable,
                message: "This warranty is non-transferable"
            ))
        }
        
        // Check if warranty is still active
        if warranty.status == .expired {
            issues.append(TransferValidationIssue(
                severity: .error,
                code: .expired,
                message: "Cannot transfer an expired warranty"
            ))
        }
        
        // Check remaining transfers
        if let remaining = transferability.remainingTransfers, remaining <= 0 {
            issues.append(TransferValidationIssue(
                severity: .error,
                code: .transferLimitReached,
                message: "Maximum number of transfers reached"
            ))
        }
        
        // Check notification requirement
        let conditions = transferability.transferConditions
        if conditions.requiresNotification {
            let daysUntilTransfer = Calendar.current.dateComponents(
                [.day],
                from: Date(),
                to: proposedTransfer.transferDate
            ).day ?? 0
            
            if daysUntilTransfer < conditions.notificationDays {
                issues.append(TransferValidationIssue(
                    severity: .warning,
                    code: .insufficientNotice,
                    message: "Transfer requires \(conditions.notificationDays) days notice"
                ))
            }
        }
        
        // Check fee requirement
        if conditions.requiresFee && proposedTransfer.transferFee == nil {
            issues.append(TransferValidationIssue(
                severity: .error,
                code: .feeRequired,
                message: "Transfer fee of \(conditions.feeAmount ?? 0) required"
            ))
        }
        
        return TransferValidationResult(
            isValid: !issues.contains { $0.severity == .error },
            issues: issues,
            adjustedEndDate: calculateAdjustedEndDate(
                original: warranty.endDate,
                conditions: conditions
            )
        )
    }
    
    private static func calculateAdjustedEndDate(
        original: Date,
        conditions: TransferConditions
    ) -> Date? {
        guard conditions.reducedCoverage,
              let reductionPercent = conditions.coverageReductionPercent else {
            return nil
        }
        
        // Calculate reduced coverage period
        let totalDays = Calendar.current.dateComponents(
            [.day],
            from: Date(),
            to: original
        ).day ?? 0
        
        let reducedDays = Int(Double(totalDays) * (1.0 - Double(reductionPercent) / 100.0))
        
        return Calendar.current.date(
            byAdding: .day,
            value: reducedDays,
            to: Date()
        )
    }
}

public struct TransferValidationResult {
    public let isValid: Bool
    public let issues: [TransferValidationIssue]
    public let adjustedEndDate: Date?
}

public struct TransferValidationIssue {
    public let severity: Severity
    public let code: IssueCode
    public let message: String
    
    public enum Severity {
        case error
        case warning
        case info
    }
    
    public enum IssueCode {
        case nonTransferable
        case expired
        case transferLimitReached
        case insufficientNotice
        case feeRequired
        case inspectionRequired
    }
}