import XCTest
import CryptoKit
@testable import Core
@testable import AppSettings
@testable import TestUtilities

/// Tests for data encryption and secure storage
final class DataEncryptionTests: XCTestCase {
    
    var securityService: SecurityService!
    var keychainService: KeychainService!
    
    override func setUp() {
        super.setUp()
        securityService = SecurityService()
        keychainService = KeychainService(accessGroup: "test.keychain")
        
        // Clean keychain for tests
        keychainService.removeAll()
    }
    
    override func tearDown() {
        keychainService.removeAll()
        super.tearDown()
    }
    
    // MARK: - Encryption Tests
    
    func testAESEncryption() throws {
        let sensitiveData = "Credit Card: 4111-1111-1111-1111, CVV: 123, PIN: 1234"
        let plainData = sensitiveData.data(using: .utf8)!
        
        // Encrypt data
        let encryptedData = try securityService.encrypt(plainData)
        
        // Verify encrypted data is different and larger (includes IV and auth tag)
        XCTAssertNotEqual(encryptedData.data, plainData)
        XCTAssertGreaterThan(encryptedData.data.count, plainData.count)
        XCTAssertNotNil(encryptedData.nonce)
        XCTAssertNotNil(encryptedData.tag)
        
        // Decrypt data
        let decryptedData = try securityService.decrypt(encryptedData)
        let decryptedString = String(data: decryptedData, encoding: .utf8)!
        
        XCTAssertEqual(decryptedString, sensitiveData)
    }
    
    func testEncryptionWithDifferentKeys() throws {
        let data = "Secret Message".data(using: .utf8)!
        
        // Encrypt with first key
        let encrypted1 = try securityService.encrypt(data)
        
        // Create new security service with different key
        let securityService2 = SecurityService()
        
        // Should fail to decrypt with wrong key
        XCTAssertThrowsError(try securityService2.decrypt(encrypted1)) { error in
            XCTAssertTrue(error is CryptoKitError)
        }
    }
    
    func testLargeDataEncryption() throws {
        // Generate 10MB of data
        let largeData = Data(repeating: 0xFF, count: 10 * 1024 * 1024)
        
        measure {
            do {
                let encrypted = try securityService.encrypt(largeData)
                let decrypted = try securityService.decrypt(encrypted)
                XCTAssertEqual(decrypted, largeData)
            } catch {
                XCTFail("Encryption failed: \(error)")
            }
        }
    }
    
    func testEncryptionKeyDerivation() throws {
        let password = "MySecurePassword123!"
        let salt = "unique-user-salt"
        
        // Derive key from password
        let key1 = try securityService.deriveKey(from: password, salt: salt)
        let key2 = try securityService.deriveKey(from: password, salt: salt)
        
        // Same password and salt should produce same key
        XCTAssertEqual(key1, key2)
        
        // Different password should produce different key
        let key3 = try securityService.deriveKey(from: "DifferentPassword", salt: salt)
        XCTAssertNotEqual(key1, key3)
        
        // Different salt should produce different key
        let key4 = try securityService.deriveKey(from: password, salt: "different-salt")
        XCTAssertNotEqual(key1, key4)
    }
    
    // MARK: - Secure Field Storage Tests
    
    func testSecureFieldEncryption() throws {
        let item = TestDataBuilder.createItem(
            name: "MacBook Pro",
            serialNumber: "C02X1234JGH7",
            notes: "Purchase receipt: #12345, Store PIN: 9876"
        )
        
        // Encrypt sensitive fields
        let encryptedItem = try securityService.encryptSensitiveFields(item)
        
        // Verify sensitive fields are encrypted
        XCTAssertNotEqual(encryptedItem.serialNumber, item.serialNumber)
        XCTAssertNotEqual(encryptedItem.notes, item.notes)
        XCTAssertEqual(encryptedItem.name, item.name) // Name should not be encrypted
        
        // Decrypt fields
        let decryptedItem = try securityService.decryptSensitiveFields(encryptedItem)
        
        XCTAssertEqual(decryptedItem.serialNumber, item.serialNumber)
        XCTAssertEqual(decryptedItem.notes, item.notes)
    }
    
    // MARK: - File Encryption Tests
    
    func testFileEncryption() throws {
        let testData = "Sensitive file content".data(using: .utf8)!
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-encrypted.dat")
        
        // Encrypt and write file
        try securityService.encryptAndWriteFile(data: testData, to: fileURL)
        
        // Verify file is encrypted
        let encryptedFileData = try Data(contentsOf: fileURL)
        XCTAssertNotEqual(encryptedFileData, testData)
        
        // Read and decrypt file
        let decryptedData = try securityService.readAndDecryptFile(from: fileURL)
        XCTAssertEqual(decryptedData, testData)
        
        // Cleanup
        try FileManager.default.removeItem(at: fileURL)
    }
    
    func testImageEncryption() throws {
        let image = TestDataBuilder.createTestImage(size: CGSize(width: 100, height: 100))
        let imageData = image.pngData()!
        
        // Encrypt image
        let encryptedImage = try securityService.encryptImage(image)
        
        // Verify encrypted data is different
        XCTAssertNotEqual(encryptedImage.data, imageData)
        
        // Decrypt image
        let decryptedImage = try securityService.decryptImage(encryptedImage)
        
        // Compare image data (not UIImage objects directly)
        XCTAssertEqual(decryptedImage.pngData(), imageData)
    }
    
