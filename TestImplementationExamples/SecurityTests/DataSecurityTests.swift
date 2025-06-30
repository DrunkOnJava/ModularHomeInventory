import XCTest
import CryptoKit
import LocalAuthentication
@testable import Core
@testable import AppSettings

/// Tests for data encryption, secure storage, and privacy
class DataSecurityTests: XCTestCase {
    
    var securityService: SecurityService!
    var keychainService: KeychainService!
    
    override func setUp() {
        super.setUp()
        securityService = SecurityService()
        keychainService = KeychainService()
        
        // Clean keychain for tests
        keychainService.removeAll()
    }
    
    override func tearDown() {
        keychainService.removeAll()
        super.tearDown()
    }
    
    // MARK: - Encryption Tests
    
    func testAESEncryption() throws {
        let sensitiveData = "Credit Card: 4111-1111-1111-1111, CVV: 123"
        let plainData = sensitiveData.data(using: .utf8)!
        
        // Generate encryption key
        let key = SymmetricKey(size: .bits256)
        
        // Encrypt
        let encrypted = try securityService.encrypt(plainData, using: key)
        
        // Verify encrypted data is different
        XCTAssertNotEqual(encrypted, plainData)
        XCTAssertGreaterThan(encrypted.count, plainData.count) // Includes IV and tag
        
        // Decrypt
        let decrypted = try securityService.decrypt(encrypted, using: key)
        let decryptedString = String(data: decrypted, encoding: .utf8)!
        
        XCTAssertEqual(decryptedString, sensitiveData)
    }
    
    func testEncryptionWithDifferentKeys() throws {
        let data = "Secret Message".data(using: .utf8)!
        let key1 = SymmetricKey(size: .bits256)
        let key2 = SymmetricKey(size: .bits256)
        
        let encrypted = try securityService.encrypt(data, using: key1)
        
        // Should fail with wrong key
        XCTAssertThrowsError(try securityService.decrypt(encrypted, using: key2)) { error in
            XCTAssertTrue(error is CryptoKitError)
        }
    }
    
    func testLargeDataEncryption() throws {
        // Generate 10MB of data
        let largeData = Data(repeating: 0xFF, count: 10 * 1024 * 1024)
        let key = SymmetricKey(size: .bits256)
        
        measure {
            do {
                let encrypted = try securityService.encrypt(largeData, using: key)
                let decrypted = try securityService.decrypt(encrypted, using: key)
                XCTAssertEqual(decrypted, largeData)
            } catch {
                XCTFail("Encryption failed: \(error)")
            }
        }
    }
    
    // MARK: - Keychain Tests
    
    func testKeychainStorage() throws {
        let apiToken = "sk-1234567890abcdef"
        let tokenKey = "api.token"
        
        // Store in keychain
        try keychainService.store(apiToken, forKey: tokenKey)
        
        // Retrieve
        let retrieved = try keychainService.retrieve(tokenKey)
        XCTAssertEqual(retrieved, apiToken)
        
        // Update
        let newToken = "sk-fedcba0987654321"
        try keychainService.store(newToken, forKey: tokenKey)
        
        let updated = try keychainService.retrieve(tokenKey)
        XCTAssertEqual(updated, newToken)
        
        // Delete
        try keychainService.remove(tokenKey)
        
        XCTAssertThrowsError(try keychainService.retrieve(tokenKey)) { error in
            XCTAssertTrue(error is KeychainError)
        }
    }
    
    func testKeychainAccessControl() throws {
        let secret = "sensitive-data"
        let key = "protected.item"
        
        // Store with biometric protection
        try keychainService.store(
            secret,
            forKey: key,
            accessControl: .biometryCurrentSet
        )
        
        // Create mock LA context
        let context = LAContextMock()
        context.mockBiometryType = .faceID
        context.mockCanEvaluate = true
        
        // Should require authentication to retrieve
        context.mockEvaluateResult = .failure(LAError(.userCancel))
        
        XCTAssertThrowsError(
            try keychainService.retrieve(key, context: context)
        ) { error in
            XCTAssertTrue(error is LAError)
        }
        
        // Should succeed with authentication
        context.mockEvaluateResult = .success(true)
        
        let retrieved = try keychainService.retrieve(key, context: context)
        XCTAssertEqual(retrieved, secret)
    }
    
