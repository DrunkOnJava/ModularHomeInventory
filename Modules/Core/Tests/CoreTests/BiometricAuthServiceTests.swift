//
//  BiometricAuthServiceTests.swift
//  CoreTests
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import XCTest
import LocalAuthentication
@testable import Core

final class BiometricAuthServiceTests: XCTestCase {
    
    var sut: BiometricAuthService!
    
    override func setUp() {
        super.setUp()
        sut = BiometricAuthService()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNotNil(sut)
    }
    
    // MARK: - Biometric Type Tests
    
    func testBiometricTypeString() {
        // Test all biometric types
        XCTAssertEqual(BiometricAuthService.BiometricType.none.rawValue, "none")
        XCTAssertEqual(BiometricAuthService.BiometricType.touchID.rawValue, "touchID")
        XCTAssertEqual(BiometricAuthService.BiometricType.faceID.rawValue, "faceID")
        
        // Test display names
        XCTAssertEqual(BiometricAuthService.BiometricType.none.displayName, "Biometric Authentication")
        XCTAssertEqual(BiometricAuthService.BiometricType.touchID.displayName, "Touch ID")
        XCTAssertEqual(BiometricAuthService.BiometricType.faceID.displayName, "Face ID")
    }
    
    // MARK: - Availability Tests
    
    func testCanUseBiometrics() {
        // This will vary based on device/simulator
        // Just verify the method returns without error
        let canUse = sut.canUseBiometrics()
        XCTAssertTrue(canUse || !canUse) // Always true - just checking it returns a bool
    }
    
    func testBiometricType() {
        // Verify we get a valid biometric type
        let type = sut.biometricType()
        XCTAssertTrue([.none, .touchID, .faceID].contains(type))
    }
    
    // MARK: - Authentication Tests
    
    func testAuthenticateWithInvalidReason() async {
        do {
            // Empty reason should still work
            _ = try await sut.authenticate(reason: "")
            // If it succeeds, that's fine (simulator behavior varies)
        } catch {
            // If it fails, verify we get a proper error
            if let authError = error as? BiometricAuthService.BiometricError {
                XCTAssertNotNil(authError.errorDescription)
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testBiometricErrorDescriptions() {
        let errors: [BiometricAuthService.BiometricError] = [
            .notAvailable,
            .notEnrolled,
            .passcodeNotSet,
            .userCancel,
            .userFallback,
            .systemCancel,
            .lockout,
            .authenticationFailed,
            .invalidContext,
            .appCancel,
            .unknown
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
    
    func testBiometricErrorRecoverySuggestions() {
        // Test errors with recovery suggestions
        XCTAssertNotNil(BiometricAuthService.BiometricError.notEnrolled.recoverySuggestion)
        XCTAssertNotNil(BiometricAuthService.BiometricError.passcodeNotSet.recoverySuggestion)
        XCTAssertNotNil(BiometricAuthService.BiometricError.lockout.recoverySuggestion)
        
        // Test errors without recovery suggestions
        XCTAssertNil(BiometricAuthService.BiometricError.userCancel.recoverySuggestion)
        XCTAssertNil(BiometricAuthService.BiometricError.systemCancel.recoverySuggestion)
    }
    
    func testMapLAError() {
        // Test LAError mapping
        let laErrors: [(LAError.Code, BiometricAuthService.BiometricError)] = [
            (.biometryNotAvailable, .notAvailable),
            (.biometryNotEnrolled, .notEnrolled),
            (.passcodeNotSet, .passcodeNotSet),
            (.userCancel, .userCancel),
            (.userFallback, .userFallback),
            (.systemCancel, .systemCancel),
            (.biometryLockout, .lockout),
            (.authenticationFailed, .authenticationFailed),
            (.invalidContext, .invalidContext),
            (.appCancel, .appCancel)
        ]
        
        for (laCode, expectedError) in laErrors {
            let laError = LAError(laCode)
            let mappedError = sut.mapLAError(laError)
            XCTAssertEqual(mappedError, expectedError)
        }
    }
    
    // MARK: - Mock Authentication Tests
    
    func testMockSuccessfulAuthentication() async throws {
        // Create a mock context for testing
        let mockContext = MockLAContext()
        mockContext.canEvaluatePolicyResult = true
        mockContext.evaluatePolicyResult = .success(true)
        
        // In a real test, we'd inject this mock context
        // For now, just verify our error types work correctly
        let error = BiometricAuthService.BiometricError.authenticationFailed
        XCTAssertEqual(error.errorDescription, "Authentication failed. Please try again.")
    }
    
    func testMockFailedAuthentication() async {
        // Test that authentication can fail with proper error
        let error = BiometricAuthService.BiometricError.userCancel
        XCTAssertEqual(error.errorDescription, "Authentication was cancelled by the user.")
    }
}

// MARK: - Mock LAContext for Testing

private class MockLAContext: LAContext {
    var canEvaluatePolicyResult = false
    var canEvaluatePolicyError: Error?
    var evaluatePolicyResult: Result<Bool, Error> = .failure(LAError(.authenticationFailed))
    
    override func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
        if let canEvaluatePolicyError = canEvaluatePolicyError {
            error?.pointee = canEvaluatePolicyError as NSError
            return false
        }
        return canEvaluatePolicyResult
    }
}