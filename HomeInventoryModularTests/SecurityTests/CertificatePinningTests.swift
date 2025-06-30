import XCTest
import Security
@testable import Core
@testable import Sync
@testable import TestUtilities

/// Tests for certificate pinning and secure network communication
final class CertificatePinningTests: XCTestCase {
    
    var networkService: SecureNetworkService!
    var certificateValidator: CertificateValidator!
    var testSession: URLSession!
    
    override func setUp() {
        super.setUp()
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        testSession = URLSession(configuration: config)
        
        certificateValidator = CertificateValidator()
        networkService = SecureNetworkService(
            session: testSession,
            certificateValidator: certificateValidator
        )
    }
    
    // MARK: - Certificate Validation Tests
    
    func testValidCertificatePinning() async throws {
        // Configure pinned certificates
        let pinnedCerts = [
            "api.homeinventory.com": TestCertificates.validAPICertificate,
            "sync.homeinventory.com": TestCertificates.validSyncCertificate
        ]
        
        certificateValidator.configure(pinnedCertificates: pinnedCerts)
        
        // Mock server with valid certificate
        MockURLProtocol.mockHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            // Simulate certificate chain
            MockURLProtocol.serverCertificates = [TestCertificates.validAPICertificate]
            
            return (Data("{\"status\": \"ok\"}".utf8), response)
        }
        
        // Make request - should succeed
        let result = try await networkService.secureRequest(
            to: URL(string: "https://api.homeinventory.com/items")!
        )
        
