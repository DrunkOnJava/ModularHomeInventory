#!/bin/bash

# Fix Export Compliance Code Issue
# This script removes the export compliance code to let Apple handle it

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Fixing Export Compliance Issue${NC}"
echo "=================================="

# Archive path
ARCHIVE_PATH="$HOME/Desktop/HomeInventory_Build10.xcarchive"
INFO_PLIST="$ARCHIVE_PATH/Products/Applications/HomeInventoryModular.app/Info.plist"

echo "Checking current export compliance settings..."

# Check if archive exists
if [ ! -f "$INFO_PLIST" ]; then
    echo -e "${RED}❌ Archive Info.plist not found${NC}"
    echo "Please ensure the archive exists at: $ARCHIVE_PATH"
    exit 1
fi

# Backup original
cp "$INFO_PLIST" "$INFO_PLIST.backup"
echo "Created backup: $INFO_PLIST.backup"

# Check current settings
echo ""
echo "Current export compliance settings:"
plutil -p "$INFO_PLIST" | grep -E "ITSAppUsesNonExemptEncryption|ITSEncryptionExportComplianceCode" || echo "No export compliance keys found"

# Remove the problematic export compliance code
echo ""
echo -e "${YELLOW}Removing export compliance code...${NC}"

# Remove ITSEncryptionExportComplianceCode if it exists
plutil -remove ITSEncryptionExportComplianceCode "$INFO_PLIST" 2>/dev/null || true

# Set ITSAppUsesNonExemptEncryption to NO
plutil -replace ITSAppUsesNonExemptEncryption -bool NO "$INFO_PLIST" 2>/dev/null || \
plutil -insert ITSAppUsesNonExemptEncryption -bool NO "$INFO_PLIST" 2>/dev/null || true

echo ""
echo "Updated export compliance settings:"
plutil -p "$INFO_PLIST" | grep -E "ITSAppUsesNonExemptEncryption|ITSEncryptionExportComplianceCode" || echo "No export compliance keys found"

echo ""
echo -e "${GREEN}✅ Export compliance fixed!${NC}"
echo ""
echo "Next steps:"
echo "1. Re-export the IPA from the fixed archive"
echo "2. Upload the new IPA to TestFlight"
echo ""
echo "To re-export:"
echo "xcodebuild -exportArchive -archivePath \"$ARCHIVE_PATH\" -exportPath ~/Desktop/HomeInventoryExport_Build10_Fixed -exportOptionsPlist ExportOptionsNoUpload.plist -allowProvisioningUpdates"