# TestFlight Upload Instructions for v1.0.6

## Current Status

✅ **IPA Created Successfully**: `build/HomeInventoryModular-1.0.6.ipa` (21.92 MB)

❌ **Automated Upload Blocked**: Requires app-specific password

## Manual Upload Options

### Option 1: Transporter App (Recommended)

1. **Open Transporter**:
   ```bash
   open -a Transporter
   ```

2. **Sign In**:
   - Email: `griffinradcliffe@gmail.com`
   - Use your Apple ID password

3. **Upload IPA**:
   - Drag `build/HomeInventoryModular-1.0.6.ipa` to Transporter
   - Click "Deliver"
   - Wait for upload to complete

### Option 2: Configure App-Specific Password

1. **Generate Password**:
   - Go to https://appleid.apple.com
   - Sign in with `griffinradcliffe@gmail.com`
   - Security → App-Specific Passwords
   - Generate new password for "fastlane"

2. **Configure fastlane**:
   ```bash
   export FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx"
   bundle exec fastlane upload_ipa
   ```

### Option 3: Xcode Upload

Despite Swift 6 issues, you can try:

1. **Open Xcode**:
   ```bash
   open HomeInventoryModular.xcodeproj
   ```

2. **Archive**:
   - Product → Archive
   - If package resolution fails, use Option 1 instead

## Release Notes for v1.0.6

```
🎉 Home Inventory v1.0.6

🆕 NEW FEATURES:
• Professional Insurance Reports - Generate comprehensive PDFs for insurance providers
• View-Only Sharing Mode - Share your inventory with privacy controls

✨ IMPROVEMENTS:
• Enhanced iPad split view navigation
• Better performance with large inventories
• Improved sync reliability
• Updated SwiftLint compliance

🐛 BUG FIXES:
• Fixed item price formatting
• Resolved optional date handling
• Corrected CloudKit sync errors
• Improved error handling

Testing Focus:
• Generate insurance reports
• Test view-only sharing
• Verify privacy controls
```

## App Information

- **Bundle ID**: `com.homeinventory.app`
- **Version**: 1.0.6
- **Build**: 7
- **Team ID**: 2VXBQV4XC9
- **Export Compliance**: Uses non-exempt encryption

## After Upload

1. **App Store Connect**:
   - Go to https://appstoreconnect.apple.com
   - Select Home Inventory
   - TestFlight → Manage
   - Add internal testers
   - Submit for review if needed

2. **Testing**:
   - Install TestFlight app on test devices
   - Accept invitation
   - Test new features thoroughly

## Troubleshooting

If upload fails:
- Ensure you're using the correct Apple ID
- Check internet connection
- Verify team membership
- Try again in a few minutes

---

*Note: The automated upload via fastlane requires an app-specific password due to 2FA on the Apple ID.*