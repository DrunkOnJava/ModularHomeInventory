import Foundation
import GoogleSignIn

public class SimpleGmailAPI: ObservableObject {
    @Published var emails: [EmailMessage] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let baseURL = "https://gmail.googleapis.com/gmail/v1"
    var authService: GmailAuthService
    
    public init(authService: GmailAuthService) {
        self.authService = authService
    }
    
    func fetchReceipts() {
        print("[SimpleGmailAPI] fetchReceipts called")
        guard authService.user != nil else {
            print("[SimpleGmailAPI] No authenticated user")
            self.error = NSError(domain: "GmailAPI", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
            return
        }
        
        print("[SimpleGmailAPI] Starting to fetch emails")
        isLoading = true
        error = nil
        emails = []
        
        // Get access token
        authService.refreshTokenIfNeeded { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let accessToken):
                print("[SimpleGmailAPI] Got access token: \(String(accessToken.prefix(10)))...")
                self.performSearch(accessToken: accessToken)
            case .failure(let error):
                print("[SimpleGmailAPI] Failed to get access token: \(error)")
                DispatchQueue.main.async {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
    
    private func performSearch(accessToken: String) {
        // Query for receipt emails
        let query = "(receipt OR invoice OR order OR purchase OR payment OR \"order confirmation\" OR \"purchase confirmation\" OR \"payment receipt\" OR \"tax invoice\" OR \"billing statement\" OR \"transaction\" OR \"your order\" OR \"order details\" OR \"order summary\") AND (from:amazon OR from:apple OR from:bestbuy OR from:walmart OR from:target OR from:ebay OR from:etsy OR from:homedepot OR from:lowes OR from:costco OR from:sephora OR from:nike OR from:adidas OR from:nordstrom OR from:macys OR from:wayfair OR from:ikea OR from:williams-sonoma OR from:westelm OR from:potterybarn OR from:crateandbarrel OR from:anthropologie OR from:zara OR from:hm OR from:uniqlo OR from:gap OR from:oldnavy OR from:bananarepublic OR from:jcrew OR from:rei OR from:patagonia OR from:northface OR from:columbia OR from:dickssportinggoods OR from:footlocker OR from:finishline OR from:gamestop OR from:steam OR from:playstation OR from:xbox OR from:nintendo OR from:uber OR from:lyft OR from:doordash OR from:grubhub OR from:postmates OR from:instacart OR from:seamless)"
        let urlString = "\(baseURL)/users/me/messages?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&maxResults=50"
        print("[SimpleGmailAPI] Search URL: \(urlString)")
        
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("[SimpleGmailAPI] Network error: \(error)")
                DispatchQueue.main.async {
                    self.error = error
                    self.isLoading = false
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("[SimpleGmailAPI] HTTP Status: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.error = NSError(domain: "GmailAPI", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                    self.isLoading = false
                }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print("[SimpleGmailAPI] Response JSON keys: \(json.keys)")
                    
                    if let error = json["error"] as? [String: Any] {
                        print("[SimpleGmailAPI] API Error: \(error)")
                        throw NSError(domain: "GmailAPI", code: 0, userInfo: [NSLocalizedDescriptionKey: error["message"] as? String ?? "Unknown error"])
                    }
                    
                    if let messages = json["messages"] as? [[String: Any]] {
                        print("[SimpleGmailAPI] Found \(messages.count) messages")
                        
                        // If no messages, add test data for development
                        if messages.isEmpty {
                            print("[SimpleGmailAPI] No messages from API, adding test data")
                            DispatchQueue.main.async {
                                self.emails = self.createTestEmails()
                                self.isLoading = false
                            }
                            return
                        }
                        
                        // Fetch details for each message
                        let group = DispatchGroup()
                        var fetchedEmails: [EmailMessage] = []
                    
                    for message in messages.prefix(20) { // Limit to 20 for demo
                        if let messageId = message["id"] as? String {
                            group.enter()
                            self.fetchMessageDetails(messageId: messageId, accessToken: accessToken) { email in
                                if let email = email {
                                    fetchedEmails.append(email)
                                }
                                group.leave()
                            }
                        }
                    }
                    
                    group.notify(queue: .main) {
                        print("[SimpleGmailAPI] Fetched \(fetchedEmails.count) emails")
                        self.emails = fetchedEmails.sorted { $0.date > $1.date }
                        self.isLoading = false
                    }
                    } else {
                        print("[SimpleGmailAPI] No messages found in response")
                        DispatchQueue.main.async {
                            self.emails = []
                            self.isLoading = false
                        }
                    }
                } else {
                    print("[SimpleGmailAPI] Invalid JSON response")
                    throw NSError(domain: "GmailAPI", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error
                    self.isLoading = false
                }
            }
        }.resume()
    }
    
    private func fetchMessageDetails(messageId: String, accessToken: String, completion: @escaping (EmailMessage?) -> Void) {
        let urlString = "\(baseURL)/users/me/messages/\(messageId)"
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                completion(nil)
                return
            }
            
            // Parse email details
            var subject = ""
            var from = ""
            var body = ""
            var date = Date()
            
            if let payload = json["payload"] as? [String: Any] {
                // Parse headers
                if let headers = payload["headers"] as? [[String: Any]] {
                    for header in headers {
                        if let name = header["name"] as? String,
                           let value = header["value"] as? String {
                            switch name {
                            case "Subject":
                                subject = value
                            case "From":
                                from = value
                            case "Date":
                                if let parsedDate = self.parseEmailDate(value) {
                                    date = parsedDate
                                }
                            default:
                                break
                            }
                        }
                    }
                }
                
                // Parse body
                body = self.extractBody(from: payload) ?? ""
            }
            
            // Parse receipt info
            let parser = ReceiptParser()
            let receiptInfo = parser.parseEmail(subject: subject, from: from, body: body)
            
            let email = EmailMessage(
                id: messageId,
                subject: subject,
                from: from,
                date: date,
                snippet: json["snippet"] as? String ?? "",
                body: body,
                receiptInfo: receiptInfo
            )
            
            completion(email)
        }.resume()
    }
    
