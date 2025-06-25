# Gmail Module

A comprehensive Gmail integration module for iOS with OAuth 2.0 authentication, email management, and receipt parsing capabilities.

## Features

- **OAuth 2.0 Authentication**: Secure Google OAuth flow using ASWebAuthenticationSession
- **Email Management**: Fetch, search, read, and delete emails
- **Email Composition**: Send new emails and reply to existing threads
- **Receipt Parsing**: Automatically extract purchase information from receipt emails
- **Token Management**: Automatic token refresh and secure keychain storage
- **SwiftUI Views**: Pre-built views for email list, compose, and receipt display

## Setup

### 1. Google Cloud Console Configuration

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the Gmail API:
   - Navigate to "APIs & Services" > "Library"
   - Search for "Gmail API"
   - Click on it and press "Enable"

### 2. Create OAuth 2.0 Credentials

1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "OAuth client ID"
3. Choose "iOS" as application type
4. Enter your bundle identifier: `com.modularhomeinventory.gmail`
5. Add the redirect URI: `com.modularhomeinventory.gmail:/oauth2redirect`

### 3. Configure OAuth Consent Screen

1. Go to "APIs & Services" > "OAuth consent screen"
2. Fill in required fields
3. Add the following scopes:
   - `https://www.googleapis.com/auth/gmail.readonly`
   - `https://www.googleapis.com/auth/gmail.send`
   - `https://www.googleapis.com/auth/gmail.modify`
   - `https://www.googleapis.com/auth/userinfo.email`
4. Add test users if in development

### 4. iOS App Configuration

Add the following URL scheme to your `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.modularhomeinventory.gmail</string>
        </array>
    </dict>
</array>
```

## Usage

### Initialize the Module

```swift
// Using environment variable
let gmailModule = GmailModule()

// Or with explicit client ID
let gmailModule = GmailModule(clientId: "your-client-id")

// Initialize
try await gmailModule.initialize()
```

### Authenticate

```swift
let success = try await gmailModule.authenticate()
if success {
    print("Successfully authenticated!")
}
```

### Fetch Emails

```swift
// Fetch inbox messages
let messages = try await gmailModule.fetchInboxMessages(maxResults: 20)

// Search emails
let searchResults = try await gmailModule.searchEmails(
    query: "from:amazon.com",
    maxResults: 50
)
```

### Send Email

```swift
try await gmailModule.sendEmail(
    to: "recipient@example.com",
    subject: "Hello from Gmail Module",
    body: "This is a test email."
)
```

### Parse Receipts

```swift
// Fetch and parse receipts
let receipts = try await gmailModule.fetchReceipts(maxResults: 100)

for receipt in receipts {
    print("Merchant: \(receipt.merchant)")
    print("Total: \(receipt.formattedTotal ?? "N/A")")
    print("Date: \(receipt.date)")
}
```

### SwiftUI Integration

```swift
import SwiftUI

struct ContentView: View {
    @StateObject private var gmailModule = GmailModule()
    
    var body: some View {
        TabView {
            GmailView()
                .environmentObject(gmailModule)
                .tabItem {
                    Label("Emails", systemImage: "envelope")
                }
            
            ReceiptListView(module: gmailModule)
                .tabItem {
                    Label("Receipts", systemImage: "doc.text")
                }
        }
    }
}
```

## Architecture

### Core Components

- **OAuth2Service**: Handles Google OAuth authentication flow and token management
- **GmailAPIClient**: Low-level API client for Gmail REST API calls
- **GmailService**: High-level service coordinating OAuth and API operations
- **ReceiptParser**: Intelligent parsing of receipt emails using NLP
- **MessageComposer**: Email composition and formatting utilities

### Security

- Access tokens stored securely in iOS Keychain
- Automatic token refresh before expiration
- State parameter validation for OAuth security
- No credentials stored in plain text

## Receipt Parsing

The module includes intelligent receipt parsing that can extract:

- Merchant name
- Order number
- Total amount and currency
- Individual items with prices
- Payment method
- Shipping address
- Tracking numbers

Supported merchants include Amazon, Apple, Best Buy, Walmart, Target, and more.

## Error Handling

The module provides comprehensive error handling:

```swift
do {
    let messages = try await gmailModule.fetchInboxMessages()
} catch GmailError.notAuthenticated {
    // Handle authentication required
} catch GmailError.networkError(let error) {
    // Handle network issues
} catch GmailError.apiError(let message) {
    // Handle API-specific errors
}
```

## Requirements

- iOS 15.0+
- Swift 5.5+
- Xcode 13.0+

## License

This module is part of the Modular Home Inventory project.