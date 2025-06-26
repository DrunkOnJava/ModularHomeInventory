#!/bin/bash

# Direct TestFlight Upload Script
# This script attempts to build without the problematic Items module

echo "🚀 TestFlight Direct Upload"
echo "=========================="

# Load credentials
source /Users/griffin/Projects/ModularHomeInventory/.env

# Check if we have a previously built IPA
IPA_PATH="$HOME/Desktop/HomeInventoryExport/HomeInventoryModular.ipa"

if [ -f "$IPA_PATH" ]; then
    echo "✅ Found existing IPA at: $IPA_PATH"
    echo "📊 IPA Info:"
    ls -lh "$IPA_PATH"
    
    echo ""
    echo "☁️ Uploading to TestFlight..."
    
    xcrun altool --upload-app \
        -f "$IPA_PATH" \
        -t ios \
        -u "$FASTLANE_USER" \
        -p "$FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD" \
        --verbose
    
    if [ $? -eq 0 ]; then
        echo "✅ Upload successful!"
        echo ""
        echo "📱 Next steps:"
        echo "1. Check App Store Connect for processing (5-30 minutes)"
        echo "2. Once processed, distribute to internal testers"
        echo "3. Monitor feedback"
        echo ""
        echo "🔗 https://appstoreconnect.apple.com"
    else
        echo "❌ Upload failed"
        echo ""
        echo "Troubleshooting:"
        echo "1. Verify credentials in .env"
        echo "2. Check network connection"
        echo "3. Ensure app-specific password is valid"
        echo "4. Try manual upload via Transporter app"
    fi
else
    echo "❌ No IPA found at: $IPA_PATH"
    echo ""
    echo "To create an IPA:"
    echo "1. Open Xcode"
    echo "2. Select Swift 5.9 toolchain (Xcode → Toolchains → Swift 5.9)"
    echo "3. Product → Archive"
    echo "4. Export → App Store Connect → Export"
    echo ""
    echo "Or use GitHub Actions:"
    echo "git push origin main"
fi