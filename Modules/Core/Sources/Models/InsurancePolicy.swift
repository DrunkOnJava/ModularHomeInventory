import Foundation

/// Represents an insurance policy covering one or more items
public struct InsurancePolicy: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public var policyNumber: String
    public var provider: String
    public var type: InsuranceType
    public var itemIds: Set<UUID> // Items covered by this policy
    public var coverageAmount: Decimal
    public var deductible: Decimal
    public var premium: PremiumDetails
    public var startDate: Date
    public var endDate: Date
    public var isActive: Bool
    public var coverageDetails: String
    public var exclusions: String?
    public var contactInfo: InsuranceContact
    public var documentIds: [UUID]
    public var claims: [InsuranceClaim]
    public var notes: String?
    public let createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        policyNumber: String,
        provider: String,
        type: InsuranceType,
        itemIds: Set<UUID> = [],
        coverageAmount: Decimal,
        deductible: Decimal,
        premium: PremiumDetails,
        startDate: Date,
        endDate: Date,
        isActive: Bool = true,
        coverageDetails: String,
        exclusions: String? = nil,
        contactInfo: InsuranceContact,
        documentIds: [UUID] = [],
        claims: [InsuranceClaim] = [],
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.policyNumber = policyNumber
        self.provider = provider
        self.type = type
        self.itemIds = itemIds
        self.coverageAmount = coverageAmount
        self.deductible = deductible
        self.premium = premium
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
        self.coverageDetails = coverageDetails
        self.exclusions = exclusions
        self.contactInfo = contactInfo
        self.documentIds = documentIds
        self.claims = claims
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Supporting Types

public enum InsuranceType: String, Codable, CaseIterable, Hashable, Sendable {
    case homeowners = "homeowners"
    case renters = "renters"
    case valuable = "valuable_items"
    case electronics = "electronics"
    case jewelry = "jewelry"
    case collectibles = "collectibles"
    case business = "business"
    case auto = "auto"
    case umbrella = "umbrella"
    case other = "other"
    
    public var displayName: String {
        switch self {
        case .homeowners: return "Homeowners"
        case .renters: return "Renters"
        case .valuable: return "Valuable Items"
        case .electronics: return "Electronics"
        case .jewelry: return "Jewelry"
        case .collectibles: return "Collectibles"
        case .business: return "Business Property"
        case .auto: return "Auto"
        case .umbrella: return "Umbrella"
        case .other: return "Other"
        }
    }
    
    public var icon: String {
        switch self {
        case .homeowners: return "house"
        case .renters: return "building"
        case .valuable: return "star"
        case .electronics: return "laptopcomputer"
        case .jewelry: return "sparkle"
        case .collectibles: return "archivebox"
        case .business: return "briefcase"
        case .auto: return "car"
        case .umbrella: return "umbrella"
        case .other: return "doc.text"
        }
    }
}

public struct PremiumDetails: Codable, Hashable, Sendable {
    public var amount: Decimal
    public var frequency: PremiumFrequency
    public var nextDueDate: Date?
    public var autoRenewal: Bool
    
    public var annualAmount: Decimal {
        switch frequency {
        case .monthly: return amount * 12
        case .quarterly: return amount * 4
        case .semiAnnual: return amount * 2
        case .annual: return amount
        }
    }
    
    public init(
        amount: Decimal,
        frequency: PremiumFrequency,
        nextDueDate: Date? = nil,
        autoRenewal: Bool = true
    ) {
        self.amount = amount
        self.frequency = frequency
        self.nextDueDate = nextDueDate
        self.autoRenewal = autoRenewal
    }
}

public enum PremiumFrequency: String, Codable, CaseIterable, Hashable, Sendable {
    case monthly = "monthly"
    case quarterly = "quarterly"
    case semiAnnual = "semi_annual"
    case annual = "annual"
    
    public var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .semiAnnual: return "Semi-Annual"
        case .annual: return "Annual"
        }
    }
}

public struct InsuranceContact: Codable, Hashable, Sendable {
    public var agentName: String?
    public var agentPhone: String?
    public var agentEmail: String?
    public var claimsPhone: String
    public var claimsEmail: String?
    public var website: String?
    public var policyHolderNumber: String?
    
    public init(
        agentName: String? = nil,
        agentPhone: String? = nil,
        agentEmail: String? = nil,
        claimsPhone: String,
        claimsEmail: String? = nil,
        website: String? = nil,
        policyHolderNumber: String? = nil
    ) {
        self.agentName = agentName
        self.agentPhone = agentPhone
        self.agentEmail = agentEmail
        self.claimsPhone = claimsPhone
        self.claimsEmail = claimsEmail
        self.website = website
        self.policyHolderNumber = policyHolderNumber
    }
}

