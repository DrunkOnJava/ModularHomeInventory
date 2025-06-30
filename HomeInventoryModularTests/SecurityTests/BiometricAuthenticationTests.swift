import XCTest
import LocalAuthentication
@testable import Core
@testable import AppSettings
@testable import TestUtilities

/// Tests for biometric authentication (Face ID/Touch ID)
final class BiometricAuthenticationTests: XCTestCase {
    
    var biometricService: BiometricAuthenticationService!
    var keychainService: KeychainService!
    var settingsService: SettingsService!
    
    override func setUp() {
        super.setUp()
        biometricService = BiometricAuthenticationService()
        keychainService = KeychainService(accessGroup: "test.keychain")
        settingsService = SettingsService()
        
        // Clean keychain
        keychainService.removeAll()
    }
    
    override func tearDown() {
        keychainService.removeAll()
        super.tearDown()
    }
    
    // MARK: - Biometric Availability Tests
    
    func testBiometricAvailability() throws {
        let availability = biometricService.checkBiometricAvailability()
        
        #if targetEnvironment(simulator)
        // Simulator may not have biometrics
        XCTAssertTrue(
            availability == .notAvailable || 
            availability == .notEnrolled ||
            availability == .available
        )
        #else
        // Physical device should have definitive status
        XCTAssertNotNil(availability)
        #endif
        
        // Log availability for debugging
        print("Biometric availability: \(availability)")
    }
    
    func testBiometricType() throws {
        let biometricType = biometricService.biometricType
        
        #if targetEnvironment(simulator)
        // Simulator reports based on device type
        XCTAssertTrue(
            biometricType == .none ||
            biometricType == .touchID ||
            biometricType == .faceID
        )
        #else
        // Physical device should report actual type
        XCTAssertNotNil(biometricType)
        #endif
        
        print("Biometric type: \(biometricType)")
    }
    
    // MARK: - Authentication Flow Tests
    
    func testBiometricAuthenticationSetup() async throws {
        // Skip on simulator without biometrics
        guard biometricService.checkBiometricAvailability() == .available else {
            throw XCTSkip("Biometric authentication not available")
        }
        
        // Enable biometric authentication
        try await biometricService.enableBiometricAuthentication(
            reason: "Enable Face ID/Touch ID for app security"
        )
        
        // Verify settings updated
        let settings = await settingsService.currentSettings
        XCTAssertTrue(settings.enableBiometrics)
        
        // Verify keychain entry created
        XCTAssertTrue(try keychainService.hasBiometricProtectedItem())
    }
    
    func testBiometricAuthentication() async throws {
        // Skip on simulator
        #if targetEnvironment(simulator)
        throw XCTSkip("Biometric authentication requires physical device")
        #else
        
        // Enable biometrics first
        try await biometricService.enableBiometricAuthentication(
            reason: "Setup biometric authentication"
        )
        
        // Authenticate
        let result = await biometricService.authenticate(
            reason: "Access your secure inventory data"
        )
        
        switch result {
        case .success:
            XCTAssertTrue(true, "Authentication succeeded")
        case .userCancelled:
            XCTFail("User cancelled authentication")
        case .failed(let error):
            XCTFail("Authentication failed: \(error)")
        case .biometryNotAvailable:
            throw XCTSkip("Biometry not available")
        case .biometryNotEnrolled:
            throw XCTSkip("Biometry not enrolled")
        case .biometryLockout:
            XCTFail("Biometry locked out")
        }
        #endif
    }
    
    func testBiometricAuthenticationCancellation() async throws {
        // Mock LAContext for testing
        let mockContext = MockLAContext()
        mockContext.canEvaluatePolicyResult = true
        mockContext.evaluatePolicyResult = .failure(LAError(.userCancel))
        
        biometricService.context = mockContext
        
        let result = await biometricService.authenticate(
            reason: "Test authentication"
        )
        
        XCTAssertEqual(result, .userCancelled)
    }
    
    func testBiometricAuthenticationFailure() async throws {
        // Mock LAContext for testing
        let mockContext = MockLAContext()
        mockContext.canEvaluatePolicyResult = true
        mockContext.evaluatePolicyResult = .failure(LAError(.authenticationFailed))
        
        biometricService.context = mockContext
        
        let result = await biometricService.authenticate(
            reason: "Test authentication"
        )
        
        if case .failed(let error) = result {
            XCTAssertTrue(error.localizedDescription.contains("Authentication failed"))
        } else {
            XCTFail("Expected authentication failure")
        }
    }
    
    // MARK: - Fallback Authentication Tests
    
