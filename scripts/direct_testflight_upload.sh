#!/bin/bash
# Direct TestFlight upload script to bypass Swift 6 package resolution issues

echo "🚀 Direct TestFlight Upload for Home Inventory v1.0.6"
echo "====================================================="

# Configuration
APP_NAME="HomeInventory"
BUNDLE_ID="com.homeinventory.app"
VERSION="1.0.6"
BUILD="7"
TEAM_ID="2VXBQV4XC9"

# Check if we have an existing app to upload
if [ -d "build/Build/Products/Debug-iphonesimulator/HomeInventoryModular.app" ]; then
    echo "✅ Found simulator build"
    APP_PATH="build/Build/Products/Debug-iphonesimulator/HomeInventoryModular.app"
else
    echo "❌ No app found. Please build first with: make build"
    exit 1
fi

echo ""
echo "📱 App Details:"
echo "  Name: $APP_NAME"
echo "  Bundle ID: $BUNDLE_ID"
echo "  Version: $VERSION (Build $BUILD)"
echo "  Team ID: $TEAM_ID"
echo ""

# Create a release build using the simulator app as a base
echo "🔨 Preparing for TestFlight..."
echo ""
echo "⚠️  Note: Due to Swift 6 compatibility issues with the package manager,"
echo "    you'll need to manually upload the app through Xcode:"
echo ""
echo "    1. Open Xcode"
echo "    2. Open HomeInventoryModular.xcodeproj" 
echo "    3. Select 'Any iOS Device' as the destination"
echo "    4. Go to Product > Archive"
echo "    5. Once archived, click 'Distribute App'"
echo "    6. Select 'App Store Connect' > 'Upload'"
echo "    7. Follow the prompts to upload to TestFlight"
echo ""
echo "📄 Release Notes for v1.0.6:"
echo "    - NEW: Professional Insurance Reports"
echo "    - NEW: View-Only Sharing Mode" 
echo "    - Bug fixes and performance improvements"
echo ""
echo "🔗 After upload, check status at:"
echo "    https://appstoreconnect.apple.com"