    func testKeychainSharing() throws {
        let sharedSecret = "shared-between-apps"
        let key = "shared.secret"
        
        // Store in shared keychain group
        try keychainService.store(
            sharedSecret,
            forKey: key,
            accessGroup: "group.com.app.shared"
        )
        
        // Simulate access from another app in same group
        let otherAppKeychain = KeychainService(
            accessGroup: "group.com.app.shared"
        )
        
        let retrieved = try otherAppKeychain.retrieve(key)
        XCTAssertEqual(retrieved, sharedSecret)
    }
    
    // MARK: - Biometric Authentication Tests
    
    func testBiometricAuthentication() async throws {
        let context = LAContextMock()
        let authService = BiometricAuthService(context: context)
        
        // Test Face ID available
        context.mockBiometryType = .faceID
        context.mockCanEvaluate = true
        
        let availability = authService.biometricAvailability()
        XCTAssertEqual(availability, .available(.faceID))
        
        // Test successful authentication
        context.mockEvaluateResult = .success(true)
        
        let result = try await authService.authenticate(
            reason: "Access secure items"
        )
        XCTAssertTrue(result)
        
        // Test failed authentication
        context.mockEvaluateResult = .failure(LAError(.authenticationFailed))
        
        do {
            _ = try await authService.authenticate(reason: "Test")
            XCTFail("Should throw authentication error")
        } catch {
            XCTAssertTrue(error is LAError)
        }
    }
    
    func testBiometricFallback() async throws {
        let context = LAContextMock()
        let authService = BiometricAuthService(context: context)
        
        // Biometry not available
        context.mockBiometryType = .none
        context.mockCanEvaluate = false
        context.mockError = LAError(.biometryNotAvailable)
        
        let availability = authService.biometricAvailability()
        XCTAssertEqual(availability, .notAvailable)
        
        // Should fall back to passcode
        context.mockCanEvaluateDeviceOwnerAuthentication = true
        
        let canUseFallback = authService.canAuthenticateWithPasscode()
        XCTAssertTrue(canUseFallback)
    }
    
    // MARK: - Data Privacy Tests
    
    func testPersonalDataRedaction() throws {
        let item = Item(
            name: "MacBook Pro",
            serialNumber: "C02X1234JGH7",
            purchaseInfo: PurchaseInfo(
                storeName: "Apple Store",
                price: 2499.99,
                creditCardLast4: "1234",
                receiptEmail: "user@example.com"
            ),
            notes: "Bought with card ending in 1234"
        )
        
        // Export with privacy mode
        let exportService = ExportService()
        let exportData = try exportService.exportItems(
            [item],
            options: .init(
                includePersonalInfo: false,
                redactSensitiveData: true
            )
        )
        
        let exportString = String(data: exportData, encoding: .utf8)!
        
        // Verify sensitive data is redacted
        XCTAssertFalse(exportString.contains("C02X1234JGH7"))
        XCTAssertFalse(exportString.contains("1234"))
        XCTAssertFalse(exportString.contains("user@example.com"))
        
        // Verify non-sensitive data remains
        XCTAssertTrue(exportString.contains("MacBook Pro"))
        XCTAssertTrue(exportString.contains("2499.99"))
        XCTAssertTrue(exportString.contains("Apple Store"))
    }
    
    func testSecureDataWipe() async throws {
        // Create test data
        let item = try await ItemService.create(name: "Test Item")
        try keychainService.store("test-token", forKey: "auth.token")
        
        // Store some user preferences
        UserDefaults.standard.set("user@example.com", forKey: "user.email")
        UserDefaults.standard.set(true, forKey: "analytics.enabled")
        
        // Perform secure wipe
        try await SecurityService.performSecureWipe()
        
        // Verify all data is removed
        let items = try await ItemService.getAllItems()
        XCTAssertTrue(items.isEmpty)
        
        // Verify keychain is cleared
        XCTAssertThrowsError(try keychainService.retrieve("auth.token"))
        
        // Verify sensitive preferences removed
        XCTAssertNil(UserDefaults.standard.string(forKey: "user.email"))
        
        // Verify non-sensitive preferences remain
        XCTAssertNotNil(UserDefaults.standard.object(forKey: "app.firstLaunch"))
    }
    
