# TestFlight Submission Guide for Home Inventory

## Table of Contents
1. [Pre-Submission Checklist](#pre-submission-checklist)
2. [Build Configuration](#build-configuration)
3. [Release Notes](#release-notes)
4. [App Store Connect Setup](#app-store-connect-setup)
5. [Submission Process](#submission-process)
6. [Beta Testing Best Practices](#beta-testing-best-practices)
7. [Troubleshooting](#troubleshooting)

## Pre-Submission Checklist

### ✅ Technical Requirements
- [ ] Swift 5.9 compatibility verified
- [ ] All tests passing
- [ ] No SwiftLint errors
- [ ] Memory leaks checked with Instruments
- [ ] Crash-free on all supported devices
- [ ] Network error handling tested
- [ ] Offline mode functionality verified

### ✅ App Configuration
- [ ] Bundle ID: `com.homeinventory.app`
- [ ] Version: 1.0.6
- [ ] Build: 7
- [ ] Team ID: 2VXBQV4XC9
- [ ] Deployment Target: iOS 17.0
- [ ] Export Compliance: No encryption

### ✅ Content Requirements
- [ ] App icon (1024x1024)
- [ ] Screenshots for all device sizes
- [ ] App description updated
- [ ] What's New section written
- [ ] Keywords optimized
- [ ] Support URL active
- [ ] Privacy policy URL active

## Build Configuration

### Version Numbers
```bash
# Current Configuration
MARKETING_VERSION = 1.0.6
CURRENT_PROJECT_VERSION = 7
```

### Build Settings
```bash
# Optimizations for Release
SWIFT_OPTIMIZATION_LEVEL = -O
DEBUG_INFORMATION_FORMAT = dwarf-with-dsym
ENABLE_BITCODE = NO
STRIP_SWIFT_SYMBOLS = YES
```

## Release Notes

### Version 1.0.6 - What's New

#### 🎯 Major Features
- **Professional Insurance Reports**: Generate comprehensive PDF reports for insurance claims
- **View-Only Sharing Mode**: Share your inventory with family or professionals without edit access
- **Enhanced iPad Experience**: Optimized layouts and keyboard shortcuts
- **Gmail Integration**: Import receipts directly from Gmail

#### 🔧 Improvements
- Faster app launch time
- Reduced memory usage
- Better offline sync reliability
- Enhanced search performance

#### 🐛 Bug Fixes
- Fixed crash when scanning certain barcodes
- Resolved sync conflicts with shared items
- Fixed widget refresh issues
- Corrected currency display in reports

### Beta Testing Notes
Please test the following scenarios:
1. Generate and export an insurance report
2. Share items using view-only mode
3. Import receipts from Gmail
4. Test offline mode thoroughly

## App Store Connect Setup

### 1. App Information
```yaml
App Name: Home Inventory
Subtitle: Track, Organize & Protect
Primary Category: Productivity
Secondary Category: Utilities
Age Rating: 4+
```

### 2. Version Information
```yaml
Version: 1.0.6
Copyright: © 2025 Home Inventory. All rights reserved.
```

### 3. Build Information
```yaml
Build Number: 7
Upload Date: [Automated]
Processing Status: [Check after upload]
```

### 4. Test Information
```yaml
Beta App Description: |
  Home Inventory helps you catalog and protect your belongings.
  
  This beta includes new insurance reporting features and 
  view-only sharing capabilities. Please test thoroughly 
  and report any issues.

Beta App Review Information:
  Email: griffinradcliffe@gmail.com
  Phone: [Your phone]
  Demo Account: demo@homeinventory.app
  Password: TestDemo123!
```

## Submission Process

### Automated Submission Script

Create `/Users/griffin/Projects/ModularHomeInventory/scripts/submit_to_testflight.sh`:

```bash
#!/bin/bash
set -e

echo "🚀 Starting TestFlight Submission Process..."

# Configuration
PROJECT_DIR="/Users/griffin/Projects/ModularHomeInventory"
SCHEME="HomeInventoryModular"
CONFIGURATION="Release"
ARCHIVE_PATH="$HOME/Desktop/HomeInventory.xcarchive"
EXPORT_PATH="$HOME/Desktop/HomeInventoryExport"

# Clean build folder
echo "🧹 Cleaning build folder..."
xcodebuild clean -project "$PROJECT_DIR/HomeInventoryModular.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION"

# Archive
echo "📦 Creating archive..."
TOOLCHAINS=swift-5.9-RELEASE xcodebuild archive \
  -project "$PROJECT_DIR/HomeInventoryModular.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -archivePath "$ARCHIVE_PATH" \
  -destination "generic/platform=iOS" \
  -allowProvisioningUpdates \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM=2VXBQV4XC9

# Export IPA
echo "📱 Exporting IPA..."
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$PROJECT_DIR/ExportOptions.plist" \
  -allowProvisioningUpdates

# Upload to App Store Connect
echo "☁️ Uploading to TestFlight..."
xcrun altool --upload-app \
  -f "$EXPORT_PATH/HomeInventoryModular.ipa" \
  -t ios \
  --apiKey "$APP_STORE_CONNECT_API_KEY_ID" \
  --apiIssuer "$APP_STORE_CONNECT_ISSUER_ID" \
  --verbose

echo "✅ Upload complete! Check App Store Connect for processing status."
```

### Manual Submission Steps

1. **Build and Archive**
   ```bash
   make testflight-build
   ```

2. **Validate Archive**
   ```bash
   xcrun altool --validate-app -f path/to/app.ipa -t ios
   ```

3. **Upload to TestFlight**
   ```bash
   xcrun altool --upload-app -f path/to/app.ipa -t ios
   ```

## Beta Testing Best Practices

### 1. Test Groups
- **Internal Testing**: Development team (up to 100 testers)
- **External Testing**: Beta users (up to 10,000 testers)

### 2. Testing Phases
```yaml
Phase 1 - Internal (1-2 days):
  - Core functionality
  - Crash testing
  - Performance validation

Phase 2 - Limited External (3-5 days):
  - Power users
  - Feature-specific testing
  - Feedback collection

Phase 3 - Broad External (7-14 days):
  - General users
  - Real-world usage
  - Final bug fixes
```

### 3. Feedback Collection
- Use TestFlight feedback
- In-app feedback button
- Crash reporting with Crashlytics
- Analytics with privacy consent

### 4. Beta Expiration
- Builds expire after 90 days
- Send reminder at 80 days
- Plan releases accordingly

## Troubleshooting

### Common Issues

#### Swift Version Error
```bash
error: the manifest is backward-incompatible with Swift < 6.0
```
**Solution**: Ensure swift-tools-version is on first line of Package.swift

#### Code Signing Error
```bash
error: No signing certificate "iOS Distribution" found
```
**Solution**: Check Keychain and Apple Developer account

#### Upload Failed
```bash
error: Failed to upload package
```
**Solution**: Verify API keys and network connection

### Validation Checks

Run before submission:
```bash
# Check for common issues
./scripts/validate_build.sh

# Verify metadata
./scripts/check_metadata.sh

# Test IPA installation
./scripts/test_ipa.sh
```

## Best Practices Summary

1. **Version Management**
   - Increment build number for each upload
   - Use semantic versioning
   - Tag releases in git

2. **Testing Coverage**
   - Test on oldest supported iOS version
   - Test all device sizes
   - Test with poor network conditions

3. **Communication**
   - Clear release notes
   - Respond to beta feedback quickly
   - Set expectations for beta testers

4. **Monitoring**
   - Track crash rates
   - Monitor performance metrics
   - Review user feedback daily

5. **Release Planning**
   - Allow 24-48 hours for review
   - Plan for rejection possibilities
   - Have rollback strategy

## Next Steps

1. Run submission script
2. Monitor App Store Connect
3. Distribute to internal testers
4. Collect and act on feedback
5. Prepare for App Store release

---

For questions or issues, contact: griffinradcliffe@gmail.com