import Foundation

/// Service for assisting users with insurance and warranty claims
public final class ClaimAssistanceService {
    
    // MARK: - Template Management
    
    /// Get appropriate claim template based on claim type
    public static func getTemplate(for type: ClaimType) -> ClaimTemplate? {
        ClaimTemplate.defaultTemplates.first { $0.type == type }
    }
    
    /// Get all available templates
    public static func getAllTemplates() -> [ClaimTemplate] {
        ClaimTemplate.defaultTemplates
    }
    
    // MARK: - Claim Document Generation
    
    /// Generate a claim summary document
    public static func generateClaimSummary(
        claim: InsuranceClaim,
        policy: InsurancePolicy,
        items: [Item],
        incidents: [IncidentDetails]
    ) -> ClaimSummaryDocument {
        let affectedItems = items.filter { claim.itemIds.contains($0.id) }
        let totalValue = affectedItems.reduce(Decimal.zero) { sum, item in
            sum + (item.value ?? 0) * Decimal(item.quantity)
        }
        
        return ClaimSummaryDocument(
            claimNumber: claim.claimNumber,
            policyNumber: policy.policyNumber,
            dateOfLoss: claim.dateOfLoss,
            dateReported: claim.dateReported,
            claimAmount: claim.claimAmount,
            description: claim.description,
            affectedItems: affectedItems.map { item in
                ClaimItemDetail(
                    name: item.name,
                    brand: item.brand,
                    model: item.model,
                    serialNumber: item.serialNumber,
                    purchaseDate: item.purchaseDate,
                    purchasePrice: item.purchasePrice ?? 0,
                    currentValue: item.value ?? 0,
                    quantity: item.quantity,
                    condition: item.condition.rawValue,
                    description: item.notes ?? ""
                )
            },
            incidents: incidents,
            totalValue: totalValue,
            deductible: policy.deductible,
            estimatedPayout: max(0, claim.claimAmount - policy.deductible)
        )
    }
    
    /// Generate email content for claim submission
    public static func generateClaimEmail(
        template: ClaimTemplate,
        claim: InsuranceClaim,
        policy: InsurancePolicy,
        items: [Item],
        personalInfo: PersonalInfo
    ) -> String {
        guard let emailTemplate = template.emailTemplate else {
            return generateDefaultClaimEmail(claim: claim, policy: policy, items: items, personalInfo: personalInfo)
        }
        
        let affectedItems = items.filter { claim.itemIds.contains($0.id) }
        let itemList = affectedItems.map { "- \($0.name) (\($0.brand ?? "Unknown")): $\($0.value ?? 0)" }.joined(separator: "\n")
        
        return emailTemplate
            .replacingOccurrences(of: "[POLICY_NUMBER]", with: policy.policyNumber)
            .replacingOccurrences(of: "[DATE]", with: formatDate(claim.dateOfLoss))
            .replacingOccurrences(of: "[LOCATION]", with: personalInfo.address ?? "N/A")
            .replacingOccurrences(of: "[REPORT_NUMBER]", with: claim.claimNumber)
            .replacingOccurrences(of: "[ITEM_LIST]", with: itemList)
            .replacingOccurrences(of: "[AMOUNT]", with: "\(claim.claimAmount)")
            .replacingOccurrences(of: "[YOUR_NAME]", with: personalInfo.name)
            .replacingOccurrences(of: "[CONTACT_INFO]", with: formatContactInfo(personalInfo))
    }
    
    // MARK: - Claim Validation
    
    /// Validate if a claim can be filed
    public static func validateClaim(
        policy: InsurancePolicy,
        dateOfLoss: Date,
        claimType: ClaimType
    ) -> ClaimValidationResult {
        var issues: [ValidationIssue] = []
        
        // Check if policy was active at time of loss
        if dateOfLoss < policy.startDate || dateOfLoss > policy.endDate {
            issues.append(ValidationIssue(
                severity: .error,
                message: "Policy was not active on the date of loss",
                suggestion: "The incident must occur during the policy coverage period"
            ))
        }
        
        // Check if policy is currently active
        if policy.status == .expired {
            issues.append(ValidationIssue(
                severity: .warning,
                message: "Policy is expired",
                suggestion: "You may still be able to file if the loss occurred during coverage period"
            ))
        }
        
        // Check claim reporting timeframe (assuming 30 days)
        let daysSinceLoss = Calendar.current.dateComponents([.day], from: dateOfLoss, to: Date()).day ?? 0
        if daysSinceLoss > 30 {
            issues.append(ValidationIssue(
                severity: .warning,
                message: "Loss occurred more than 30 days ago",
                suggestion: "Check your policy for claim reporting deadlines"
            ))
        }
        
        return ClaimValidationResult(
            isValid: !issues.contains { $0.severity == .error },
            issues: issues
        )
    }
    
