import Foundation
import SwiftUI
import GoogleSignIn
import Combine

/// Bridge between the old Gmail implementation and the new module structure
public class GmailBridge: ObservableObject {
    @Published public var emails: [EmailMessage] = []
    @Published public var isLoading = false
    @Published public var error: Error?
    @Published public var isAuthenticated = false
    
    private let authService: GmailAuthService
    private let gmailAPI: SimpleGmailAPI
    
    public init() {
        let authService = GmailAuthService()
        self.authService = authService
        self.gmailAPI = SimpleGmailAPI(authService: authService)
        
        // Bind authentication state
        self.isAuthenticated = authService.isAuthenticated
    }
    
    public func signOut() {
        authService.signOut()
        emails = []
        isAuthenticated = false
    }
    
    public func checkAuthenticationStatus() {
        isAuthenticated = authService.isAuthenticated
    }
    
    public func fetchReceiptEmails() async throws -> [EmailMessage] {
        return try await withCheckedThrowingContinuation { continuation in
            gmailAPI.fetchReceipts()
            
            // Wait for results
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                if let emails = self?.gmailAPI.emails {
                    continuation.resume(returning: emails)
                } else if let error = self?.gmailAPI.error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: [])
                }
            }
        }
    }
}
