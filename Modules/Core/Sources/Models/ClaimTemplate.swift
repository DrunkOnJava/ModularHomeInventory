import Foundation

/// Templates for different types of insurance and warranty claims
public struct ClaimTemplate: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let type: ClaimType
    public let title: String
    public let description: String
    public let requiredDocuments: [RequiredDocument]
    public let steps: [ClaimStep]
    public let tips: [String]
    public let estimatedTimeframe: String
    public let contactTemplate: String?
    public let emailTemplate: String?
    
    public init(
        id: UUID = UUID(),
        type: ClaimType,
        title: String,
        description: String,
        requiredDocuments: [RequiredDocument],
        steps: [ClaimStep],
        tips: [String] = [],
        estimatedTimeframe: String,
        contactTemplate: String? = nil,
        emailTemplate: String? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.requiredDocuments = requiredDocuments
        self.steps = steps
        self.tips = tips
        self.estimatedTimeframe = estimatedTimeframe
        self.contactTemplate = contactTemplate
        self.emailTemplate = emailTemplate
    }
}

// MARK: - Supporting Types

public enum ClaimType: String, Codable, CaseIterable, Hashable, Sendable {
    case theft = "theft"
    case damage = "damage"
    case loss = "loss"
    case malfunction = "malfunction"
    case naturalDisaster = "natural_disaster"
    case warranty = "warranty"
    case accidental = "accidental"
    case fire = "fire"
    case water = "water"
    
    public var displayName: String {
        switch self {
        case .theft: return "Theft"
        case .damage: return "Damage"
        case .loss: return "Loss"
        case .malfunction: return "Malfunction"
        case .naturalDisaster: return "Natural Disaster"
        case .warranty: return "Warranty Claim"
        case .accidental: return "Accidental Damage"
        case .fire: return "Fire Damage"
        case .water: return "Water Damage"
        }
    }
    
    public var icon: String {
        switch self {
        case .theft: return "lock.open"
        case .damage: return "exclamationmark.triangle"
        case .loss: return "questionmark.circle"
        case .malfunction: return "wrench.and.screwdriver"
        case .naturalDisaster: return "tornado"
        case .warranty: return "shield"
        case .accidental: return "hand.raised"
        case .fire: return "flame"
        case .water: return "drop.triangle"
        }
    }
}

public struct RequiredDocument: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let name: String
    public let description: String
    public let isOptional: Bool
    public let tips: String?
    
    public init(
        id: UUID = UUID(),
        name: String,
        description: String,
        isOptional: Bool = false,
        tips: String? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.isOptional = isOptional
        self.tips = tips
    }
}

public struct ClaimStep: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let order: Int
    public let title: String
    public let description: String
    public let actionItems: [String]
    public let warningMessage: String?
    public let estimatedTime: String?
    
    public init(
        id: UUID = UUID(),
        order: Int,
        title: String,
        description: String,
        actionItems: [String] = [],
        warningMessage: String? = nil,
        estimatedTime: String? = nil
    ) {
        self.id = id
        self.order = order
        self.title = title
        self.description = description
        self.actionItems = actionItems
        self.warningMessage = warningMessage
        self.estimatedTime = estimatedTime
    }
}

// MARK: - Claim Progress Tracking

public struct ClaimProgress: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let claimId: UUID
    public let templateId: UUID
    public var currentStep: Int
    public var completedSteps: Set<Int>
    public var collectedDocuments: [UUID]
    public var notes: [ClaimNote]
    public var startedAt: Date
    public var lastUpdated: Date
    public var completedAt: Date?
    
    public init(
        id: UUID = UUID(),
        claimId: UUID,
        templateId: UUID,
        currentStep: Int = 0,
        completedSteps: Set<Int> = [],
        collectedDocuments: [UUID] = [],
        notes: [ClaimNote] = [],
        startedAt: Date = Date(),
        lastUpdated: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.claimId = claimId
        self.templateId = templateId
        self.currentStep = currentStep
        self.completedSteps = completedSteps
        self.collectedDocuments = collectedDocuments
        self.notes = notes
        self.startedAt = startedAt
        self.lastUpdated = lastUpdated
        self.completedAt = completedAt
    }
}

