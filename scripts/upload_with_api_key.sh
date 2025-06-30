#!/bin/bash

# Upload to TestFlight using API Key
# This script uses the new API key for upload

set -e

# Configuration
API_KEY_ID="ACR4LF383U"
API_ISSUER_ID="a76e12e9-38f6-4549-b283-41e5c11c3a91"
API_KEY_PATH="/Users/griffin/Downloads/AuthKey_ACR4LF383U.p8"
IPA_PATH="$HOME/Desktop/HomeInventoryExport_Build10/HomeInventoryModular.ipa"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 TestFlight Upload with API Key${NC}"
echo "===================================="

# Check if IPA exists
if [ ! -f "$IPA_PATH" ]; then
    echo -e "${RED}❌ IPA not found at: $IPA_PATH${NC}"
    echo "Please ensure the app has been exported first."
    exit 1
fi

# Check if API key exists
if [ ! -f "$API_KEY_PATH" ]; then
    echo -e "${RED}❌ API Key not found at: $API_KEY_PATH${NC}"
    exit 1
fi

# Copy API key to expected location
echo "Setting up API key..."
mkdir -p ~/.appstoreconnect/private_keys
cp "$API_KEY_PATH" ~/.appstoreconnect/private_keys/

echo ""
echo -e "${YELLOW}📤 Uploading to TestFlight...${NC}"
echo "IPA: $IPA_PATH"
echo "API Key ID: $API_KEY_ID"
echo ""

# First, let's check what build number is in the IPA
echo "Checking IPA contents..."
unzip -p "$IPA_PATH" Payload/*.app/Info.plist | plutil -p - | grep -E "CFBundleShortVersionString|CFBundleVersion" || true

echo ""
echo "Starting upload..."

# Use altool to upload
xcrun altool --upload-app \
    -f "$IPA_PATH" \
    -t ios \
    --apiKey "$API_KEY_ID" \
    --apiIssuer "$API_ISSUER_ID" \
    --verbose || {
        echo -e "${RED}❌ Upload failed${NC}"
        echo ""
        echo "Alternative: Try using Transporter app manually:"
        echo "1. Open Transporter from /Applications/Transporter.app"
        echo "2. Sign in with Apple ID"
        echo "3. Drag the IPA file: $IPA_PATH"
        echo "4. Click Deliver"
        exit 1
    }

echo ""
echo -e "${GREEN}✅ Upload completed successfully!${NC}"
echo ""
echo "Next steps:"
echo "1. Check App Store Connect in 5-30 minutes"
echo "2. Look for processing email from Apple"
echo "3. Visit: https://appstoreconnect.apple.com/apps/6739348639/testflight/ios"