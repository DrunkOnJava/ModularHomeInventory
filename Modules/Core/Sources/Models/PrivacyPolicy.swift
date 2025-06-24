import Foundation

/// Privacy policy acceptance tracking
/// Swift 5.9 - No Swift 6 features
public struct PrivacyPolicyAcceptance: Codable {
    public let version: String
    public let acceptedAt: Date
    public let acceptedVersion: String
    
    public init(version: String, acceptedAt: Date, acceptedVersion: String) {
        self.version = version
        self.acceptedAt = acceptedAt
        self.acceptedVersion = acceptedVersion
    }
}

/// Privacy policy version tracking
public struct PrivacyPolicyVersion {
    public static let current = "1.0"
    public static let effectiveDate = Date(timeIntervalSince1970: 1751155200) // June 24, 2025
    
    public static var hasAcceptedCurrentVersion: Bool {
        guard let acceptance = loadAcceptance() else { return false }
        return acceptance.acceptedVersion == current
    }
    
    public static func acceptCurrentVersion() {
        let acceptance = PrivacyPolicyAcceptance(
            version: current,
            acceptedAt: Date(),
            acceptedVersion: current
        )
        saveAcceptance(acceptance)
    }
    
    private static let acceptanceKey = "com.modularhomeinventory.privacy.acceptance"
    
    static func loadAcceptance() -> PrivacyPolicyAcceptance? {
        guard let data = UserDefaults.standard.data(forKey: acceptanceKey) else { return nil }
        return try? JSONDecoder().decode(PrivacyPolicyAcceptance.self, from: data)
    }
    
    private static func saveAcceptance(_ acceptance: PrivacyPolicyAcceptance) {
        if let data = try? JSONEncoder().encode(acceptance) {
            UserDefaults.standard.set(data, forKey: acceptanceKey)
        }
    }
}

/// Privacy policy consent status
public enum PrivacyConsentStatus {
    case notAsked
    case accepted(version: String, date: Date)
    case declined
    
    public var isAccepted: Bool {
        if case .accepted = self { return true }
        return false
    }
    
    public static var current: PrivacyConsentStatus {
        if let acceptance = PrivacyPolicyVersion.loadAcceptance() {
            return .accepted(version: acceptance.acceptedVersion, date: acceptance.acceptedAt)
        }
        return .notAsked
    }
}