    func testDataAnonymization() throws {
        let analytics = AnalyticsEvent(
            eventName: "item_added",
            userId: "user123",
            deviceId: "device456",
            properties: [
                "item_name": "Personal Document",
                "category": "Documents",
                "location": "37.7749,-122.4194" // GPS coordinates
            ]
        )
        
        let anonymized = SecurityService.anonymize(analytics)
        
        // User ID should be hashed
        XCTAssertNotEqual(anonymized.userId, "user123")
        XCTAssertEqual(anonymized.userId?.count, 64) // SHA256 hash
        
        // Device ID should be preserved (needed for analytics)
        XCTAssertEqual(anonymized.deviceId, analytics.deviceId)
        
        // Sensitive properties should be removed or generalized
        XCTAssertNil(anonymized.properties["item_name"])
        XCTAssertEqual(anonymized.properties["category"], "Documents")
        XCTAssertEqual(anonymized.properties["location"], "California") // Generalized
    }
    
    // MARK: - Secure Communication Tests
    
    func testCertificatePinning() async throws {
        let session = URLSession(
            configuration: .default,
            delegate: CertificatePinningDelegate(),
            delegateQueue: nil
        )
        
        let syncService = SyncService(session: session)
        
        // Should succeed with valid certificate
        MockCertificateValidator.mockCertificate = TestCertificates.valid
        try await syncService.sync()
        
        // Should fail with invalid certificate
        MockCertificateValidator.mockCertificate = TestCertificates.invalid
        
        do {
            try await syncService.sync()
            XCTFail("Should reject invalid certificate")
        } catch {
            XCTAssertTrue(error is CertificatePinningError)
        }
    }
    
    func testSecureHeaders() async throws {
        var capturedRequest: URLRequest?
        
        MockURLProtocol.mockHandler = { request in
            capturedRequest = request
            
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            return (Data("{}".utf8), response)
        }
        
        let service = NetworkService()
        _ = try await service.request(endpoint: .sync)
        
        // Verify security headers
        XCTAssertNotNil(capturedRequest)
        let headers = capturedRequest!.allHTTPHeaderFields!
        
        // Should include security headers
        XCTAssertNotNil(headers["X-Request-ID"])
        XCTAssertEqual(headers["X-Platform"], "iOS")
        XCTAssertNotNil(headers["X-App-Version"])
        
        // Should not include sensitive data in headers
        XCTAssertNil(headers["Authorization"]) // Should use encrypted body
        XCTAssertNil(headers["X-User-Email"])
    }
}

// MARK: - Mock Helpers

class LAContextMock: LAContext {
    var mockBiometryType: LABiometryType = .none
    var mockCanEvaluate = false
    var mockCanEvaluateDeviceOwnerAuthentication = false
    var mockError: Error?
    var mockEvaluateResult: Result<Bool, Error>?
    
    override var biometryType: LABiometryType {
        return mockBiometryType
    }
    
    override func canEvaluatePolicy(
        _ policy: LAPolicy,
        error: NSErrorPointer
    ) -> Bool {
        if let mockError = mockError {
            error?.pointee = mockError as NSError
            return false
        }
        
        switch policy {
        case .deviceOwnerAuthenticationWithBiometrics:
            return mockCanEvaluate
        case .deviceOwnerAuthentication:
            return mockCanEvaluateDeviceOwnerAuthentication
        default:
            return false
        }
    }
    
    override func evaluatePolicy(
        _ policy: LAPolicy,
        localizedReason: String,
        reply: @escaping (Bool, Error?) -> Void
    ) {
        DispatchQueue.main.async {
            switch self.mockEvaluateResult {
            case .success(let result):
                reply(result, nil)
            case .failure(let error):
                reply(false, error)
            case nil:
                reply(false, LAError(.unknown))
            }
        }
    }
}