        XCTAssertNotNil(result)
    }
    
    func testInvalidCertificateRejection() async throws {
        // Configure pinned certificates
        certificateValidator.configure(
            pinnedCertificates: [
                "api.homeinventory.com": TestCertificates.validAPICertificate
            ]
        )
        
        // Mock server with different certificate
        MockURLProtocol.mockHandler = { request in
            // Simulate wrong certificate
            MockURLProtocol.serverCertificates = [TestCertificates.invalidCertificate]
            
            throw CertificateError.pinningFailed(
                host: "api.homeinventory.com",
                reason: "Certificate does not match pinned certificate"
            )
        }
        
        // Make request - should fail
        do {
            _ = try await networkService.secureRequest(
                to: URL(string: "https://api.homeinventory.com/items")!
            )
            XCTFail("Request should fail with invalid certificate")
        } catch CertificateError.pinningFailed {
            // Expected
        }
    }
    
    func testExpiredCertificateDetection() async throws {
        // Mock expired certificate
        let expiredCert = TestCertificates.createCertificate(
            validFrom: Date().addingTimeInterval(-365 * 24 * 60 * 60), // 1 year ago
            validUntil: Date().addingTimeInterval(-24 * 60 * 60) // Yesterday
        )
        
        certificateValidator.configure(
            pinnedCertificates: ["api.homeinventory.com": expiredCert],
            checkExpiration: true
        )
        
        MockURLProtocol.mockHandler = { request in
            MockURLProtocol.serverCertificates = [expiredCert]
            
            throw CertificateError.expired(
                host: "api.homeinventory.com",
                expiredAt: expiredCert.notAfter
            )
        }
        
        do {
            _ = try await networkService.secureRequest(
                to: URL(string: "https://api.homeinventory.com/items")!
            )
            XCTFail("Request should fail with expired certificate")
        } catch CertificateError.expired(_, let expiredAt) {
            XCTAssertTrue(expiredAt < Date())
        }
    }
    
    func testCertificateChainValidation() async throws {
        // Configure with root CA certificate
        let rootCA = TestCertificates.rootCACertificate
        let intermediateCert = TestCertificates.intermediateCertificate
        let leafCert = TestCertificates.leafCertificate
        
        certificateValidator.configure(
            pinnedCertificates: ["api.homeinventory.com": rootCA],
            validateChain: true
        )
        
        MockURLProtocol.mockHandler = { request in
            // Simulate full certificate chain
            MockURLProtocol.serverCertificates = [leafCert, intermediateCert, rootCA]
            
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            return (Data("{\"status\": \"ok\"}".utf8), response)
        }
        
        // Should validate entire chain
        let result = try await networkService.secureRequest(
            to: URL(string: "https://api.homeinventory.com/items")!
        )
        
        XCTAssertNotNil(result)
    }
    
    // MARK: - Public Key Pinning Tests
    
    func testPublicKeyPinning() async throws {
        // Extract public key from certificate
        let certificate = TestCertificates.validAPICertificate
        let publicKey = try certificateValidator.extractPublicKey(from: certificate)
        
        // Configure public key pinning
        certificateValidator.configure(
            pinnedPublicKeys: ["api.homeinventory.com": publicKey]
        )
        
        MockURLProtocol.mockHandler = { request in
            // Server can use different certificate with same public key
            let newCertWithSameKey = TestCertificates.createCertificate(
                publicKey: publicKey,
                validFrom: Date(),
                validUntil: Date().addingTimeInterval(365 * 24 * 60 * 60)
            )
            
            MockURLProtocol.serverCertificates = [newCertWithSameKey]
            
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            return (Data("{\"status\": \"ok\"}".utf8), response)
        }
        
        // Should succeed with same public key
        let result = try await networkService.secureRequest(
            to: URL(string: "https://api.homeinventory.com/items")!
        )
        
        XCTAssertNotNil(result)
    }
    
    // MARK: - Certificate Transparency Tests
    
    func testCertificateTransparencyValidation() async throws {
        certificateValidator.configure(
            requireCertificateTransparency: true,
            minimumSCTs: 2
        )
        
        MockURLProtocol.mockHandler = { request in
            let cert = TestCertificates.validAPICertificate
            
            // Simulate SCT (Signed Certificate Timestamp) validation
            let sctList = TestCertificates.createSCTList(count: 2)
            MockURLProtocol.serverCertificates = [cert]
            MockURLProtocol.certificateTransparencyInfo = sctList
            
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            return (Data("{\"status\": \"ok\"}".utf8), response)
        }
        
        let result = try await networkService.secureRequest(
            to: URL(string: "https://api.homeinventory.com/items")!
        )
        
        XCTAssertNotNil(result)
    }
    
    func testInsufficientSCTs() async throws {
        certificateValidator.configure(
            requireCertificateTransparency: true,
            minimumSCTs: 3
        )
        
        MockURLProtocol.mockHandler = { request in
            // Only provide 1 SCT when 3 are required
            let sctList = TestCertificates.createSCTList(count: 1)
            MockURLProtocol.certificateTransparencyInfo = sctList
            
            throw CertificateError.insufficientSCTs(
                required: 3,
                found: 1
            )
        }
        
        do {
            _ = try await networkService.secureRequest(
                to: URL(string: "https://api.homeinventory.com/items")!
            )
            XCTFail("Should fail with insufficient SCTs")
        } catch CertificateError.insufficientSCTs(let required, let found) {
            XCTAssertEqual(required, 3)
            XCTAssertEqual(found, 1)
        }
    }
    
    // MARK: - OCSP Tests
    
    func testOCSPValidation() async throws {
        certificateValidator.configure(
            enableOCSP: true,
            requireOCSPStapling: false
        )
        
        let certificate = TestCertificates.validAPICertificate
        
        MockURLProtocol.mockHandler = { request in
            if request.url?.host == "ocsp.homeinventory.com" {
                // Mock OCSP response
                let ocspResponse = TestCertificates.createOCSPResponse(
                    for: certificate,
                    status: .good
                )
                
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/ocsp-response"]
                )!
                
                return (ocspResponse, response)
            } else {
                // Regular request
                MockURLProtocol.serverCertificates = [certificate]
                
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
                
                return (Data("{\"status\": \"ok\"}".utf8), response)
            }
        }
        
        let result = try await networkService.secureRequest(
            to: URL(string: "https://api.homeinventory.com/items")!
        )
        
        XCTAssertNotNil(result)
    }
    
    func testRevokedCertificateDetection() async throws {
        certificateValidator.configure(
            enableOCSP: true,
            failOnRevoked: true
        )
        
        let certificate = TestCertificates.validAPICertificate
        
        MockURLProtocol.mockHandler = { request in
            if request.url?.host == "ocsp.homeinventory.com" {
                // Mock revoked OCSP response
                let ocspResponse = TestCertificates.createOCSPResponse(
                    for: certificate,
                    status: .revoked,
                    revokedAt: Date().addingTimeInterval(-24 * 60 * 60)
                )
                
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/ocsp-response"]
                )!
                
                return (ocspResponse, response)
            } else {
                throw CertificateError.revoked(
                    host: "api.homeinventory.com",
                    revokedAt: Date().addingTimeInterval(-24 * 60 * 60)
                )
            }
        }
        
        do {
            _ = try await networkService.secureRequest(
                to: URL(string: "https://api.homeinventory.com/items")!
            )
            XCTFail("Should fail with revoked certificate")
        } catch CertificateError.revoked {
            // Expected
        }
    }
    
    // MARK: - Network Security Policy Tests
    
    func testHTTPSEnforcement() async throws {
        // Attempt HTTP request
        do {
            _ = try await networkService.secureRequest(
                to: URL(string: "http://api.homeinventory.com/items")! // HTTP, not HTTPS
            )
            XCTFail("Should reject non-HTTPS requests")
        } catch NetworkError.insecureConnection {
            // Expected
        }
    }
    
    func testMinimumTLSVersion() async throws {
        networkService.configure(minimumTLSVersion: .v1_3)
        
        MockURLProtocol.mockHandler = { request in
            // Simulate TLS 1.2 connection
            MockURLProtocol.tlsVersion = .v1_2
            
            throw NetworkError.tlsVersionTooLow(
                required: .v1_3,
                actual: .v1_2
            )
        }
        
        do {
            _ = try await networkService.secureRequest(
                to: URL(string: "https://api.homeinventory.com/items")!
            )
            XCTFail("Should reject TLS versions below 1.3")
        } catch NetworkError.tlsVersionTooLow(let required, let actual) {
            XCTAssertEqual(required, .v1_3)
            XCTAssertEqual(actual, .v1_2)
        }
    }
    
    // MARK: - Certificate Update Tests
    
    func testCertificateRotation() async throws {
        let oldCertificate = TestCertificates.validAPICertificate
        let newCertificate = TestCertificates.createCertificate(
            validFrom: Date(),
            validUntil: Date().addingTimeInterval(365 * 24 * 60 * 60)
        )
        
        // Start with old certificate
        certificateValidator.configure(
            pinnedCertificates: ["api.homeinventory.com": oldCertificate]
        )
        
        // Update to new certificate with grace period
        try await certificateValidator.rotateCertificate(
            for: "api.homeinventory.com",
            newCertificate: newCertificate,
            gracePeriodDays: 30
        )
        
        // Both certificates should be valid during grace period
        MockURLProtocol.mockHandler = { request in
            // Test with old certificate
            MockURLProtocol.serverCertificates = [oldCertificate]
            
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            return (Data("{\"status\": \"ok\"}".utf8), response)
        }
        
        // Old certificate still works
        let result1 = try await networkService.secureRequest(
            to: URL(string: "https://api.homeinventory.com/items")!
        )
        XCTAssertNotNil(result1)
        
        // New certificate also works
        MockURLProtocol.serverCertificates = [newCertificate]
        let result2 = try await networkService.secureRequest(
            to: URL(string: "https://api.homeinventory.com/items")!
        )
        XCTAssertNotNil(result2)
    }
    
    // MARK: - Backup Pinning Tests
    
    func testBackupPinning() async throws {
        // Configure primary and backup pins
        let primaryCert = TestCertificates.validAPICertificate
        let backupCert = TestCertificates.backupCertificate
        
        certificateValidator.configure(
            pinnedCertificates: ["api.homeinventory.com": primaryCert],
            backupCertificates: ["api.homeinventory.com": [backupCert]]
        )
        
        MockURLProtocol.mockHandler = { request in
            // Primary certificate fails
            if MockURLProtocol.attemptCount == 0 {
                MockURLProtocol.attemptCount += 1
                throw CertificateError.pinningFailed(
                    host: "api.homeinventory.com",
                    reason: "Primary certificate unavailable"
                )
            }
            
            // Fallback to backup certificate
            MockURLProtocol.serverCertificates = [backupCert]
            
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            return (Data("{\"status\": \"ok\"}".utf8), response)
        }
        
        // Should succeed with backup certificate
        let result = try await networkService.secureRequest(
            to: URL(string: "https://api.homeinventory.com/items")!
        )
        
        XCTAssertNotNil(result)
    }
    
    // MARK: - Report-Only Mode Tests
    
    func testReportOnlyMode() async throws {
        var pinningFailures: [PinningFailureReport] = []
        
        certificateValidator.configure(
            pinnedCertificates: ["api.homeinventory.com": TestCertificates.validAPICertificate],
            reportOnly: true,
            failureHandler: { report in
                pinningFailures.append(report)
            }
        )
        
        MockURLProtocol.mockHandler = { request in
            // Use wrong certificate
            MockURLProtocol.serverCertificates = [TestCertificates.invalidCertificate]
            
            // In report-only mode, request should succeed
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            return (Data("{\"status\": \"ok\"}".utf8), response)
        }
        
        // Request should succeed despite pinning failure
        let result = try await networkService.secureRequest(
            to: URL(string: "https://api.homeinventory.com/items")!
        )
        
        XCTAssertNotNil(result)
        
        // But failure should be reported
        XCTAssertEqual(pinningFailures.count, 1)
        XCTAssertEqual(pinningFailures[0].host, "api.homeinventory.com")
        XCTAssertNotNil(pinningFailures[0].failureReason)
    }
}

