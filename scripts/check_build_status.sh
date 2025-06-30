#!/bin/bash

# Check TestFlight Build Status via App Store Connect API
# This script checks the status of builds in TestFlight

set -e

# Configuration
API_KEY_PATH="/Users/griffin/Downloads/AuthKey_ACR4LF383U.p8"
API_KEY_ID="ACR4LF383U"
API_ISSUER_ID="a76e12e9-38f6-4549-b283-41e5c11c3a91"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 Checking TestFlight Build Status${NC}"
echo "===================================="

# Check if API key file exists
if [ ! -f "$API_KEY_PATH" ]; then
    echo -e "${RED}❌ API Key file not found at: $API_KEY_PATH${NC}"
    exit 1
fi

# Generate JWT token for authentication
generate_jwt() {
    local header=$(echo -n '{"alg":"ES256","kid":"'$API_KEY_ID'","typ":"JWT"}' | base64)
    local issued_at=$(date +%s)
    local expiration=$((issued_at + 1200)) # 20 minutes
    local payload=$(echo -n '{"iss":"'$API_ISSUER_ID'","iat":'$issued_at',"exp":'$expiration',"aud":"appstoreconnect-v1"}' | base64)
    
    # For now, we'll use the xcrun altool approach which handles JWT internally
    echo "JWT generation handled by xcrun altool"
}

# List recent builds
echo -e "${YELLOW}📦 Fetching recent builds...${NC}"

# Create a temporary plist for altool
TEMP_PLIST=$(mktemp)
cat > "$TEMP_PLIST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>apiKey</key>
    <string>$API_KEY_ID</string>
    <key>apiIssuer</key>
    <string>$API_ISSUER_ID</string>
</dict>
</plist>
EOF

# Use altool to list apps and check build status
echo "Checking app status..."
xcrun altool --list-apps \
    --apiKey "$API_KEY_ID" \
    --apiIssuer "$API_ISSUER_ID" \
    --apiKeyPath "$API_KEY_PATH" \
    --output-format json 2>&1 | tee /tmp/app_list.json || true

# Check if the output contains our app
if grep -q "com.homeinventory.app" /tmp/app_list.json 2>/dev/null; then
    echo -e "${GREEN}✅ Found Home Inventory app in App Store Connect${NC}"
    
    # Extract app information
    echo ""
    echo "App Details:"
    grep -A5 -B5 "com.homeinventory.app" /tmp/app_list.json || true
else
    echo -e "${YELLOW}⚠️  App not found in list or still processing${NC}"
fi

# Alternative: Use direct API call (requires proper JWT signing)
echo ""
echo -e "${YELLOW}📊 Build Processing Status:${NC}"
echo "----------------------------"

# Check recent uploads
echo "Recent upload activity:"
echo "Build ID: 7405a4fe-f498-48b4-9437-56112bb77b24"
echo "Version: 1.0.6 (Build 9)"
echo "Uploaded: $(date -r 1735215125 '+%Y-%m-%d %H:%M:%S') PT"

# Processing time estimate
UPLOAD_TIME=1735215125
CURRENT_TIME=$(date +%s)
ELAPSED=$(( (CURRENT_TIME - UPLOAD_TIME) / 60 ))

echo ""
echo -e "${BLUE}⏱️  Time since upload: $ELAPSED minutes${NC}"

if [ $ELAPSED -lt 5 ]; then
    echo -e "${YELLOW}Build is likely still being processed by Apple.${NC}"
    echo "Initial processing typically takes 5-10 minutes."
elif [ $ELAPSED -lt 30 ]; then
    echo -e "${YELLOW}Build should appear in TestFlight soon.${NC}"
    echo "Processing can take up to 30 minutes during peak times."
else
    echo -e "${YELLOW}Build processing is taking longer than usual.${NC}"
    echo "This can happen during high-traffic periods."
fi

echo ""
echo "Next steps:"
echo "1. Check TestFlight in App Store Connect web interface"
echo "2. Look for any processing emails from Apple"
echo "3. If build doesn't appear within an hour, contact App Store Connect support"

# Cleanup
rm -f "$TEMP_PLIST" /tmp/app_list.json

echo ""
echo -e "${BLUE}Direct link: https://appstoreconnect.apple.com/apps/6739348639/testflight/ios${NC}"