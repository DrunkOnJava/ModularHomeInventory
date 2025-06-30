#!/bin/bash

# TestFlight API Direct Upload Script
# Uses App Store Connect API directly

set -e

# Configuration
API_KEY_ID="ACR4LF383U"
API_ISSUER_ID="a76e12e9-38f6-4549-b283-41e5c11c3a91"
API_KEY_PATH="/Users/griffin/Downloads/AuthKey_ACR4LF383U.p8"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 TestFlight Build Status Check${NC}"
echo "================================="

# Check if API key file exists
if [ ! -f "$API_KEY_PATH" ]; then
    echo -e "${RED}❌ API Key file not found at: $API_KEY_PATH${NC}"
    exit 1
fi

# Function to base64 encode for URL
base64url() {
    base64 | tr '+/' '-_' | tr -d '=' | tr -d '\n'
}

# Generate JWT token
generate_jwt() {
    # Header
    local header='{"alg":"ES256","kid":"'$API_KEY_ID'","typ":"JWT"}'
    local header_base64=$(echo -n "$header" | base64url)
    
    # Payload
    local issued_at=$(date +%s)
    local expiration=$((issued_at + 600)) # 10 minutes
    local payload='{"iss":"'$API_ISSUER_ID'","iat":'$issued_at',"exp":'$expiration',"aud":"appstoreconnect-v1"}'
    local payload_base64=$(echo -n "$payload" | base64url)
    
    # Create signature input
    local signing_input="${header_base64}.${payload_base64}"
    
    # Sign with private key
    local signature=$(echo -n "$signing_input" | openssl dgst -sha256 -sign "$API_KEY_PATH" | base64url)
    
    # Return complete JWT
    echo "${signing_input}.${signature}"
}

echo "Generating JWT token..."
JWT_TOKEN=$(generate_jwt)

echo ""
echo -e "${YELLOW}📦 Checking recent builds...${NC}"

# Query builds for our app
APP_ID="6739348639"
BUNDLE_ID="com.homeinventory.app"

# Get app info
echo "Fetching app information..."
curl -s -H "Authorization: Bearer $JWT_TOKEN" \
     "https://api.appstoreconnect.apple.com/v1/apps/$APP_ID" \
     | python3 -m json.tool > /tmp/app_info.json 2>/dev/null || {
    echo -e "${RED}❌ Failed to fetch app information${NC}"
}

# Get builds
echo "Fetching builds..."
curl -s -H "Authorization: Bearer $JWT_TOKEN" \
     "https://api.appstoreconnect.apple.com/v1/builds?filter[app]=$APP_ID&limit=10" \
     | python3 -m json.tool > /tmp/builds.json 2>/dev/null || {
    echo -e "${RED}❌ Failed to fetch builds${NC}"
}

# Check if we have builds
if [ -f /tmp/builds.json ] && grep -q '"data"' /tmp/builds.json; then
    echo -e "${GREEN}✅ Found builds for Home Inventory${NC}"
    echo ""
    
    # Extract build information
    echo "Recent builds:"
    python3 -c "
import json
with open('/tmp/builds.json') as f:
    data = json.load(f)
    for build in data.get('data', []):
        attrs = build.get('attributes', {})
        version = attrs.get('version', 'N/A')
        build_num = attrs.get('buildNumber', 'N/A')
        status = attrs.get('processingState', 'UNKNOWN')
        uploaded = attrs.get('uploadedDate', 'N/A')
        print(f'  Version {version} (Build {build_num}) - Status: {status}')
        print(f'    Uploaded: {uploaded}')
        print()
" 2>/dev/null || echo "Unable to parse build data"
else
    echo -e "${YELLOW}⚠️  No builds found or API error${NC}"
fi

# Check processing status
echo ""
echo -e "${YELLOW}📊 Build 9 Processing Status:${NC}"
echo "------------------------------"
echo "Build ID: 7405a4fe-f498-48b4-9437-56112bb77b24"
echo "Version: 1.0.6 (Build 9)"
echo "Uploaded at: 03:32 AM PT"

# Calculate time elapsed
CURRENT_HOUR=$(date +%H)
CURRENT_MIN=$(date +%M)
UPLOAD_HOUR=3
UPLOAD_MIN=32

# Simple elapsed time calculation
if [ $CURRENT_HOUR -ge $UPLOAD_HOUR ]; then
    ELAPSED_HOURS=$((CURRENT_HOUR - UPLOAD_HOUR))
    ELAPSED_MIN=$((CURRENT_MIN - UPLOAD_MIN))
    if [ $ELAPSED_MIN -lt 0 ]; then
        ELAPSED_MIN=$((ELAPSED_MIN + 60))
        ELAPSED_HOURS=$((ELAPSED_HOURS - 1))
    fi
else
    # Past midnight case
    ELAPSED_HOURS=$((24 - UPLOAD_HOUR + CURRENT_HOUR))
    ELAPSED_MIN=$((CURRENT_MIN - UPLOAD_MIN))
    if [ $ELAPSED_MIN -lt 0 ]; then
        ELAPSED_MIN=$((ELAPSED_MIN + 60))
        ELAPSED_HOURS=$((ELAPSED_HOURS - 1))
    fi
fi

echo ""
echo -e "${BLUE}⏱️  Approximate time since upload: ${ELAPSED_HOURS}h ${ELAPSED_MIN}m${NC}"

if [ $ELAPSED_HOURS -eq 0 ] && [ $ELAPSED_MIN -lt 30 ]; then
    echo -e "${YELLOW}Build should appear in TestFlight soon.${NC}"
    echo "Processing typically takes 5-30 minutes."
else
    echo -e "${YELLOW}Build processing is taking longer than usual.${NC}"
    echo "Check for any processing emails from Apple."
fi

echo ""
echo "Next steps:"
echo "1. Check your email for processing notifications"
echo "2. Visit: https://appstoreconnect.apple.com/apps/$APP_ID/testflight/ios"
echo "3. Once processed, Build 9 will appear in TestFlight"

# Cleanup
rm -f /tmp/app_info.json /tmp/builds.json