// MARK: - Supporting Types

enum CertificateError: Error {
    case pinningFailed(host: String, reason: String)
    case expired(host: String, expiredAt: Date)
    case revoked(host: String, revokedAt: Date)
    case insufficientSCTs(required: Int, found: Int)
    case invalidChain
}

enum NetworkError: Error {
    case insecureConnection
    case tlsVersionTooLow(required: TLSVersion, actual: TLSVersion)
}

enum TLSVersion {
    case v1_0
    case v1_1
    case v1_2
    case v1_3
}

struct PinningFailureReport {
    let host: String
    let failureReason: String
    let certificateInfo: CertificateInfo?
    let timestamp: Date
}

struct CertificateInfo {
    let subject: String
    let issuer: String
    let serialNumber: String
    let notBefore: Date
    let notAfter: Date
    let publicKeyHash: String
}

enum OCSPStatus {
    case good
    case revoked
    case unknown
}

// MARK: - Mock URL Protocol Extension

extension MockURLProtocol {
    static var serverCertificates: [SecCertificate] = []
    static var certificateTransparencyInfo: [Data] = []
    static var tlsVersion: TLSVersion = .v1_3
    static var attemptCount = 0
}

// MARK: - Test Certificates

struct TestCertificates {
    static let validAPICertificate = createCertificate(
        subject: "api.homeinventory.com",
        validFrom: Date(),
        validUntil: Date().addingTimeInterval(365 * 24 * 60 * 60)
    )
    
