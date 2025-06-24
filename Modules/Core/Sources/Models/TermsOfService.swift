import Foundation

/// Terms of Service acceptance tracking
/// Swift 5.9 - No Swift 6 features
public struct TermsOfServiceAcceptance: Codable {
    public let version: String
    public let acceptedAt: Date
    public let acceptedVersion: String
    
    public init(version: String, acceptedAt: Date, acceptedVersion: String) {
        self.version = version
        self.acceptedAt = acceptedAt
        self.acceptedVersion = acceptedVersion
    }
}

/// Terms of Service version tracking
public struct TermsOfServiceVersion {
    public static let current = "1.0"
    public static let effectiveDate = Date(timeIntervalSince1970: 1751155200) // June 24, 2025
    
    public static var hasAcceptedCurrentVersion: Bool {
        guard let acceptance = loadAcceptance() else { return false }
        return acceptance.acceptedVersion == current
    }
    
    public static func acceptCurrentVersion() {
        let acceptance = TermsOfServiceAcceptance(
            version: current,
            acceptedAt: Date(),
            acceptedVersion: current
        )
        saveAcceptance(acceptance)
    }
    
    private static let acceptanceKey = "com.modularhomeinventory.terms.acceptance"
    
    static func loadAcceptance() -> TermsOfServiceAcceptance? {
        guard let data = UserDefaults.standard.data(forKey: acceptanceKey) else { return nil }
        return try? JSONDecoder().decode(TermsOfServiceAcceptance.self, from: data)
    }
    
    private static func saveAcceptance(_ acceptance: TermsOfServiceAcceptance) {
        if let data = try? JSONEncoder().encode(acceptance) {
            UserDefaults.standard.set(data, forKey: acceptanceKey)
        }
    }
}

/// Terms of Service consent status
public enum TermsConsentStatus {
    case notAsked
    case accepted(version: String, date: Date)
    case declined
    
    public var isAccepted: Bool {
        if case .accepted = self { return true }
        return false
    }
    
    public static var current: TermsConsentStatus {
        if let acceptance = TermsOfServiceVersion.loadAcceptance() {
            return .accepted(version: acceptance.acceptedVersion, date: acceptance.acceptedAt)
        }
        return .notAsked
    }
}

/// Combined legal acceptance status
public struct LegalAcceptanceStatus {
    public let privacyAccepted: Bool
    public let termsAccepted: Bool
    
    public var allAccepted: Bool {
        privacyAccepted && termsAccepted
    }
    
    public static var current: LegalAcceptanceStatus {
        LegalAcceptanceStatus(
            privacyAccepted: PrivacyPolicyVersion.hasAcceptedCurrentVersion,
            termsAccepted: TermsOfServiceVersion.hasAcceptedCurrentVersion
        )
    }
}