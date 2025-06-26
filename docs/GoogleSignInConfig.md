# Google Sign-In Configuration for Home Inventory

## Overview
The Gmail module has been successfully integrated into the Home Inventory app. To enable Gmail receipt scanning, you need to configure Google Sign-In.

## Configuration Steps

### 1. Add URL Scheme to Xcode Project

1. Open `HomeInventoryModular.xcodeproj` in Xcode
2. Select your app target
3. Go to the "Info" tab
4. Under "URL Types", add a new URL type:
   - URL Schemes: `com.googleusercontent.apps.316432172622-6huvbn752v0ep68jkfdftrh8fgpesikg`
   - This is the reverse client ID from your GoogleServices.plist

### 2. Add GoogleServices.plist to Main App

The GoogleServices.plist is already included in the Gmail module at:
`Modules/Gmail/Sources/Resources/GoogleServices.plist`

To ensure it's accessible:
1. In Xcode, drag the GoogleServices.plist from the Gmail module to your main app target
2. Make sure "Copy items if needed" is unchecked
3. Add to target: HomeInventoryModular

### 3. Configure Info.plist

Add the following to your app's Info.plist (or in Xcode project settings):

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.316432172622-6huvbn752v0ep68jkfdftrh8fgpesikg</string>
        </array>
    </dict>
</array>
```

### 4. OAuth Configuration

The Gmail module is configured to request read-only access to Gmail for receipt scanning:
- Scope: `https://www.googleapis.com/auth/gmail.readonly`
- Client ID: `316432172622-6huvbn752v0ep68jkfdftrh8fgpesikg.apps.googleusercontent.com`

## Usage

### Accessing Gmail Features

1. **From Receipts Tab**: 
   - Navigate to the Receipts tab
   - Tap "Import" button
   - Select "Gmail" from the import options
   - Sign in with Google if not already authenticated
   - Receipts will be automatically scanned and imported

2. **From Settings**:
   - Go to Settings → Gmail
   - Connect/disconnect Gmail account
   - View connection status and permissions

### Features Included

- **Receipt Scanning**: Automatically detects and parses receipts from:
  - Amazon, Walmart, Target, Apple, Best Buy
  - CVS, Walgreens, and other pharmacies
  - Uber, Lyft (ride sharing)
  - DoorDash, Grubhub (food delivery)
  - Netflix, Spotify, Adobe (subscriptions)
  - Insurance documents
  - Warranty documents

- **Smart Parsing**: Extracts:
  - Merchant name
  - Order numbers
  - Total amounts
  - Individual items (when available)
  - Purchase dates
  - Confidence scores

### Privacy & Security

- The app only accesses emails that match receipt/purchase patterns
- Personal emails are never accessed
- All authentication is handled by Google's secure OAuth flow
- Tokens are stored securely in iOS Keychain
- Users can revoke access at any time through Google account settings

## Troubleshooting

1. **"Not Connected" status**: Tap Gmail in import options to sign in
2. **No receipts found**: Check that you have receipt emails in your Gmail
3. **Authentication errors**: Ensure GoogleServices.plist is properly configured
4. **Build errors**: Make sure to run `make build` to rebuild all modules

## Next Steps

1. Build and run the app: `make build && make run`
2. Test Gmail authentication
3. Import some receipts
4. Verify receipt parsing accuracy