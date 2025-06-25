import Foundation
import GoogleSignIn
import UIKit

class GmailAuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var user: GIDGoogleUser?
    @Published var error: Error?
    
    private let gmailScope = "https://www.googleapis.com/auth/gmail.readonly"
    
    init() {
        print("[GmailAuthService] Initializing")
        // Check if already signed in
        GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
            DispatchQueue.main.async {
                if let user = user {
                    print("[GmailAuthService] Restored previous sign-in: \(user.profile?.email ?? "unknown")")
                    self?.user = user
                    self?.isAuthenticated = true
                } else if let error = error {
                    print("[GmailAuthService] Failed to restore sign-in: \(error)")
                    self?.error = error
                } else {
                    print("[GmailAuthService] No previous sign-in found")
                }
            }
        }
    }
    
    func signIn(presentingViewController: UIViewController) {
        print("[GmailAuthService] Starting sign-in flow")
        print("[GmailAuthService] Requesting scope: \(gmailScope)")
        
        GIDSignIn.sharedInstance.signIn(
            withPresenting: presentingViewController,
            hint: nil,
            additionalScopes: [gmailScope]
        ) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result = result {
                    print("[GmailAuthService] Sign-in successful: \(result.user.profile?.email ?? "unknown")")
                    print("[GmailAuthService] Granted scopes: \(result.user.grantedScopes ?? [])")
                    self?.user = result.user
                    self?.isAuthenticated = true
                    self?.error = nil
                } else if let error = error {
                    print("[GmailAuthService] Sign-in failed: \(error)")
                    self?.error = error
                    self?.isAuthenticated = false
                }
            }
        }
    }
    
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        DispatchQueue.main.async {
            self.user = nil
            self.isAuthenticated = false
            self.error = nil
        }
    }
    
    func refreshTokenIfNeeded(completion: @escaping (Result<String, Error>) -> Void) {
        guard let user = user else {
            print("[GmailAuthService] No user to refresh token for")
            completion(.failure(AuthError.notAuthenticated))
            return
        }
        
        print("[GmailAuthService] Refreshing tokens if needed")
        user.refreshTokensIfNeeded { [weak self] user, error in
            if let error = error {
                print("[GmailAuthService] Token refresh failed: \(error)")
                completion(.failure(error))
            } else if let accessToken = user?.accessToken.tokenString {
                print("[GmailAuthService] Token refresh successful")
                completion(.success(accessToken))
            } else {
                print("[GmailAuthService] No access token after refresh")
                completion(.failure(AuthError.noAccessToken))
            }
        }
    }
}

enum AuthError: LocalizedError {
    case notAuthenticated
    case noAccessToken
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .noAccessToken:
            return "No access token available"
        }
    }
}