    // MARK: - Document Checklist
    
    /// Generate a personalized document checklist for a claim
    public static func generateDocumentChecklist(
        template: ClaimTemplate,
        policy: InsurancePolicy,
        items: [Item]
    ) -> DocumentChecklist {
        var checklist: [DocumentChecklistItem] = []
        
        // Add template required documents
        for doc in template.requiredDocuments {
            checklist.append(DocumentChecklistItem(
                name: doc.name,
                description: doc.description,
                isRequired: !doc.isOptional,
                tips: doc.tips,
                isCollected: false
            ))
        }
        
        // Add policy-specific documents
        checklist.append(DocumentChecklistItem(
            name: "Insurance Policy",
            description: "Copy of your \(policy.type.displayName) policy from \(policy.provider)",
            isRequired: true,
            tips: "Include all pages and any riders or amendments",
            isCollected: false
        ))
        
        // Add item-specific documents
        if !items.isEmpty {
            checklist.append(DocumentChecklistItem(
                name: "Item Documentation",
                description: "Receipts, photos, and documentation for affected items",
                isRequired: true,
                tips: "Include purchase receipts, warranty info, and recent photos",
                isCollected: false
            ))
        }
        
        return DocumentChecklist(
            claimType: template.type,
            items: checklist,
            additionalTips: template.tips
        )
    }
    
    // MARK: - Helper Functions
    
    private static func generateDefaultClaimEmail(
        claim: InsuranceClaim,
        policy: InsurancePolicy,
        items: [Item],
        personalInfo: PersonalInfo
    ) -> String {
        let affectedItems = items.filter { claim.itemIds.contains($0.id) }
        let itemList = affectedItems.map { "- \($0.name): $\($0.value ?? 0)" }.joined(separator: "\n")
        
        return """
        Subject: Insurance Claim - Policy #\(policy.policyNumber)
        
        Dear \(policy.provider) Claims Department,
        
        I am writing to file a claim under my \(policy.type.displayName) policy.
        
        Policy Information:
        - Policy Number: \(policy.policyNumber)
        - Policy Holder: \(personalInfo.name)
        
        Claim Details:
        - Date of Loss: \(formatDate(claim.dateOfLoss))
        - Claim Amount: $\(claim.claimAmount)
        - Description: \(claim.description)
        
        Affected Items:
        \(itemList)
        
        I have attached all required documentation. Please confirm receipt of this claim and advise on next steps.
        
        Sincerely,
        \(personalInfo.name)
        \(formatContactInfo(personalInfo))
        """
    }
    
    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private static func formatContactInfo(_ info: PersonalInfo) -> String {
        var contact = [String]()
        if let phone = info.phone { contact.append("Phone: \(phone)") }
        if let email = info.email { contact.append("Email: \(email)") }
        if let address = info.address { contact.append("Address: \(address)") }
        return contact.joined(separator: "\n")
    }
}

// MARK: - Supporting Types

public struct ClaimSummaryDocument {
    public let claimNumber: String
    public let policyNumber: String
    public let dateOfLoss: Date
    public let dateReported: Date
    public let claimAmount: Decimal
    public let description: String
    public let affectedItems: [ClaimItemDetail]
    public let incidents: [IncidentDetails]
    public let totalValue: Decimal
    public let deductible: Decimal
    public let estimatedPayout: Decimal
}

public struct ClaimItemDetail {
    public let name: String
    public let brand: String?
    public let model: String?
    public let serialNumber: String?
    public let purchaseDate: Date?
    public let purchasePrice: Decimal
    public let currentValue: Decimal
    public let quantity: Int
    public let condition: String
    public let description: String
}

public struct IncidentDetails {
    public let type: String
    public let description: String
    public let location: String?
    public let witnesses: [String]
    public let policeReportNumber: String?
    public let photos: [UUID]
}

public struct PersonalInfo {
    public let name: String
    public let phone: String?
    public let email: String?
    public let address: String?
}

public struct ClaimValidationResult {
    public let isValid: Bool
    public let issues: [ValidationIssue]
}

public struct ValidationIssue {
    public let severity: Severity
    public let message: String
    public let suggestion: String?
    
    public enum Severity {
        case error
        case warning
        case info
    }
}

public struct DocumentChecklist {
    public let claimType: ClaimType
    public let items: [DocumentChecklistItem]
    public let additionalTips: [String]
}

public struct DocumentChecklistItem: Identifiable {
    public let id = UUID()
    public let name: String
    public let description: String
    public let isRequired: Bool
    public let tips: String?
    public var isCollected: Bool
}