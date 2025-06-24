import Foundation
import LocalAuthentication

/// Service for managing biometric authentication (Face ID/Touch ID)
/// Swift 5.9 - No Swift 6 features
@MainActor
public final class BiometricAuthService: ObservableObject {
    
    // Singleton instance
    public static let shared = BiometricAuthService()
    
    // Published properties
    @Published public var isAuthenticated = false
    @Published public var biometricType: BiometricType = .none
    @Published public var isAvailable = false
    @Published public var error: BiometricError?
    
    // Private properties
    private let context = LAContext()
    private let keychainService = KeychainService()
    
    // Biometric types
    public enum BiometricType {
        case none
        case touchID
        case faceID
        
        public var displayName: String {
            switch self {
            case .none: return "None"
            case .touchID: return "Touch ID"
            case .faceID: return "Face ID"
            }
        }
        
        public var icon: String {
            switch self {
            case .none: return "lock"
            case .touchID: return "touchid"
            case .faceID: return "faceid"
            }
        }
    }
    
    // Error types
    public enum BiometricError: LocalizedError {
        case notAvailable
        case notEnrolled
        case authenticationFailed
        case userCancelled
        case passcodeNotSet
        case systemCancel
        case appCancel
        case invalidContext
        case notInteractive
        case unknown(String)
        
        public var errorDescription: String? {
            switch self {
            case .notAvailable:
                return "Biometric authentication is not available on this device"
            case .notEnrolled:
                return "No biometric data is enrolled. Please set up Face ID or Touch ID in Settings"
            case .authenticationFailed:
                return "Authentication failed. Please try again"
            case .userCancelled:
                return "Authentication was cancelled"
            case .passcodeNotSet:
                return "Device passcode is not set"
            case .systemCancel:
                return "Authentication was cancelled by the system"
            case .appCancel:
                return "Authentication was cancelled by the app"
            case .invalidContext:
                return "Invalid authentication context"
            case .notInteractive:
                return "Authentication requires user interaction"
            case .unknown(let message):
                return message
            }
        }
    }
    
    private init() {
        checkBiometricAvailability()
    }
    
    // MARK: - Public Methods
    
    /// Check if biometric authentication is available
    public func checkBiometricAvailability() {
        var error: NSError?
        let available = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        isAvailable = available
        
        if available {
            switch context.biometryType {
            case .none:
                biometricType = .none
            case .touchID:
                biometricType = .touchID
            case .faceID:
                biometricType = .faceID
            @unknown default:
                biometricType = .none
            }
        } else {
            biometricType = .none
            if let error = error {
                self.error = mapError(error)
            }
        }
    }
    
    /// Authenticate using biometrics
    public func authenticate(reason: String = "Authenticate to access your inventory") async -> Bool {
        // Reset error
        error = nil
        
        // Check availability first
        guard isAvailable else {
            error = .notAvailable
            return false
        }
        
        // Create new context for this authentication
        let authContext = LAContext()
        authContext.localizedCancelTitle = "Cancel"
        
        // Set fallback to device passcode after first failed attempt
        authContext.localizedFallbackTitle = "Enter Passcode"
        
        do {
            let success = try await authContext.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            await MainActor.run {
                self.isAuthenticated = success
            }
            
            return success
        } catch let error as NSError {
            await MainActor.run {
                self.error = mapError(error)
                self.isAuthenticated = false
            }
            return false
        }
    }
    
    /// Authenticate with biometrics or device passcode
    public func authenticateWithPasscode(reason: String = "Authenticate to access your inventory") async -> Bool {
        // Reset error
        error = nil
        
        // Create new context for this authentication
        let authContext = LAContext()
        
        do {
            let success = try await authContext.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            
            await MainActor.run {
                self.isAuthenticated = success
            }
            
            return success
        } catch let error as NSError {
            await MainActor.run {
                self.error = mapError(error)
                self.isAuthenticated = false
            }
            return false
        }
    }
    
    /// Store sensitive data in keychain with biometric protection
    public func storeSecureData(_ data: Data, for key: String) async throws {
        guard isAvailable else {
            throw BiometricError.notAvailable
        }
        
        // Create access control with biometric protection
        let access = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .biometryCurrentSet,
            nil
        )
        
        try keychainService.store(data, for: key, accessControl: access)
    }
    
    /// Retrieve sensitive data from keychain with biometric authentication
    public func retrieveSecureData(for key: String, reason: String = "Authenticate to access secure data") async throws -> Data? {
        // Authenticate first
        let authenticated = await authenticate(reason: reason)
        guard authenticated else {
            throw error ?? BiometricError.authenticationFailed
        }
        
        return try keychainService.retrieve(for: key)
    }
    
    /// Remove secure data from keychain
    public func removeSecureData(for key: String) throws {
        try keychainService.remove(for: key)
    }
    
    /// Reset authentication state
    public func reset() {
        isAuthenticated = false
        error = nil
    }
    
    // MARK: - Private Methods
    
    private func mapError(_ error: NSError) -> BiometricError {
        let laError = LAError(_nsError: error)
        
        switch laError.code {
        case .authenticationFailed:
            return .authenticationFailed
        case .userCancel:
            return .userCancelled
        case .userFallback:
            return .authenticationFailed
        case .systemCancel:
            return .systemCancel
        case .passcodeNotSet:
            return .passcodeNotSet
        case .biometryNotAvailable:
            return .notAvailable
        case .biometryNotEnrolled:
            return .notEnrolled
        case .biometryLockout:
            return .authenticationFailed
        case .appCancel:
            return .appCancel
        case .invalidContext:
            return .invalidContext
        case .notInteractive:
            return .notInteractive
        default:
            return .unknown(error.localizedDescription)
        }
    }
}

// MARK: - Keychain Service

private final class KeychainService {
    
    enum KeychainError: LocalizedError {
        case unhandledError(status: OSStatus)
        case noData
        case unexpectedData
        
        var errorDescription: String? {
            switch self {
            case .unhandledError(let status):
                return "Keychain error: \(status)"
            case .noData:
                return "No data found in keychain"
            case .unexpectedData:
                return "Unexpected data format in keychain"
            }
        }
    }
    
    func store(_ data: Data, for key: String, accessControl: SecAccessControl? = nil) throws {
        // Remove any existing item first
        try? remove(for: key)
        
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrService as String: "com.homeinventory.biometric"
        ]
        
        if let accessControl = accessControl {
            query[kSecAttrAccessControl as String] = accessControl
        }
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    func retrieve(for key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.homeinventory.biometric",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecItemNotFound {
            return nil
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
        
        guard let data = dataTypeRef as? Data else {
            throw KeychainError.unexpectedData
        }
        
        return data
    }
    
    func remove(for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.homeinventory.biometric"
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
}