public struct ClaimNote: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let content: String
    public let attachmentIds: [UUID]
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        content: String,
        attachmentIds: [UUID] = []
    ) {
        self.id = id
        self.timestamp = timestamp
        self.content = content
        self.attachmentIds = attachmentIds
    }
}

// MARK: - Default Templates

extension ClaimTemplate {
    public static let defaultTemplates: [ClaimTemplate] = [
        // Theft Claim Template
        ClaimTemplate(
            type: .theft,
            title: "Theft Claim Process",
            description: "Step-by-step guide for filing a theft claim",
            requiredDocuments: [
                RequiredDocument(
                    name: "Police Report",
                    description: "Official police report with case number",
                    tips: "File within 24-48 hours of discovering theft"
                ),
                RequiredDocument(
                    name: "Proof of Ownership",
                    description: "Receipts, photos, or documentation proving ownership",
                    tips: "Include serial numbers if available"
                ),
                RequiredDocument(
                    name: "Insurance Policy",
                    description: "Copy of your current insurance policy"
                ),
                RequiredDocument(
                    name: "Claim Form",
                    description: "Completed insurance claim form"
                ),
                RequiredDocument(
                    name: "Photo Evidence",
                    description: "Photos of where item was stolen from",
                    isOptional: true
                )
            ],
            steps: [
                ClaimStep(
                    order: 1,
                    title: "File Police Report",
                    description: "Contact local police immediately to file a theft report",
                    actionItems: [
                        "Call non-emergency police line",
                        "Provide detailed description of stolen items",
                        "Get case number and officer's name",
                        "Request copy of police report"
                    ],
                    warningMessage: "Most insurers require police report within 48 hours",
                    estimatedTime: "1-2 hours"
                ),
                ClaimStep(
                    order: 2,
                    title: "Notify Insurance Company",
                    description: "Contact your insurance company to initiate claim",
                    actionItems: [
                        "Call claims hotline",
                        "Provide policy number",
                        "Brief description of incident",
                        "Get claim number"
                    ],
                    estimatedTime: "30 minutes"
                ),
                ClaimStep(
                    order: 3,
                    title: "Document Everything",
                    description: "Gather all necessary documentation",
                    actionItems: [
                        "Collect receipts and proof of purchase",
                        "Find photos of stolen items",
                        "List serial numbers and identifying marks",
                        "Document current market value"
                    ],
                    estimatedTime: "1-2 hours"
                ),
                ClaimStep(
                    order: 4,
                    title: "Submit Claim",
                    description: "Complete and submit all claim forms",
                    actionItems: [
                        "Fill out claim forms completely",
                        "Attach all documentation",
                        "Submit via preferred method",
                        "Keep copies of everything"
                    ],
                    estimatedTime: "1 hour"
                ),
                ClaimStep(
                    order: 5,
                    title: "Follow Up",
                    description: "Monitor claim progress and respond to requests",
                    actionItems: [
                        "Track claim status",
                        "Respond to adjuster questions",
                        "Provide additional info if requested",
                        "Document all communications"
                    ],
                    estimatedTime: "Ongoing"
                )
            ],
            tips: [
                "Act quickly - most policies have time limits for filing claims",
                "Be honest and accurate in all statements",
                "Keep detailed records of all communications",
                "Take photos of the location where theft occurred",
                "Consider changing locks if keys were stolen"
            ],
            estimatedTimeframe: "2-4 weeks",
            emailTemplate: """
            Subject: Theft Claim - Policy #[POLICY_NUMBER]
            
            Dear Claims Department,
            
            I am writing to report a theft and initiate a claim under my policy #[POLICY_NUMBER].
            
            Incident Details:
            - Date of theft: [DATE]
            - Location: [LOCATION]
            - Police report #: [REPORT_NUMBER]
            - Items stolen: [ITEM_LIST]
            - Estimated value: $[AMOUNT]
            
            I have attached the following documents:
            - Police report
            - Proof of ownership
            - Photos of items
            - Completed claim form
            
            Please confirm receipt of this claim and provide next steps.
            
            Thank you,
            [YOUR_NAME]
            [CONTACT_INFO]
            """
        ),
        
        // Damage Claim Template
        ClaimTemplate(
            type: .damage,
            title: "Property Damage Claim",
            description: "Guide for filing claims for damaged items",
            requiredDocuments: [
                RequiredDocument(
                    name: "Photos of Damage",
                    description: "Clear photos showing extent of damage"
                ),
                RequiredDocument(
                    name: "Incident Report",
                    description: "Detailed description of how damage occurred"
                ),
                RequiredDocument(
                    name: "Repair Estimates",
                    description: "Professional estimates for repair costs",
                    isOptional: true
                ),
                RequiredDocument(
                    name: "Original Purchase Info",
                    description: "Receipts or proof of item value"
                )
            ],
            steps: [
                ClaimStep(
                    order: 1,
                    title: "Document Damage",
                    description: "Take photos and document the damage thoroughly",
                    actionItems: [
                        "Photograph damage from multiple angles",
                        "Include close-ups and wide shots",
                        "Document date and time",
                        "Preserve damaged item if possible"
                    ],
                    warningMessage: "Do not dispose of damaged items until claim is settled",
                    estimatedTime: "30 minutes"
                ),
                ClaimStep(
                    order: 2,
                    title: "Prevent Further Damage",
                    description: "Take reasonable steps to prevent additional damage",
                    actionItems: [
                        "Make temporary repairs if safe",
                        "Document mitigation efforts",
                        "Keep receipts for emergency repairs",
                        "Take photos of temporary fixes"
                    ],
                    estimatedTime: "Varies"
                ),
                ClaimStep(
                    order: 3,
                    title: "Get Repair Estimates",
                    description: "Obtain professional repair or replacement estimates",
                    actionItems: [
                        "Contact qualified repair services",
                        "Get written estimates",
                        "Include parts and labor costs",
                        "Get multiple estimates if valuable"
                    ],
                    estimatedTime: "2-3 days"
                )
            ],
            tips: [
                "Don't throw away damaged items",
                "Keep all receipts for temporary repairs",
                "Be prepared for adjuster inspection",
                "Document pre-damage condition if possible"
            ],
            estimatedTimeframe: "1-3 weeks"
        ),
        
        // Warranty Claim Template
        ClaimTemplate(
            type: .warranty,
            title: "Warranty Claim Process",
            description: "Steps for filing a warranty claim",
            requiredDocuments: [
                RequiredDocument(
                    name: "Proof of Purchase",
                    description: "Original receipt or invoice"
                ),
                RequiredDocument(
                    name: "Warranty Documentation",
                    description: "Warranty certificate or terms"
                ),
                RequiredDocument(
                    name: "Serial Number",
                    description: "Product serial or model number"
                ),
                RequiredDocument(
                    name: "Problem Description",
                    description: "Detailed description of the issue"
                )
            ],
            steps: [
                ClaimStep(
                    order: 1,
                    title: "Verify Warranty Coverage",
                    description: "Confirm item is still under warranty",
                    actionItems: [
                        "Check warranty expiration date",
                        "Review covered issues",
                        "Verify warranty hasn't been voided",
                        "Locate warranty documentation"
                    ],
                    estimatedTime: "30 minutes"
                ),
                ClaimStep(
                    order: 2,
                    title: "Contact Manufacturer",
                    description: "Reach out to warranty provider",
                    actionItems: [
                        "Call warranty service number",
                        "Have serial number ready",
                        "Describe issue clearly",
                        "Get case/reference number"
                    ],
                    estimatedTime: "30-60 minutes"
                ),
                ClaimStep(
                    order: 3,
                    title: "Follow Return Process",
                    description: "Complete required return or service steps",
                    actionItems: [
                        "Get RMA number if required",
                        "Package item properly",
                        "Include required documentation",
                        "Ship via specified method"
                    ],
                    estimatedTime: "1-2 hours"
                )
            ],
            tips: [
                "Register products when purchased",
                "Keep all original packaging if possible",
                "Document issues with photos/videos",
                "Be patient - warranty claims take time"
            ],
            estimatedTimeframe: "2-6 weeks"
        )
    ]
}