    // MARK: - Database Encryption Tests
    
    func testDatabaseEncryption() async throws {
        // Create encrypted database
        let encryptedDB = try await SecureDatabase.create(
            name: "TestEncrypted",
            password: "dbPassword123"
        )
        
        // Store sensitive data
        let item = TestDataBuilder.createItem(
            name: "Secret Item",
            value: 9999.99,
            serialNumber: "SECRET123"
        )
        
        try await encryptedDB.save(item)
        
        // Verify data is encrypted at rest
        let dbURL = encryptedDB.fileURL
        let rawData = try Data(contentsOf: dbURL)
        let rawString = String(data: rawData, encoding: .utf8) ?? ""
        
        // Sensitive data should not be visible in raw file
        XCTAssertFalse(rawString.contains("Secret Item"))
        XCTAssertFalse(rawString.contains("SECRET123"))
        
        // Verify can read with correct password
        let retrievedItem = try await encryptedDB.fetch(Item.self, id: item.id)
        XCTAssertEqual(retrievedItem?.name, "Secret Item")
        
        // Verify cannot read with wrong password
        do {
            let wrongPasswordDB = try await SecureDatabase.open(
                at: dbURL,
                password: "wrongPassword"
            )
            _ = try await wrongPasswordDB.fetch(Item.self, id: item.id)
            XCTFail("Should not be able to read with wrong password")
        } catch {
            XCTAssertTrue(error is DatabaseError)
        }
    }
    
    // MARK: - Secure Communication Tests
    
    func testDataInTransitEncryption() async throws {
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
        
        // Send sensitive data
        let sensitivePayload = SensitiveData(
            creditCard: "4111111111111111",
            ssn: "123-45-6789",
            password: "MySecretPassword"
        )
        
        let networkService = SecureNetworkService(session: URLSession.shared)
        try await networkService.sendSensitiveData(sensitivePayload)
        
        // Verify request was encrypted
        XCTAssertNotNil(capturedRequest)
        let body = capturedRequest!.httpBody!
        let bodyString = String(data: body, encoding: .utf8) ?? ""
        
        // Sensitive data should not be visible in request
        XCTAssertFalse(bodyString.contains("4111111111111111"))
        XCTAssertFalse(bodyString.contains("123-45-6789"))
        XCTAssertFalse(bodyString.contains("MySecretPassword"))
        
        // Verify proper headers
        XCTAssertEqual(capturedRequest!.value(forHTTPHeaderField: "Content-Type"), "application/octet-stream")
        XCTAssertNotNil(capturedRequest!.value(forHTTPHeaderField: "X-Encryption-Version"))
    }
    
    // MARK: - Memory Security Tests
    
    func testSecureMemoryHandling() throws {
        // Test that sensitive data is cleared from memory
        autoreleasepool {
            let sensitiveString = "SuperSecretPassword123!"
            let secureString = SecureString(sensitiveString)
            
            // Use the secure string
            XCTAssertEqual(secureString.reveal(), sensitiveString)
            
            // Clear sensitive data
            secureString.clear()
            
            // Verify cleared
            XCTAssertNotEqual(secureString.reveal(), sensitiveString)
            XCTAssertTrue(secureString.isCleared)
        }
        
        // Force memory cleanup
        for _ in 0..<10 {
            autoreleasepool {
                _ = (0..<1000).map { _ in UUID().uuidString }
            }
        }
        
        // At this point, sensitive data should be overwritten in memory
        // (This is hard to verify in a unit test, but the SecureString
        // implementation should handle it properly)
    }
    
    // MARK: - Cryptographic Hash Tests
    
    func testHashingAndVerification() throws {
        let password = "UserPassword123!"
        
        // Hash password
        let hashedPassword = try securityService.hashPassword(password)
        
        // Verify correct password
        XCTAssertTrue(try securityService.verifyPassword(password, hash: hashedPassword))
        
        // Verify incorrect password
        XCTAssertFalse(try securityService.verifyPassword("WrongPassword", hash: hashedPassword))
        
        // Verify hash is salted (same password produces different hashes)
        let hashedPassword2 = try securityService.hashPassword(password)
        XCTAssertNotEqual(hashedPassword, hashedPassword2)
        
        // But both hashes verify correctly
        XCTAssertTrue(try securityService.verifyPassword(password, hash: hashedPassword2))
    }
    
    func testDataIntegrityVerification() throws {
        let data = "Important data that must not be tampered with".data(using: .utf8)!
        
        // Generate signature
        let signature = try securityService.sign(data)
        
        // Verify valid signature
        XCTAssertTrue(try securityService.verify(data: data, signature: signature))
        
        // Tamper with data
        var tamperedData = data
        tamperedData[0] = 0xFF
        
        // Verify signature fails for tampered data
        XCTAssertFalse(try securityService.verify(data: tamperedData, signature: signature))
    }
}

// MARK: - Supporting Types

struct SensitiveData: Codable {
    let creditCard: String
    let ssn: String
    let password: String
}

class SecureString {
    private var data: Data
    private(set) var isCleared = false
    
    init(_ string: String) {
        self.data = string.data(using: .utf8) ?? Data()
    }
    
    func reveal() -> String {
        guard !isCleared else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    func clear() {
        // Overwrite memory with random data
        for i in 0..<data.count {
            data[i] = UInt8.random(in: 0...255)
        }
        data = Data()
        isCleared = true
    }
    
    deinit {
        clear()
    }
}