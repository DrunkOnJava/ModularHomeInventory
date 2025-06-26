//
//  VoiceSearchServiceTests.swift
//  CoreTests
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import XCTest
@testable import Core
import Speech

final class VoiceSearchServiceTests: XCTestCase {
    
    var sut: VoiceSearchService!
    
    override func setUp() {
        super.setUp()
        sut = VoiceSearchService()
    }
    
    override func tearDown() {
        sut.stopRecording()
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNotNil(sut)
        XCTAssertFalse(sut.isRecording)
        XCTAssertTrue(sut.transcribedText.isEmpty)
        XCTAssertNil(sut.error)
        XCTAssertEqual(sut.audioLevel, 0.0)
    }
    
    // MARK: - Authorization Tests
    
    func testRequestAuthorization() {
        let expectation = expectation(description: "Authorization request completes")
        
        sut.requestAuthorization()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Authorization status should be set (actual value depends on system state)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    // MARK: - Recording State Tests
    
    func testStartRecordingWhenNotAuthorized() {
        // Given not authorized
        sut.isAuthorized = false
        
        // When
        XCTAssertThrowsError(try sut.startRecording()) { error in
            // Then
            XCTAssertEqual(error as? VoiceSearchError, .notAuthorized)
        }
        XCTAssertFalse(sut.isRecording)
    }
    
    func testStopRecordingWhenNotRecording() {
        // Given not recording
        XCTAssertFalse(sut.isRecording)
        
        // When
        sut.stopRecording()
        
        // Then
        XCTAssertFalse(sut.isRecording)
        XCTAssertEqual(sut.audioLevel, 0.0)
    }
    
    func testClearTranscription() {
        // Given
        sut.transcribedText = "Test transcription"
        
        // When
        sut.clearTranscription()
        
        // Then
        XCTAssertTrue(sut.transcribedText.isEmpty)
    }
    
    // MARK: - Error Tests
    
    func testVoiceSearchErrorDescriptions() {
        let errors: [VoiceSearchError] = [
            .notAuthorized,
            .authorizationDenied,
            .restricted,
            .notDetermined,
            .recognizerNotAvailable,
            .requestCreationFailed,
            .recognitionFailed("Test failure"),
            .unknown
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
    
    func testVoiceSearchErrorRecoverySuggestions() {
        XCTAssertNotNil(VoiceSearchError.notAuthorized.recoverySuggestion)
        XCTAssertNotNil(VoiceSearchError.authorizationDenied.recoverySuggestion)
        XCTAssertNil(VoiceSearchError.restricted.recoverySuggestion)
    }
    
    // MARK: - Audio Level Tests
    
    func testAudioLevelRange() {
        // Audio level should always be between 0 and 1
        XCTAssertGreaterThanOrEqual(sut.audioLevel, 0.0)
        XCTAssertLessThanOrEqual(sut.audioLevel, 1.0)
    }
}

// MARK: - Mock Tests for CI/CD

extension VoiceSearchServiceTests {
    
    func testMockTranscription() {
        // Simulate transcription update
        let testText = "Show me all electronics"
        sut.transcribedText = testText
        
        XCTAssertEqual(sut.transcribedText, testText)
    }
    
    func testMockRecordingState() {
        // Test recording state changes
        XCTAssertFalse(sut.isRecording)
        
        // Simulate recording start
        sut.isRecording = true
        XCTAssertTrue(sut.isRecording)
        
        // Simulate recording stop
        sut.isRecording = false
        XCTAssertFalse(sut.isRecording)
    }
}