    private func extractBody(from payload: [String: Any]) -> String? {
        if let body = payload["body"] as? [String: Any],
           let data = body["data"] as? String {
            return String(data: Data(base64Encoded: data.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")) ?? Data(), encoding: .utf8)
        }
        
        if let parts = payload["parts"] as? [[String: Any]] {
            for part in parts {
                if let mimeType = part["mimeType"] as? String,
                   (mimeType == "text/plain" || mimeType == "text/html") {
                    if let body = part["body"] as? [String: Any],
                       let data = body["data"] as? String {
                        return String(data: Data(base64Encoded: data.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")) ?? Data(), encoding: .utf8)
                    }
                }
            }
        }
        
        return nil
    }
    
    private func parseEmailDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, d MMM yyyy HH:mm:ss Z"
        return formatter.date(from: dateString)
    }
    
    private func createTestEmails() -> [EmailMessage] {
        let parser = ReceiptParser()
        
        // Amazon order
        let amazonSubject = "Your Amazon.com order of \"Sony a7 IV Mirrorless Camera\" has shipped!"
        let amazonFrom = "Amazon.com <ship-confirm@amazon.com>"
        let amazonBody = """
        Order #112-3456789-1234567
        
        Hello,
        Your order has been shipped and is on its way!
        
        Order Details:
        Sony a7 IV Mirrorless Camera Body
        Quantity: 1
        Price: $2,498.00
        
        Shipping & Handling: $0.00
        Tax: $224.82
        Order Total: $2,722.82
        
        Delivery Date: Tuesday, December 27
        """
        
        let amazonReceipt = parser.parseEmail(subject: amazonSubject, from: amazonFrom, body: amazonBody)
        
        let email1 = EmailMessage(
            id: "test1",
            subject: amazonSubject,
            from: amazonFrom,
            date: Date().addingTimeInterval(-86400), // Yesterday
            snippet: "Your order has been shipped! Sony a7 IV Mirrorless Camera Body - $2,498.00...",
            body: amazonBody,
            receiptInfo: amazonReceipt
        )
        
        // Apple Store receipt
        let appleSubject = "Your receipt from Apple Store"
        let appleFrom = "Apple Store <do_not_reply@apple.com>"
        let appleBody = """
        Receipt
        Order Number: W123456789
        
        Thank you for your order.
        
        Items:
        iPad Pro 12.9" (256GB, Space Gray)
        Price: $1,199.00
        
        AppleCare+ for iPad Pro
        Price: $149.00
        
        Subtotal: $1,348.00
        Tax: $121.32
        Total: $1,469.32
        
        Payment Method: •••• 1234
        """
        
        let appleReceipt = parser.parseEmail(subject: appleSubject, from: appleFrom, body: appleBody)
        
        let email2 = EmailMessage(
            id: "test2",
            subject: appleSubject,
            from: appleFrom,
            date: Date().addingTimeInterval(-172800), // 2 days ago
            snippet: "Thank you for your order. iPad Pro 12.9 - $1,199.00...",
            body: appleBody,
            receiptInfo: appleReceipt
        )
        
        // Best Buy receipt
        let bestBuySubject = "Thank you for your Best Buy order"
        let bestBuyFrom = "Best Buy <BestBuyInfo@emailinfo.bestbuy.com>"
        let bestBuyBody = """
        Order Confirmation
        Order Number: BBY01-123456789
        
        Your order has been received!
        
        Items Ordered:
        LG OLED 65" TV
        SKU: 6501902
        Price: $1,799.99
        
        Subtotal: $1,799.99
        Shipping: FREE
        Tax: $161.99
        Total: $1,961.98
        
        Expected Delivery: December 29, 2023
        """
        
        let bestBuyReceipt = parser.parseEmail(subject: bestBuySubject, from: bestBuyFrom, body: bestBuyBody)
        
        let email3 = EmailMessage(
            id: "test3",
            subject: bestBuySubject,
            from: bestBuyFrom,
            date: Date().addingTimeInterval(-259200), // 3 days ago
            snippet: "Your order has been received! LG OLED 65 TV - $1,799.99...",
            body: bestBuyBody,
            receiptInfo: bestBuyReceipt
        )
        
        // Williams Sonoma receipt
        let wsSubject = "Williams Sonoma Order Confirmation"
        let wsFrom = "Williams Sonoma <customerservice@williams-sonoma.com>"
        let wsBody = """
        Order Confirmation
        Order #: WS987654321
        
        Thank you for shopping with Williams Sonoma!
        
        Items:
        KitchenAid Stand Mixer - Pistachio
        Item #: 123456
        Qty: 1
        Price: $449.95
        
        Shipping: $19.95
        Tax: $42.30
        Order Total: $512.20
        
        Estimated Delivery: January 3, 2024
        """
        
        let wsReceipt = parser.parseEmail(subject: wsSubject, from: wsFrom, body: wsBody)
        
        let email4 = EmailMessage(
            id: "test4",
            subject: wsSubject,
            from: wsFrom,
            date: Date().addingTimeInterval(-345600), // 4 days ago
            snippet: "Thank you for shopping! KitchenAid Stand Mixer - $449.95...",
            body: wsBody,
            receiptInfo: wsReceipt
        )
        
        // Microsoft 365 subscription
        let microsoftSubject = "Microsoft 365 subscription renewal"
        let microsoftFrom = "Microsoft <microsoft-noreply@microsoft.com>"
        let microsoftBody = """
        Microsoft 365 Family
        
        Subscription ID: MSO365-789012345
        
        Your subscription has been renewed
        
        Plan: Microsoft 365 Family (up to 6 users)
        Price: $99.99/year
        
        Includes:
        - Word, Excel, PowerPoint, Outlook
        - 1TB OneDrive storage per user
        - Advanced security features
        
        Next billing date: December 22, 2024
        """
        
        let microsoftReceipt = parser.parseEmail(subject: microsoftSubject, from: microsoftFrom, body: microsoftBody)
        
        let email5 = EmailMessage(
            id: "test5",
            subject: microsoftSubject,
            from: microsoftFrom,
            date: Date().addingTimeInterval(-432000), // 5 days ago
            snippet: "Microsoft 365 Family. Your subscription has been renewed. Price: $99.99/year...",
            body: microsoftBody,
            receiptInfo: microsoftReceipt
        )
        
        // YouTube Premium subscription
        let youtubeSubject = "Your YouTube Premium membership receipt"
        let youtubeFrom = "YouTube <noreply@youtube.com>"
        let youtubeBody = """
        YouTube Premium
        
        Thank you for your payment!
        
        Membership: YouTube Premium Individual
        Price: $13.99/month
        
        Benefits:
        - Ad-free videos
        - Background play
        - YouTube Music Premium included
        - Offline downloads
        
        Next billing date: January 22, 2024
        
        Manage your subscription in YouTube settings.
        """
        
        let youtubeReceipt = parser.parseEmail(subject: youtubeSubject, from: youtubeFrom, body: youtubeBody)
        
        let email6 = EmailMessage(
            id: "test6",
            subject: youtubeSubject,
            from: youtubeFrom,
            date: Date().addingTimeInterval(-518400), // 6 days ago
            snippet: "YouTube Premium. Thank you for your payment! Price: $13.99/month...",
            body: youtubeBody,
            receiptInfo: youtubeReceipt
        )
        
        // Disney+ subscription
        let disneySubject = "Your Disney+ subscription receipt"
        let disneyFrom = "Disney+ <disneyplus@mail.disneyplus.com>"
        let disneyBody = """
        Disney+ Subscription Receipt
        
        Account: user@email.com
        
        Disney+ Premium (No Ads)
        Monthly subscription: $13.99
        
        Features:
        - 4K UHD & HDR streaming
        - Up to 4 concurrent streams
        - Unlimited downloads
        - No advertisements
        
        Next billing date: January 23, 2024
        
        Thank you for being a Disney+ subscriber!
        """
        
        let disneyReceipt = parser.parseEmail(subject: disneySubject, from: disneyFrom, body: disneyBody)
        
        let email7 = EmailMessage(
            id: "test7",
            subject: disneySubject,
            from: disneyFrom,
            date: Date().addingTimeInterval(-604800), // 7 days ago
            snippet: "Disney+ Subscription Receipt. Disney+ Premium (No Ads). Monthly: $13.99...",
            body: disneyBody,
            receiptInfo: disneyReceipt
        )
        
        // Dropbox subscription
        let dropboxSubject = "Your Dropbox Plus subscription renewed"
        let dropboxFrom = "Dropbox <no-reply@dropbox.com>"
        let dropboxBody = """
        Dropbox Plus Annual Plan
        
        Thank you for renewing your subscription!
        
        Plan details:
        - 2TB (2,000 GB) of storage
        - Dropbox Passwords
        - Dropbox Vault
        - 30-day file recovery
        
        Annual charge: $119.88
        
        Your subscription will automatically renew on December 22, 2024.
        
        Invoice #: DBX-2023-1234567
        """
        
        let dropboxReceipt = parser.parseEmail(subject: dropboxSubject, from: dropboxFrom, body: dropboxBody)
        
        let email8 = EmailMessage(
            id: "test8",
            subject: dropboxSubject,
            from: dropboxFrom,
            date: Date().addingTimeInterval(-691200), // 8 days ago
            snippet: "Dropbox Plus Annual Plan. Thank you for renewing! Annual charge: $119.88...",
            body: dropboxBody,
            receiptInfo: dropboxReceipt
        )
        
        // LinkedIn Premium subscription
        let linkedinSubject = "Your LinkedIn Premium subscription receipt"
        let linkedinFrom = "LinkedIn <billing-noreply@linkedin.com>"
        let linkedinBody = """
        LinkedIn Premium Career
        
        Thank you for your subscription!
        
        Subscription details:
        - InMail credits: 5 per month
        - See who viewed your profile
        - LinkedIn Learning access
        - Applicant insights
        - Career insights
        
        Monthly subscription: $29.99
        
        Next billing date: January 15, 2024
        
        Order ID: LI-2023-987654
        """
        
        let linkedinReceipt = parser.parseEmail(subject: linkedinSubject, from: linkedinFrom, body: linkedinBody)
        
        let email9 = EmailMessage(
            id: "test9",
            subject: linkedinSubject,
            from: linkedinFrom,
            date: Date().addingTimeInterval(-777600), // 9 days ago
            snippet: "LinkedIn Premium Career. Thank you for your subscription! Monthly: $29.99...",
            body: linkedinBody,
            receiptInfo: linkedinReceipt
        )
        
        // Amazon Prime subscription
        let amazonPrimeSubject = "Your Amazon Prime membership has renewed"
        let amazonPrimeFrom = "Amazon Prime <prime@amazon.com>"
        let amazonPrimeBody = """
        Amazon Prime Membership
        
        Your membership has been renewed.
        
        Membership benefits:
        - FREE Two-Day Shipping
        - Prime Video streaming
        - Prime Music
        - Prime Gaming
        - Whole Foods discounts
        - Prime Reading
        
        Annual membership: $139.00
        
        Next renewal date: December 22, 2024
        
        Manage your membership at amazon.com/prime
        """
        
        let amazonPrimeReceipt = parser.parseEmail(subject: amazonPrimeSubject, from: amazonPrimeFrom, body: amazonPrimeBody)
        
        let email10 = EmailMessage(
            id: "test10",
            subject: amazonPrimeSubject,
            from: amazonPrimeFrom,
            date: Date().addingTimeInterval(-864000), // 10 days ago
            snippet: "Amazon Prime Membership. Your membership has been renewed. Annual: $139.00...",
            body: amazonPrimeBody,
            receiptInfo: amazonPrimeReceipt
        )
        
        return [email1, email2, email3, email4].sorted { $0.date > $1.date }
    }
}