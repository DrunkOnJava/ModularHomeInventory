import Foundation
import SwiftUI
import UIKit
import GoogleSignIn
import Combine

/// Bridge between the old Gmail implementation and the new module structure
public class GmailBridge: ObservableObject {
    @Published public var emails: [EmailMessage] = []
    @Published public var isLoading = false
    @Published public var error: Error?
    @Published public var isAuthenticated = false
    
    public let authService: GmailAuthService
    public let gmailAPI: SimpleGmailAPI
    
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
    
    public func configure() {
        // Configure Google Sign-In if needed
        guard let path = Bundle.main.path(forResource: "GoogleServices", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            print("[GmailBridge] Failed to configure: GoogleServices.plist not found")
            return
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
        print("[GmailBridge] Configured with client ID: \(clientId)")
    }
    
    public func signIn(presentingViewController: UIViewController) {
        authService.signIn(presentingViewController: presentingViewController)
    }
    
    public func fetchReceipts() {
        gmailAPI.fetchReceipts()
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
