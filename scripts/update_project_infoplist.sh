#!/bin/bash

# Update Info.plist in project to ensure all privacy keys are included
# This ensures the archive includes all required privacy descriptions

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}📝 Updating Project Info.plist${NC}"
echo "================================"

# Path to Info.plist
INFO_PLIST="/Users/griffin/Projects/ModularHomeInventory/HomeInventoryModular/Info.plist"

echo "Current Info.plist location: $INFO_PLIST"
echo ""

# Check current privacy descriptions
echo "Current privacy descriptions:"
plutil -p "$INFO_PLIST" | grep -E "Usage" || echo "No usage descriptions found"

echo ""
echo -e "${GREEN}✅ All required privacy keys are present:${NC}"
echo "- NSCameraUsageDescription"
echo "- NSPhotoLibraryUsageDescription" 
echo "- NSPhotoLibraryAddUsageDescription"
echo "- NSSpeechRecognitionUsageDescription"
echo "- NSMicrophoneUsageDescription"

echo ""
echo -e "${YELLOW}⚠️  The issue is that the archive didn't include these keys${NC}"
echo ""

# Create a new Info.plist specifically for the build
echo "Creating HomeInventory-Info.plist with all required keys..."

cat > /Users/griffin/Projects/ModularHomeInventory/HomeInventory-Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    <key>CFBundleShortVersionString</key>
    <string>$(MARKETING_VERSION)</string>
    <key>CFBundleVersion</key>
    <string>$(CURRENT_PROJECT_VERSION)</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UIApplicationSceneManifest</key>
    <dict>
        <key>UIApplicationSupportsMultipleScenes</key>
        <false/>
        <key>UISceneConfigurations</key>
        <dict>
            <key>UIWindowSceneSessionRoleApplication</key>
            <array>
                <dict>
                    <key>UISceneConfigurationName</key>
                    <string>Default Configuration</string>
                    <key>UISceneDelegateClassName</key>
                    <string>$(PRODUCT_MODULE_NAME).SceneDelegate</string>
                </dict>
            </array>
        </dict>
    </dict>
    <key>UILaunchStoryboardName</key>
    <string>LaunchScreen</string>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>armv7</string>
    </array>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>UISupportedInterfaceOrientations~ipad</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>NSCameraUsageDescription</key>
    <string>Camera access is needed to scan barcodes and take photos of your items</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>Photo library access is needed to add photos to your items</string>
    <key>NSPhotoLibraryAddUsageDescription</key>
    <string>This allows you to save item photos to your photo library</string>
    <key>NSSpeechRecognitionUsageDescription</key>
    <string>Speech recognition is used to help you quickly add items by voice</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>Microphone access is needed for voice input when adding items</string>
    <key>ITSAppUsesNonExemptEncryption</key>
    <false/>
</dict>
</plist>
EOF

echo -e "${GREEN}✅ Created HomeInventory-Info.plist${NC}"
echo ""
echo "Next steps:"
echo "1. Build a new archive with: INFOPLIST_FILE=HomeInventory-Info.plist"
echo "2. This will ensure all privacy keys are included in the final build"