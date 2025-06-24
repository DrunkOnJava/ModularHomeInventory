#!/bin/bash

# Fixed Screenshot Capture Script that handles SPM build order issues

set -e

echo "📸 Screenshot Capture (with SPM fix)"
echo "===================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Step 1: Pre-build all modules
echo "🔨 Step 1: Pre-building modules to fix dependency issues..."
./scripts/prebuild_modules.sh

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Module pre-build failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Modules pre-built successfully${NC}"
echo ""

# Step 2: Build the main app
echo "🏗️ Step 2: Building main app..."
xcodebuild build \
    -workspace HomeInventoryModular.xcworkspace \
    -scheme HomeInventoryModular \
    -destination "platform=iOS Simulator,name=iPhone 16 Pro Max" \
    -configuration Debug \
    -derivedDataPath DerivedData \
    SWIFT_SUPPRESS_WARNINGS=YES \
    SWIFT_STRICT_CONCURRENCY=minimal \
    -quiet

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Main app build failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Main app built successfully${NC}"
echo ""

# Step 3: Build UI Tests
echo "🧪 Step 3: Building UI tests..."
xcodebuild build-for-testing \
    -workspace HomeInventoryModular.xcworkspace \
    -scheme HomeInventoryModular \
    -destination "platform=iOS Simulator,name=iPhone 16 Pro Max" \
    -derivedDataPath DerivedData \
    SWIFT_SUPPRESS_WARNINGS=YES \
    SWIFT_STRICT_CONCURRENCY=minimal \
    -quiet

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ UI test build failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ UI tests built successfully${NC}"
echo ""

# Step 4: Run Fastlane Snapshot
echo "📸 Step 4: Capturing screenshots..."
echo ""

# Clean previous screenshots
rm -rf fastlane/screenshots/*

# Run snapshot with derived data path
bundle exec fastlane snapshot \
    --derived_data_path "./DerivedData" \
    --stop_after_first_error false \
    --number_of_retries 1

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Screenshots captured successfully!${NC}"
    echo ""
    echo "📂 View results at: fastlane/screenshots/screenshots.html"
    echo ""
    
    # Ask to open results
    read -p "Open screenshot results? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        open "fastlane/screenshots/screenshots.html"
    fi
else
    echo -e "${RED}❌ Screenshot capture failed${NC}"
    echo ""
    echo "Debug tips:"
    echo "1. Check fastlane/test_output/ for detailed logs"
    echo "2. Try running with --verbose flag"
    echo "3. Ensure simulators are available: xcrun simctl list"
    exit 1
fi