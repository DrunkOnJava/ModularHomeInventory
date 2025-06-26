#!/bin/bash
set -e

# TestFlight Submission using App-Specific Password
echo "🚀 Starting TestFlight submission with app-specific password..."

# Load environment variables
source /Users/griffin/Projects/ModularHomeInventory/.env

# Configuration
PROJECT_DIR="/Users/griffin/Projects/ModularHomeInventory"
ARCHIVE_PATH="$HOME/Desktop/HomeInventory.xcarchive"
EXPORT_PATH="$HOME/Desktop/HomeInventoryExport"

cd "$PROJECT_DIR"

# Step 1: Clean and prepare
echo "🧹 Cleaning build artifacts..."
rm -rf ~/Library/Developer/Xcode/DerivedData/HomeInventoryModular-*
rm -rf "$ARCHIVE_PATH"
rm -rf "$EXPORT_PATH"

# Step 2: Build archive
echo "📦 Building archive with Swift 5.9..."
TOOLCHAINS=swift-5.9-RELEASE xcodebuild archive \
    -project HomeInventoryModular.xcodeproj \
    -scheme HomeInventoryModular \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    -destination "generic/platform=iOS" \
    -allowProvisioningUpdates \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM=2VXBQV4XC9 || {
        echo "❌ Archive failed"
        exit 1
    }

echo "✅ Archive created successfully"

# Step 3: Export IPA
echo "📱 Exporting IPA..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist ExportOptions.plist \
    -allowProvisioningUpdates || {
        echo "❌ Export failed"
        exit 1
    }

echo "✅ IPA exported successfully"

# Step 4: Upload to TestFlight
echo "☁️ Uploading to TestFlight..."
xcrun altool --upload-app \
    -f "$EXPORT_PATH/HomeInventoryModular.ipa" \
    -t ios \
    -u "$FASTLANE_USER" \
    -p "$FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD" \
    --verbose || {
        echo "❌ Upload failed"
        exit 1
    }

echo "✅ Upload complete!"
echo ""
echo "📱 Next steps:"
echo "1. Check App Store Connect for processing status"
echo "2. Once processed, distribute to testers"
echo "3. Monitor feedback in TestFlight"
echo ""
echo "🔗 App Store Connect: https://appstoreconnect.apple.com"