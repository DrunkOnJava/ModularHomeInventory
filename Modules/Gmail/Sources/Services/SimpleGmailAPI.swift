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
        // Enhanced query specifically for recurring subscriptions
        let query = "(subscription OR recurring OR renewal OR membership OR \"monthly fee\" OR \"annual fee\" OR \"auto-renewal\" OR \"automatic renewal\" OR \"billing cycle\" OR \"next payment\" OR \"payment due\" OR \"subscription fee\" OR \"membership fee\" OR \"monthly plan\" OR \"annual plan\" OR \"premium plan\" OR \"pro plan\" OR \"plus plan\") AND (from:netflix OR from:spotify OR from:apple OR from:adobe OR from:microsoft OR from:google OR from:amazon OR from:hulu OR from:disney OR from:hbo OR from:paramount OR from:peacock OR from:youtube OR from:dropbox OR from:icloud OR from:onedrive OR from:notion OR from:slack OR from:zoom OR from:linkedin OR from:github OR from:figma OR from:canva OR from:grammarly OR from:duolingo OR from:headspace OR from:calm OR from:peloton OR from:strava OR from:fitbit OR from:myfitnesspal OR from:nytimes OR from:wsj OR from:medium OR from:substack OR from:patreon OR from:twitch OR from:discord OR from:xbox OR from:playstation OR from:nintendo OR from:steam OR from:epic OR from:blizzard OR from:nordvpn OR from:expressvpn OR from:surfshark OR from:dashlane OR from:1password OR from:lastpass OR from:todoist OR from:evernote OR from:asana OR from:monday OR from:salesforce OR from:hubspot OR from:mailchimp OR from:squarespace OR from:wix OR from:shopify OR from:godaddy OR from:namecheap OR from:cloudflare)"
        let urlString = "\(baseURL)/users/me/messages?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&maxResults=100"
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
        
        // Netflix subscription
        let netflixSubject = "Your Netflix monthly subscription"
        let netflixFrom = "Netflix <info@account.netflix.com>"
        let netflixBody = """
        Thank you for your payment
        
        Account ID: NFLX123456789
        
        Netflix Premium Plan
        Monthly charge: $19.99
        
        Next billing date: January 25, 2024
        """
        
        let netflixReceipt = parser.parseEmail(subject: netflixSubject, from: netflixFrom, body: netflixBody)
        
        let email1 = EmailMessage(
            id: "test1",
            subject: netflixSubject,
            from: netflixFrom,
            date: Date().addingTimeInterval(-86400), // Yesterday
            snippet: "Thank you for your payment. Netflix Premium Plan Monthly charge: $19.99...",
            body: netflixBody,
            receiptInfo: netflixReceipt
        )
        
        // Spotify subscription
        let spotifySubject = "Your receipt for Spotify Premium"
        let spotifyFrom = "Spotify <no-reply@spotify.com>"
        let spotifyBody = """
        Receipt for your subscription
        
        Spotify Premium Individual
        
        Billing period: Dec 20, 2023 - Jan 20, 2024
        Amount: $10.99
        
        Payment method: •••• 1234
        
        Your subscription will automatically renew on Jan 20, 2024
        """
        
        let spotifyReceipt = parser.parseEmail(subject: spotifySubject, from: spotifyFrom, body: spotifyBody)
        
        let email2 = EmailMessage(
            id: "test2",
            subject: spotifySubject,
            from: spotifyFrom,
            date: Date().addingTimeInterval(-172800), // 2 days ago
            snippet: "Receipt for your subscription. Spotify Premium Individual. Amount: $10.99...",
            body: spotifyBody,
            receiptInfo: spotifyReceipt
        )
        
        // Adobe Creative Cloud subscription
        let adobeSubject = "Your Adobe Creative Cloud subscription receipt"
        let adobeFrom = "Adobe <mail@mail.adobe.com>"
        let adobeBody = """
        Thank you for your subscription
        
        Adobe Creative Cloud All Apps
        
        Order number: AD2023121234567
        Monthly subscription: $54.99
        
        Billing period: December 22, 2023 - January 22, 2024
        
        Your subscription will automatically renew unless cancelled.
        """
        
        let adobeReceipt = parser.parseEmail(subject: adobeSubject, from: adobeFrom, body: adobeBody)
        
        let email3 = EmailMessage(
            id: "test3",
            subject: adobeSubject,
            from: adobeFrom,
            date: Date().addingTimeInterval(-259200), // 3 days ago
            snippet: "Thank you for your subscription. Adobe Creative Cloud All Apps. Monthly: $54.99...",
            body: adobeBody,
            receiptInfo: adobeReceipt
        )
        
        // Apple iCloud+ subscription
        let appleSubject = "Your receipt from Apple"
        let appleFrom = "Apple <no_reply@email.apple.com>"
        let appleBody = """
        Receipt
        
        SUBSCRIPTION
        
        iCloud+ 200GB
        Monthly subscription
        
        Billed To: Your Apple ID
        Order ID: ML123456789
        
        Amount: $2.99
        
        Renewal Date: January 15, 2024
        
        This subscription will automatically renew unless cancelled.
        """
        
        let appleReceipt = parser.parseEmail(subject: appleSubject, from: appleFrom, body: appleBody)
        
        let email4 = EmailMessage(
            id: "test4",
            subject: appleSubject,
            from: appleFrom,
            date: Date().addingTimeInterval(-345600), // 4 days ago
            snippet: "Receipt - SUBSCRIPTION. iCloud+ 200GB Monthly subscription. Amount: $2.99...",
            body: appleBody,
            receiptInfo: appleReceipt
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
        
        return [email1, email2, email3, email4, email5, email6, email7, email8, email9, email10].sorted { $0.date > $1.date }
    }
}