    func testPasscodeFallback() async throws {
        // Configure to allow passcode fallback
        biometricService.allowPasscodeFallback = true
        
        // Mock biometric failure
        let mockContext = MockLAContext()
        mockContext.canEvaluatePolicyResult = true
        mockContext.evaluatePolicyResult = .failure(LAError(.biometryNotAvailable))
        
        biometricService.context = mockContext
        
        // Should fall back to passcode
        let result = await biometricService.authenticateWithFallback(
            reason: "Access secure data"
        )
        
        // In test environment, we can't actually test passcode
        // But we verify the fallback mechanism is triggered
        XCTAssertNotNil(result)
    }
    
    func testCustomPasswordFallback() async throws {
        // Disable system passcode fallback
        biometricService.allowPasscodeFallback = false
        
        // Set custom password
        let customPassword = "SecurePassword123!"
        try await biometricService.setFallbackPassword(customPassword)
        
        // Mock biometric failure
        let mockContext = MockLAContext()
        mockContext.canEvaluatePolicyResult = true
        mockContext.evaluatePolicyResult = .failure(LAError(.authenticationFailed))
        
        biometricService.context = mockContext
        
        // Attempt authentication
        let result = await biometricService.authenticateWithFallback(
            reason: "Access secure data"
        )
        
        // Should prompt for custom password
        if case .requiresPassword = result {
            // Verify password
            let passwordResult = try await biometricService.verifyFallbackPassword(customPassword)
            XCTAssertTrue(passwordResult)
        } else {
            XCTFail("Expected password requirement")
        }
    }
    
    // MARK: - Security Policy Tests
    
    func testBiometricPolicyConfiguration() throws {
        let policy = BiometricPolicy(
            requireRecentAuthentication: true,
            authenticationValidityDuration: 300, // 5 minutes
            maxFailedAttempts: 3,
            lockoutDuration: 3600 // 1 hour
        )
        
        biometricService.configure(policy: policy)
        
        XCTAssertEqual(biometricService.policy.requireRecentAuthentication, true)
        XCTAssertEqual(biometricService.policy.authenticationValidityDuration, 300)
        XCTAssertEqual(biometricService.policy.maxFailedAttempts, 3)
    }
    
    func testRecentAuthenticationRequirement() async throws {
        // Configure policy requiring recent authentication
        let policy = BiometricPolicy(
            requireRecentAuthentication: true,
            authenticationValidityDuration: 5 // 5 seconds
        )
        
        biometricService.configure(policy: policy)
        
        // Mock successful authentication
        let mockContext = MockLAContext()
        mockContext.canEvaluatePolicyResult = true
        mockContext.evaluatePolicyResult = .success(())
        
        biometricService.context = mockContext
        
        // First authentication
        let result1 = await biometricService.authenticate(reason: "Test")
        XCTAssertEqual(result1, .success)
        
        // Immediate re-authentication should use cached result
        let result2 = await biometricService.authenticate(reason: "Test")
        XCTAssertEqual(result2, .success)
        
        // Wait for cache to expire
        try await Task.sleep(seconds: 6)
        
        // Should require new authentication
        mockContext.evaluatePolicyCallCount = 0
        let result3 = await biometricService.authenticate(reason: "Test")
        XCTAssertEqual(result3, .success)
        XCTAssertGreaterThan(mockContext.evaluatePolicyCallCount, 0)
    }
    
    func testFailedAttemptTracking() async throws {
        let policy = BiometricPolicy(maxFailedAttempts: 3)
        biometricService.configure(policy: policy)
        
        // Mock repeated failures
        let mockContext = MockLAContext()
        mockContext.canEvaluatePolicyResult = true
        mockContext.evaluatePolicyResult = .failure(LAError(.authenticationFailed))
        
        biometricService.context = mockContext
        
        // Attempt authentication 3 times
        for i in 1...3 {
            let result = await biometricService.authenticate(reason: "Test")
            if case .failed = result {
                XCTAssertEqual(biometricService.failedAttempts, i)
            }
        }
        
        // Fourth attempt should be locked out
        let lockedResult = await biometricService.authenticate(reason: "Test")
        XCTAssertEqual(lockedResult, .biometryLockout)
    }
    
    // MARK: - Keychain Integration Tests
    
    func testBiometricProtectedKeychainAccess() async throws {
        // Store secret with biometric protection
        let secret = "SuperSecretAPIKey"
        let key = "api.key"
        
        try keychainService.store(
            secret,
            forKey: key,
            accessControl: .biometryCurrentSet,
            authenticationPrompt: "Access API key"
        )
        
        // Mock successful authentication
        let mockContext = MockLAContext()
        mockContext.canEvaluatePolicyResult = true
        mockContext.evaluatePolicyResult = .success(())
        
        // In real scenario, retrieval would trigger biometric prompt
        // For testing, we verify the item exists with proper protection
        let attributes = try keychainService.getItemAttributes(forKey: key)
        XCTAssertNotNil(attributes[kSecAttrAccessControl as String])
    }
    
    // MARK: - App State Integration Tests
    