public struct InsuranceClaim: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public var claimNumber: String
    public var dateOfLoss: Date
    public var dateReported: Date
    public var status: ClaimStatus
    public var itemIds: Set<UUID> // Items involved in claim
    public var description: String
    public var claimAmount: Decimal
    public var approvedAmount: Decimal?
    public var paidAmount: Decimal?
    public var deductibleApplied: Decimal?
    public var adjustorName: String?
    public var adjustorPhone: String?
    public var notes: String?
    public var documentIds: [UUID]
    public let createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        claimNumber: String,
        dateOfLoss: Date,
        dateReported: Date = Date(),
        status: ClaimStatus = .filed,
        itemIds: Set<UUID> = [],
        description: String,
        claimAmount: Decimal,
        approvedAmount: Decimal? = nil,
        paidAmount: Decimal? = nil,
        deductibleApplied: Decimal? = nil,
        adjustorName: String? = nil,
        adjustorPhone: String? = nil,
        notes: String? = nil,
        documentIds: [UUID] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.claimNumber = claimNumber
        self.dateOfLoss = dateOfLoss
        self.dateReported = dateReported
        self.status = status
        self.itemIds = itemIds
        self.description = description
        self.claimAmount = claimAmount
        self.approvedAmount = approvedAmount
        self.paidAmount = paidAmount
        self.deductibleApplied = deductibleApplied
        self.adjustorName = adjustorName
        self.adjustorPhone = adjustorPhone
        self.notes = notes
        self.documentIds = documentIds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public enum ClaimStatus: String, Codable, CaseIterable, Hashable, Sendable {
    case filed = "filed"
    case underReview = "under_review"
    case approved = "approved"
    case denied = "denied"
    case paid = "paid"
    case closed = "closed"
    case appealing = "appealing"
    
    public var displayName: String {
        switch self {
        case .filed: return "Filed"
        case .underReview: return "Under Review"
        case .approved: return "Approved"
        case .denied: return "Denied"
        case .paid: return "Paid"
        case .closed: return "Closed"
        case .appealing: return "Appealing"
        }
    }
    
    public var icon: String {
        switch self {
        case .filed: return "doc.text"
        case .underReview: return "magnifyingglass"
        case .approved: return "checkmark.circle"
        case .denied: return "xmark.circle"
        case .paid: return "dollarsign.circle"
        case .closed: return "lock"
        case .appealing: return "arrow.triangle.2.circlepath"
        }
    }
    
    public var color: String {
        switch self {
        case .filed: return "blue"
        case .underReview: return "orange"
        case .approved: return "green"
        case .denied: return "red"
        case .paid: return "green"
        case .closed: return "gray"
        case .appealing: return "purple"
        }
    }
}

// MARK: - Computed Properties
extension InsurancePolicy {
    public var status: PolicyStatus {
        let now = Date()
        if !isActive {
            return .inactive
        } else if now < startDate {
            return .pending
        } else if now > endDate {
            return .expired
        } else if let nextDue = premium.nextDueDate,
                  nextDue < now.addingTimeInterval(30 * 24 * 60 * 60) {
            return .renewalDue
        } else {
            return .active
        }
    }
    
    public var daysRemaining: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: endDate)
        return max(0, components.day ?? 0)
    }
    
    public var totalClaimsAmount: Decimal {
        claims.reduce(0) { $0 + $1.claimAmount }
    }
    
    public var totalPaidAmount: Decimal {
        claims.reduce(0) { $0 + ($1.paidAmount ?? 0) }
    }
}

public enum PolicyStatus: String, Hashable {
    case pending = "pending"
    case active = "active"
    case renewalDue = "renewal_due"
    case expired = "expired"
    case inactive = "inactive"
    
    public var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .active: return "Active"
        case .renewalDue: return "Renewal Due"
        case .expired: return "Expired"
        case .inactive: return "Inactive"
        }
    }
    
    public var color: String {
        switch self {
        case .pending: return "orange"
        case .active: return "green"
        case .renewalDue: return "yellow"
        case .expired: return "red"
        case .inactive: return "gray"
        }
    }
}

// MARK: - Preview Data
extension InsurancePolicy {
    public static var preview: InsurancePolicy {
        InsurancePolicy(
            policyNumber: "HO-123456789",
            provider: "State Farm",
            type: .homeowners,
            itemIds: [UUID(), UUID(), UUID()],
            coverageAmount: 500000,
            deductible: 1000,
            premium: PremiumDetails(
                amount: 125,
                frequency: .monthly,
                nextDueDate: Date().addingTimeInterval(15 * 24 * 60 * 60)
            ),
            startDate: Date().addingTimeInterval(-365 * 24 * 60 * 60),
            endDate: Date().addingTimeInterval(365 * 24 * 60 * 60),
            coverageDetails: "Full replacement value coverage for personal property",
            contactInfo: InsuranceContact(
                agentName: "Jane Smith",
                agentPhone: "(555) 123-4567",
                agentEmail: "jane.smith@statefarm.com",
                claimsPhone: "1-800-STATE-FARM"
            )
        )
    }
    
    public static var previews: [InsurancePolicy] {
        [
            preview,
            InsurancePolicy(
                policyNumber: "VPP-987654321",
                provider: "Chubb",
                type: .valuable,
                itemIds: [UUID()],
                coverageAmount: 50000,
                deductible: 500,
                premium: PremiumDetails(
                    amount: 600,
                    frequency: .annual
                ),
                startDate: Date().addingTimeInterval(-180 * 24 * 60 * 60),
                endDate: Date().addingTimeInterval(185 * 24 * 60 * 60),
                coverageDetails: "Valuable personal property rider",
                contactInfo: InsuranceContact(
                    claimsPhone: "1-800-CHUBB"
                )
            )
        ]
    }
}