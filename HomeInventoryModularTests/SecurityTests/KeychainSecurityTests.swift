import XCTest
import Security
@testable import Core
@testable import TestUtilities

/// Tests for keychain security and secure credential storage
final class KeychainSecurityTests: XCTestCase {
    
    var keychainService: KeychainService!
    let testAccessGroup = "test.keychain.group"
    
    override func setUp() {
        super.setUp()
        keychainService = KeychainService(accessGroup: testAccessGroup)
        
        // Clean keychain for tests
        keychainService.removeAll()
    }
    
    override func tearDown() {
        keychainService.removeAll()
        super.tearDown()
    }
    
    // MARK: - Basic Keychain Operations
    
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
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
    }
    
    func testKeychainDataStorage() throws {
        let secretData = "Binary secret data".data(using: .utf8)!
        let dataKey = "secret.data"
        
        // Store data
        try keychainService.storeData(secretData, forKey: dataKey)
        
        // Retrieve data
        let retrievedData = try keychainService.retrieveData(dataKey)
        XCTAssertEqual(retrievedData, secretData)
    }
    
    // MARK: - Access Control Tests
    
    func testBiometricProtectedStorage() throws {
        // Skip on simulator where biometrics aren't available
        #if targetEnvironment(simulator)
        throw XCTSkip("Biometric tests require physical device")
        #else
        
        let secret = "biometric-protected-secret"
        let key = "protected.item"
        
        // Store with biometric protection
        try keychainService.store(
            secret,
            forKey: key,
            accessControl: .biometryCurrentSet,
            authenticationPrompt: "Authenticate to access secret"
        )
        
        // Retrieval would require biometric authentication
        // In tests, we can verify the item exists with proper access control
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrAccessGroup as String: testAccessGroup,
            kSecReturnAttributes as String: true
        ]
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        XCTAssertEqual(status, errSecSuccess)
        
        if let attributes = result as? [String: Any] {
            // Verify access control is set
            XCTAssertNotNil(attributes[kSecAttrAccessControl as String])
        }
        #endif
    }
    
    func testDevicePasscodeProtection() throws {
        let secret = "passcode-protected-secret"
        let key = "passcode.protected"
        
        // Store with device passcode protection
        try keychainService.store(
            secret,
            forKey: key,
            accessControl: .devicePasscode
        )
        
        // In a real scenario, retrieving this would require device passcode
        // For testing, we verify it's stored with correct attributes
        let attributes = try keychainService.getItemAttributes(forKey: key)
        XCTAssertNotNil(attributes[kSecAttrAccessControl as String])
    }
    
    // MARK: - Keychain Sharing Tests
    
    func testKeychainAccessGroupSharing() throws {
        let sharedSecret = "shared-between-apps"
        let key = "shared.secret"
        let sharedGroup = "group.com.app.shared"
        
        // Store in shared keychain group
        let sharedKeychain = KeychainService(accessGroup: sharedGroup)
        try sharedKeychain.store(sharedSecret, forKey: key)
        
        // Simulate access from another app in same group
        let otherAppKeychain = KeychainService(accessGroup: sharedGroup)
        let retrieved = try otherAppKeychain.retrieve(key)
        XCTAssertEqual(retrieved, sharedSecret)
        
        // Verify not accessible from different group
        let differentGroupKeychain = KeychainService(accessGroup: "different.group")
        XCTAssertThrowsError(try differentGroupKeychain.retrieve(key))
        
        // Cleanup
        try sharedKeychain.remove(key)
    }
    
    // MARK: - Secure Credential Storage
    
    func testCredentialStorage() throws {
        let credentials = UserCredentials(
            username: "user@example.com",
            password: "SecurePassword123!",
            apiKey: "api_key_12345",
            refreshToken: "refresh_token_67890"
        )
        
        // Store credentials securely
        try keychainService.storeCredentials(credentials)
        
        // Retrieve credentials
        let retrieved = try keychainService.retrieveCredentials()
        XCTAssertEqual(retrieved.username, credentials.username)
        XCTAssertEqual(retrieved.password, credentials.password)
        XCTAssertEqual(retrieved.apiKey, credentials.apiKey)
        XCTAssertEqual(retrieved.refreshToken, credentials.refreshToken)
        
        // Update password only
        try keychainService.updatePassword("NewPassword456!")
        
        let updated = try keychainService.retrieveCredentials()
        XCTAssertEqual(updated.password, "NewPassword456!")
        XCTAssertEqual(updated.username, credentials.username) // Others unchanged
    }
    
    // MARK: - Token Management
    
    func testOAuthTokenStorage() throws {
        let tokens = OAuthTokens(
            accessToken: "access_token_123",
            refreshToken: "refresh_token_456",
            expiresIn: 3600,
            tokenType: "Bearer"
        )
        
        // Store tokens
        try keychainService.storeOAuthTokens(tokens)
        
        // Retrieve tokens
        let retrieved = try keychainService.retrieveOAuthTokens()
        XCTAssertEqual(retrieved.accessToken, tokens.accessToken)
        XCTAssertEqual(retrieved.refreshToken, tokens.refreshToken)
        
        // Test token refresh
        let newTokens = OAuthTokens(
            accessToken: "new_access_token_789",
            refreshToken: tokens.refreshToken, // Refresh token often stays same
            expiresIn: 3600,
            tokenType: "Bearer"
        )
        
        try keychainService.refreshOAuthTokens(newTokens)
        
        let refreshed = try keychainService.retrieveOAuthTokens()
        XCTAssertEqual(refreshed.accessToken, newTokens.accessToken)
        XCTAssertEqual(refreshed.refreshToken, tokens.refreshToken)
    }
    
    // MARK: - Security Best Practices
    
    func testKeychainItemExpiration() throws {
        let temporarySecret = "temporary-secret"
        let key = "temp.secret"
        
        // Store with expiration
        let expirationDate = Date().addingTimeInterval(60) // 1 minute
        try keychainService.store(
            temporarySecret,
            forKey: key,
            expiresAt: expirationDate
        )
        
        // Verify can retrieve before expiration
        let retrieved = try keychainService.retrieve(key)
        XCTAssertEqual(retrieved, temporarySecret)
        
        // Simulate expiration check
        let isExpired = try keychainService.isItemExpired(key)
        XCTAssertFalse(isExpired)
        
        // Clean up expired items
        try keychainService.removeExpiredItems()
    }
    
    func testSensitiveDataNonPersistence() throws {
        let sensitiveData = "sensitive-memory-only"
        let key = "memory.only"
        
        // Store as non-persistent (memory only)
        try keychainService.store(
            sensitiveData,
            forKey: key,
            persistent: false
        )
        
        // Should be accessible now
        let retrieved = try keychainService.retrieve(key)
        XCTAssertEqual(retrieved, sensitiveData)
        
        // After app restart, it would be gone
        // (Can't test actual restart in unit tests)
    }
    
    // MARK: - Keychain Migration Tests
    
    func testKeychainDataMigration() throws {
        // Simulate old format data
        let oldFormatData = [
            "user": "old_user",
            "pass": "old_pass",
            "token": "old_token"
        ]
        
        // Store in old format
        for (key, value) in oldFormatData {
            try keychainService.store(value, forKey: "legacy.\(key)")
        }
        
        // Perform migration
        try keychainService.migrateToNewFormat { oldKey in
            // Migration logic
            if oldKey.hasPrefix("legacy.") {
                return String(oldKey.dropFirst(7)) // Remove "legacy." prefix
            }
            return nil
        }
        
        // Verify migrated data
        XCTAssertEqual(try keychainService.retrieve("user"), "old_user")
        XCTAssertEqual(try keychainService.retrieve("pass"), "old_pass")
        XCTAssertEqual(try keychainService.retrieve("token"), "old_token")
        
        // Verify old keys removed
        XCTAssertThrowsError(try keychainService.retrieve("legacy.user"))
    }
    
    // MARK: - Security Audit Tests
    
    func testKeychainSecurityAudit() throws {
        // Store various items with different security levels
        try keychainService.store("public-data", forKey: "public")
        try keychainService.store("private-data", forKey: "private", accessControl: .devicePasscode)
        try keychainService.store("sensitive-data", forKey: "sensitive", accessControl: .biometryCurrentSet)
        
        // Perform security audit
        let auditReport = try keychainService.performSecurityAudit()
        
        XCTAssertEqual(auditReport.totalItems, 3)
        XCTAssertEqual(auditReport.unprotectedItems.count, 1)
        XCTAssertEqual(auditReport.protectedItems.count, 2)
        
        // Check for weak protection
        XCTAssertTrue(auditReport.recommendations.contains { 
            $0.contains("Consider adding access control")
        })
    }
    
    func testDuplicateDetection() throws {
        // Store same value with different keys (potential duplicate)
        let duplicateValue = "same-secret-value"
        try keychainService.store(duplicateValue, forKey: "key1")
        try keychainService.store(duplicateValue, forKey: "key2")
        try keychainService.store("different-value", forKey: "key3")
        
        // Detect duplicates
        let duplicates = try keychainService.findDuplicateValues()
        
        XCTAssertEqual(duplicates.count, 1)
        XCTAssertEqual(duplicates.first?.keys.sorted(), ["key1", "key2"])
    }
}

// MARK: - Supporting Types

struct UserCredentials: Codable {
    let username: String
    let password: String
    let apiKey: String
    let refreshToken: String
}

struct OAuthTokens: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let tokenType: String
}

struct KeychainAuditReport {
    let totalItems: Int
    let protectedItems: [String]
    let unprotectedItems: [String]
    let expiredItems: [String]
    let recommendations: [String]
}

struct DuplicateKeychainValues {
    let value: String
    let keys: [String]
}