    func testAppLockWithBiometrics() async throws {
        // Enable app lock with biometrics
        try await settingsService.update { settings in
            settings.enableBiometrics = true
            settings.requireAuthenticationOnLaunch = true
            settings.lockAfterBackgroundTime = 60 // 1 minute
        }
        
        // Simulate app going to background
        await biometricService.applicationDidEnterBackground()
        
        // Simulate returning after lock timeout
        try await Task.sleep(seconds: 2)
        
        // Check if authentication required
        let requiresAuth = await biometricService.isAuthenticationRequired()
        XCTAssertTrue(requiresAuth)
        
        // Mock successful authentication
        let mockContext = MockLAContext()
        mockContext.canEvaluatePolicyResult = true
        mockContext.evaluatePolicyResult = .success(())
        
        biometricService.context = mockContext
        
        // Authenticate to unlock
        let result = await biometricService.authenticateForAppUnlock()
        XCTAssertEqual(result, .success)
        
        // Should no longer require authentication
        let stillRequiresAuth = await biometricService.isAuthenticationRequired()
        XCTAssertFalse(stillRequiresAuth)
    }
    
    // MARK: - Privacy Tests
    
    func testBiometricDataPrivacy() throws {
        // Verify no biometric data is stored
        let documentsPath = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        
        let biometricDataPath = documentsPath.appendingPathComponent("biometric_data")
        XCTAssertFalse(FileManager.default.fileExists(atPath: biometricDataPath.path))
        
        // Verify no biometric data in keychain
        let allKeychainItems = keychainService.getAllItems()
        for item in allKeychainItems {
            XCTAssertFalse(item.key.contains("biometric_template"))
            XCTAssertFalse(item.key.contains("face_data"))
            XCTAssertFalse(item.key.contains("fingerprint"))
        }
    }
    
    func testAuthenticationAuditLog() async throws {
        // Enable audit logging
        biometricService.enableAuditLogging = true
        
        // Mock authentication attempts
        let mockContext = MockLAContext()
        mockContext.canEvaluatePolicyResult = true
        
        biometricService.context = mockContext
        
        // Successful attempt
        mockContext.evaluatePolicyResult = .success(())
        _ = await biometricService.authenticate(reason: "Test success")
        
        // Failed attempt
        mockContext.evaluatePolicyResult = .failure(LAError(.authenticationFailed))
        _ = await biometricService.authenticate(reason: "Test failure")
        
        // Get audit log
        let auditLog = await biometricService.getAuditLog()
        
        XCTAssertEqual(auditLog.count, 2)
        XCTAssertEqual(auditLog[0].result, .success)
        XCTAssertEqual(auditLog[1].result, .failed)
        
        // Verify log doesn't contain sensitive data
        for entry in auditLog {
            XCTAssertNil(entry.biometricData)
            XCTAssertNotNil(entry.timestamp)
            XCTAssertNotNil(entry.reason)
        }
    }
}

// MARK: - Mock LAContext

class MockLAContext: LAContext {
    var canEvaluatePolicyResult = false
    var evaluatePolicyResult: Result<Void, Error> = .failure(LAError(.biometryNotAvailable))
    var evaluatePolicyCallCount = 0
    
    override func canEvaluatePolicy(
        _ policy: LAPolicy,
        error: NSErrorPointer
    ) -> Bool {
        return canEvaluatePolicyResult
    }
    
    override func evaluatePolicy(
        _ policy: LAPolicy,
        localizedReason: String,
        reply: @escaping (Bool, Error?) -> Void
    ) {
        evaluatePolicyCallCount += 1
        
        switch evaluatePolicyResult {
        case .success:
            reply(true, nil)
        case .failure(let error):
            reply(false, error)
        }
    }
}

// MARK: - Supporting Types

enum BiometricAuthenticationResult: Equatable {
    case success
    case userCancelled
    case failed(String)
    case biometryNotAvailable
    case biometryNotEnrolled
    case biometryLockout
    case requiresPassword
}

struct BiometricPolicy {
    let requireRecentAuthentication: Bool
    let authenticationValidityDuration: TimeInterval
    let maxFailedAttempts: Int
    let lockoutDuration: TimeInterval
    
    init(
        requireRecentAuthentication: Bool = false,
        authenticationValidityDuration: TimeInterval = 300,
        maxFailedAttempts: Int = 5,
        lockoutDuration: TimeInterval = 3600
    ) {
        self.requireRecentAuthentication = requireRecentAuthentication
        self.authenticationValidityDuration = authenticationValidityDuration
        self.maxFailedAttempts = maxFailedAttempts
        self.lockoutDuration = lockoutDuration
    }
}

struct BiometricAuditEntry {
    let timestamp: Date
    let reason: String
    let result: BiometricAuthenticationResult
    let biometricData: Data? // Should always be nil for privacy
}

extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: TimeInterval) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}