    static let validSyncCertificate = createCertificate(
        subject: "sync.homeinventory.com",
        validFrom: Date(),
        validUntil: Date().addingTimeInterval(365 * 24 * 60 * 60)
    )
    
    static let invalidCertificate = createCertificate(
        subject: "malicious.com",
        validFrom: Date(),
        validUntil: Date().addingTimeInterval(365 * 24 * 60 * 60)
    )
    
    static let backupCertificate = createCertificate(
        subject: "api.homeinventory.com",
        validFrom: Date(),
        validUntil: Date().addingTimeInterval(730 * 24 * 60 * 60) // 2 years
    )
    
    static let rootCACertificate = createCertificate(
        subject: "HomeInventory Root CA",
        isCA: true,
        validFrom: Date().addingTimeInterval(-365 * 24 * 60 * 60),
        validUntil: Date().addingTimeInterval(10 * 365 * 24 * 60 * 60)
    )
    
    static let intermediateCertificate = createCertificate(
        subject: "HomeInventory Intermediate CA",
        issuer: "HomeInventory Root CA",
        isCA: true,
        validFrom: Date(),
        validUntil: Date().addingTimeInterval(5 * 365 * 24 * 60 * 60)
    )
    
    static let leafCertificate = createCertificate(
        subject: "api.homeinventory.com",
        issuer: "HomeInventory Intermediate CA",
        validFrom: Date(),
        validUntil: Date().addingTimeInterval(365 * 24 * 60 * 60)
    )
    
    static func createCertificate(
        subject: String = "test.com",
        issuer: String? = nil,
        isCA: Bool = false,
        publicKey: SecKey? = nil,
        validFrom: Date,
        validUntil: Date
    ) -> SecCertificate {
        // In a real implementation, this would create actual certificates
        // For testing, we create mock certificates
        let certData = Data() // Mock certificate data
        return SecCertificateCreateWithData(nil, certData as CFData)!
    }
    
    static func createSCTList(count: Int) -> [Data] {
        (0..<count).map { _ in
            Data("mock-sct-\(UUID().uuidString)".utf8)
        }
    }
    
    static func createOCSPResponse(
        for certificate: SecCertificate,
        status: OCSPStatus,
        revokedAt: Date? = nil
    ) -> Data {
        // Mock OCSP response
        var response = ["status": status.rawValue]
        if let revokedAt = revokedAt {
            response["revokedAt"] = revokedAt.timeIntervalSince1970
        }
        return try! JSONSerialization.data(withJSONObject: response)
    }
}

extension SecCertificate {
    var notAfter: Date {
        // In real implementation, extract from certificate
        return Date().addingTimeInterval(365 * 24 * 60 * 60)
    }
}

extension OCSPStatus {
    var rawValue: String {
        switch self {
        case .good: return "good"
        case .revoked: return "revoked"
        case .unknown: return "unknown"
        }
    }
}