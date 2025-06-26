//
//  ImportHistoryService.swift
//  Gmail Module
//
//  Apple Configuration:
//  Bundle Identifier: com.homeinventory.app
//  Display Name: Home Inventory
//  Version: 1.0.5
//  Build: 5
//  Deployment Target: iOS 17.0
//  Supported Devices: iPhone & iPad
//  Team ID: 2VXBQV4XC9
//
//  Makefile Configuration:
//  Default Simulator: iPhone 16 Pro Max (DD192264-DFAA-4582-B2FE-D6FC444C9DDF)
//  iPad Simulator: iPad Pro 13-inch (M4) (CE6D038C-840B-4BDB-AA63-D61FA0755C4A)
//  App Bundle ID: com.homeinventory.app
//  Build Path: build/Build/Products/Debug-iphonesimulator/
//
//  Google Sign-In Configuration:
//  Client ID: 316432172622-6huvbn752v0ep68jkfdftrh8fgpesikg.apps.googleusercontent.com
//  URL Scheme: com.googleusercontent.apps.316432172622-6huvbn752v0ep68jkfdftrh8fgpesikg
//  OAuth Scope: https://www.googleapis.com/auth/gmail.readonly
//  Config Files: GoogleSignIn-Info.plist (project root), GoogleServices.plist (Gmail module)
//
//  Key Commands:
//  Build and run: make build run
//  Fast build (skip module prebuild): make build-fast run
//  iPad build and run: make build-ipad run-ipad
//  Clean build: make clean build run
//  Run tests: make test
//
//  Project Structure:
//  Main Target: HomeInventoryModular
//  Test Targets: HomeInventoryModularTests, HomeInventoryModularUITests
//  Swift Version: 5.9 (DO NOT upgrade to Swift 6)
//  Minimum iOS Version: 17.0
//
//  Architecture: Modular SPM packages with local package dependencies
//  Repository: https://github.com/DrunkOnJava/ModularHomeInventory.git
//  Module: Gmail
//  Dependencies: Foundation, Core
//  Testing: GmailTests/ImportHistoryServiceTests.swift
//
//  Description: Service for managing Gmail import history
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation
import Core

/// Service for managing Gmail import history
public class ImportHistoryService: ObservableObject {
    
    // MARK: - Properties
    
    @Published public private(set) var sessions: [ImportSession] = []
    @Published public private(set) var isLoading = false
    
    private let storageKey = "gmail.import.history"
    private let maxSessionsToKeep = 100
    private let userDefaults: UserDefaults
    
    // MARK: - Initialization
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        loadHistory()
    }
    
    // MARK: - Public Methods
    
    /// Start a new import session
    public func startSession(totalEmails: Int) -> ImportSession {
        let session = ImportSession(
            status: .inProgress,
            totalEmails: totalEmails
        )
        
        sessions.insert(session, at: 0)
        saveHistory()
        
        return session
    }
    
    /// Update an existing session
    public func updateSession(
        _ sessionId: UUID,
        endDate: Date? = nil,
        status: ImportStatus? = nil,
        successfulImports: Int? = nil,
        failedImports: Int? = nil,
        newReceipts: [ImportedReceipt] = [],
        newErrors: [ImportErrorRecord] = []
    ) {
        guard let index = sessions.firstIndex(where: { $0.id == sessionId }) else { return }
        
        var session = sessions[index]
        
        session = ImportSession(
            id: session.id,
            startDate: session.startDate,
            endDate: endDate ?? session.endDate,
            status: status ?? session.status,
            totalEmails: session.totalEmails,
            successfulImports: successfulImports ?? session.successfulImports,
            failedImports: failedImports ?? session.failedImports,
            importedReceipts: session.importedReceipts + newReceipts,
            errors: session.errors + newErrors
        )
        
        sessions[index] = session
        saveHistory()
    }
    
    /// Complete a session
    public func completeSession(_ sessionId: UUID, status: ImportStatus = .completed) {
        updateSession(sessionId, endDate: Date(), status: status)
    }
    
    /// Record a successful import
    public func recordSuccessfulImport(
        sessionId: UUID,
        email: EmailMessage,
        receipt: Receipt,
        itemCount: Int
    ) {
        let importedReceipt = ImportedReceipt(
            emailId: email.id,
            emailSubject: email.subject,
            emailDate: email.date,
            retailer: receipt.storeName,
            amount: receipt.totalAmount,
            confidence: receipt.confidence,
            receiptId: receipt.id,
            itemCount: itemCount
        )
        
        guard let index = sessions.firstIndex(where: { $0.id == sessionId }) else { return }
        let currentSuccess = sessions[index].successfulImports
        
        updateSession(
            sessionId,
            successfulImports: currentSuccess + 1,
            newReceipts: [importedReceipt]
        )
    }
    
    /// Record a failed import
    public func recordFailedImport(
        sessionId: UUID,
        email: EmailMessage,
        error: Error
    ) {
        let errorType: ImportErrorType
        let errorMessage: String
        
        // Categorize error
        if let importError = error as? ImportServiceError {
            switch importError {
            case .belowConfidenceThreshold:
                errorType = .lowConfidence
            case .noReceiptDataFound:
                errorType = .parsingError
            default:
                errorType = .unknown
            }
            errorMessage = importError.localizedDescription
        } else {
            errorType = .unknown
            errorMessage = error.localizedDescription
        }
        
        let errorRecord = ImportErrorRecord(
            emailId: email.id,
            emailSubject: email.subject,
            errorType: errorType,
            errorMessage: errorMessage
        )
        
        guard let index = sessions.firstIndex(where: { $0.id == sessionId }) else { return }
        let currentFailures = sessions[index].failedImports
        
        updateSession(
            sessionId,
            failedImports: currentFailures + 1,
            newErrors: [errorRecord]
        )
    }
    
    /// Get statistics for all import history
    public func getStatistics() -> ImportStatistics {
        return ImportStatistics(sessions: sessions)
    }
    
    /// Get statistics for a specific date range
    public func getStatistics(from startDate: Date, to endDate: Date) -> ImportStatistics {
        let filteredSessions = sessions.filter { session in
            session.startDate >= startDate && session.startDate <= endDate
        }
        return ImportStatistics(sessions: filteredSessions)
    }
    
    /// Clear all import history
    public func clearHistory() {
        sessions = []
        saveHistory()
    }
    
    /// Delete a specific session
    public func deleteSession(_ sessionId: UUID) {
        sessions.removeAll { $0.id == sessionId }
        saveHistory()
    }
    
    // MARK: - Private Methods
    
    private func loadHistory() {
        isLoading = true
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self,
                  let data = self.userDefaults.data(forKey: self.storageKey) else {
                DispatchQueue.main.async {
                    self?.isLoading = false
                }
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let loadedSessions = try decoder.decode([ImportSession].self, from: data)
                
                DispatchQueue.main.async {
                    self.sessions = loadedSessions
                    self.isLoading = false
                }
            } catch {
                print("[ImportHistoryService] Failed to load history: \(error)")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func saveHistory() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            do {
                // Keep only the most recent sessions
                let sessionsToSave = Array(self.sessions.prefix(self.maxSessionsToKeep))
                
                let encoder = JSONEncoder()
                let data = try encoder.encode(sessionsToSave)
                
                self.userDefaults.set(data, forKey: self.storageKey)
            } catch {
                print("[ImportHistoryService] Failed to save history: \(error)")
            }
        }
    }
}