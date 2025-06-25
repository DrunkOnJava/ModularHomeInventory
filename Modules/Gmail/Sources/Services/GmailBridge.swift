import Foundation
import SwiftUI
import GoogleSignIn
import Combine

/// Bridge between the old Gmail implementation and the new module structure
public class GmailBridge: ObservableObject {
    @Published public var authService: GmailAuthService
    @Published public var gmailAPI: SimpleGmailAPI
    @Published public var emails: [EmailMessage] = []
    @Published public var isLoading = false
    @Published public var error: Error?
    
    public init() {
        let authService = GmailAuthService()
        self.authService = authService
        self.gmailAPI = SimpleGmailAPI(authService: authService)
        
        // Bind Gmail API changes to bridge
        setupBindings()
    }
    
    private func setupBindings() {
        // Subscribe to Gmail API emails
        gmailAPI.$emails
            .receive(on: DispatchQueue.main)
            .assign(to: &$emails)
        
        gmailAPI.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)
        
        gmailAPI.$error
            .receive(on: DispatchQueue.main)
            .assign(to: &$error)
    }
    
    /// Configure Google Sign-In
    public func configure() {
        // Try to find the bundle containing the resources
        let bundle = Bundle(for: type(of: self))
        
        // First try the module bundle approach
        var resourcePath: String?
        
        #if SWIFT_PACKAGE
        resourcePath = Bundle.module.path(forResource: "GoogleServices", ofType: "plist")
        #else
        // Fallback for non-SPM environments
        resourcePath = bundle.path(forResource: "GoogleServices", ofType: "plist")
        #endif
        
        // If still not found, try main bundle
        if resourcePath == nil {
            resourcePath = Bundle.main.path(forResource: "GoogleServices", ofType: "plist")
        }
        
        guard let path = resourcePath,
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            print("[GmailBridge] Failed to load GoogleServices.plist")
            // Fallback to hardcoded client ID for development
            let fallbackClientId = "316432172622-6huvbn752v0ep68jkfdftrh8fgpesikg.apps.googleusercontent.com"
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: fallbackClientId)
            print("[GmailBridge] Using fallback client ID")
            return
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
        print("[GmailBridge] Configured with client ID: \(clientId.prefix(20))...")
    }
    
    /// Sign in with Google
    public func signIn(presentingViewController: UIViewController) {
        authService.signIn(presentingViewController: presentingViewController)
    }
    
    /// Sign out
    public func signOut() {
        authService.signOut()
    }
    
    /// Fetch receipts from Gmail
    public func fetchReceipts() {
        gmailAPI.fetchReceipts()
    }
    
    /// Convert EmailMessage to GmailMessage for module compatibility
    public func toGmailMessage(_ email: EmailMessage) -> GmailMessage {
        return GmailMessage(
            id: email.id,
            threadId: email.id, // Use same ID for thread
            subject: email.subject,
            from: email.from,
            to: [authService.user?.profile?.email ?? ""],
            date: email.date,
            snippet: email.snippet,
            body: email.body,
            isRead: false,
            labels: []
        )
    }
    
    /// Convert EmailMessage to ParsedReceipt for module compatibility
    public func toParseReceipt(_ email: EmailMessage) -> ParsedReceipt? {
        guard let receiptInfo = email.receiptInfo else { return nil }
        
        let items = receiptInfo.items.map { item in
            ReceiptItem(
                name: item.name,
                quantity: item.quantity,
                unitPrice: item.price.map { Decimal($0) },
                totalPrice: item.price.map { Decimal($0) },
                description: nil,
                sku: nil
            )
        }
        
        return ParsedReceipt(
            messageId: email.id,
            merchant: receiptInfo.retailer,
            date: email.date,
            totalAmount: receiptInfo.totalAmount.map { Decimal($0) },
            currency: "USD",
            items: items,
            orderNumber: receiptInfo.orderNumber,
            paymentMethod: nil,
            shippingAddress: nil,
            trackingNumber: nil
        )
    }
}