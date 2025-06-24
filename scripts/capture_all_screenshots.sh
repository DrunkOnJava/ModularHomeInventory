#!/bin/bash

# Comprehensive Screenshot Capture Script for App Store
# This script captures screenshots of all app views using Fastlane snapshot

set -e

echo "📸 Home Inventory Screenshot Automation"
echo "======================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "Makefile" ]; then
    echo -e "${RED}Error: Must run from project root directory${NC}"
    exit 1
fi

# Function to check prerequisites
check_prerequisites() {
    echo "🔍 Checking prerequisites..."
    
    # Check for Fastlane
    if ! command -v fastlane &> /dev/null; then
        echo -e "${RED}❌ Fastlane not installed${NC}"
        echo "Install with: gem install fastlane"
        exit 1
    fi
    
    # Check for bundle
    if ! command -v bundle &> /dev/null; then
        echo -e "${RED}❌ Bundler not installed${NC}"
        echo "Install with: gem install bundler"
        exit 1
    fi
    
    # Check for required files
    if [ ! -f "fastlane/Snapfile" ]; then
        echo -e "${RED}❌ Snapfile not found${NC}"
        exit 1
    fi
    
    if [ ! -f "HomeInventoryModularUITests/SnapshotHelper.swift" ]; then
        echo -e "${YELLOW}⚠️  SnapshotHelper.swift not found. Initializing...${NC}"
        bundle exec fastlane snapshot init
    fi
    
    echo -e "${GREEN}✅ Prerequisites check passed${NC}"
}

# Function to prepare mock data
prepare_mock_data() {
    echo ""
    echo "📊 Preparing mock data for screenshots..."
    
    # Update AppDelegate or launch arguments to enable mock data
    cat > /tmp/screenshot_launch_args.txt << EOF
-FASTLANE_SNAPSHOT
-DisableAnimations
-MockDataEnabled
-ShowAllFeatures
EOF
    
    echo -e "${GREEN}✅ Mock data prepared${NC}"
}

# Function to clean previous screenshots
clean_screenshots() {
    echo ""
    echo "🧹 Cleaning previous screenshots..."
    
    if [ -d "fastlane/screenshots" ]; then
        rm -rf fastlane/screenshots/*
        echo -e "${GREEN}✅ Previous screenshots cleaned${NC}"
    else
        mkdir -p fastlane/screenshots
        echo -e "${GREEN}✅ Screenshot directory created${NC}"
    fi
}

# Function to build UI test target
build_ui_tests() {
    echo ""
    echo "🔨 Building UI test target..."
    
    xcodebuild build-for-testing \
        -workspace HomeInventoryModular.xcworkspace \
        -scheme HomeInventoryModular \
        -destination "platform=iOS Simulator,name=iPhone 16 Pro Max" \
        -derivedDataPath DerivedData \
        SWIFT_SUPPRESS_WARNINGS=YES \
        SWIFT_STRICT_CONCURRENCY=minimal
    
    echo -e "${GREEN}✅ UI tests built successfully${NC}"
}

# Function to capture screenshots
capture_screenshots() {
    echo ""
    echo "📸 Starting screenshot capture..."
    echo "This will take several minutes as it runs on multiple devices..."
    echo ""
    
    # Run Fastlane snapshot
    bundle exec fastlane snapshot \
        --stop_after_first_error false \
        --concurrent_simulators true \
        --number_of_retries 1 \
        --verbose
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Screenshots captured successfully!${NC}"
    else
        echo -e "${RED}❌ Screenshot capture failed${NC}"
        exit 1
    fi
}

# Function to organize screenshots
organize_screenshots() {
    echo ""
    echo "📁 Organizing screenshots for App Store..."
    
    SCREENSHOT_DIR="fastlane/screenshots"
    OUTPUT_DIR="AppStoreAssets/Screenshots"
    
    mkdir -p "$OUTPUT_DIR"
    
    # Define device mappings
    declare -A DEVICE_FOLDERS=(
        ["iPhone 16 Pro Max"]="iPhone-6.9"
        ["iPhone 15 Pro"]="iPhone-6.1"
        ["iPhone SE (3rd generation)"]="iPhone-4.7"
        ["iPad Pro (12.9-inch) (6th generation)"]="iPad-12.9"
        ["iPad Pro (11-inch) (4th generation)"]="iPad-11"
    )
    
    # Copy and organize screenshots
    for device in "${!DEVICE_FOLDERS[@]}"; do
        device_folder="${DEVICE_FOLDERS[$device]}"
        source_dir="$SCREENSHOT_DIR/en-US"
        
        if [ -d "$source_dir" ]; then
            mkdir -p "$OUTPUT_DIR/$device_folder"
            
            # Find all screenshots for this device
            find "$source_dir" -name "*${device// /-}*" -type f -exec cp {} "$OUTPUT_DIR/$device_folder/" \;
            
            echo -e "${GREEN}✅ Organized screenshots for $device${NC}"
        fi
    done
}

# Function to generate screenshot report
generate_report() {
    echo ""
    echo "📋 Generating screenshot report..."
    
    REPORT_FILE="AppStoreAssets/screenshot_report.md"
    
    cat > "$REPORT_FILE" << EOF
# Screenshot Report
Generated on: $(date)

## Screenshot Inventory

### Required Screenshots Captured:

EOF
    
    # Add screenshot counts
    for dir in AppStoreAssets/Screenshots/*/; do
        if [ -d "$dir" ]; then
            device_name=$(basename "$dir")
            count=$(find "$dir" -name "*.png" | wc -l)
            echo "- **$device_name**: $count screenshots" >> "$REPORT_FILE"
        fi
    done
    
    echo "" >> "$REPORT_FILE"
    echo "## Screenshot Checklist" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "### Main Features:" >> "$REPORT_FILE"
    echo "- [ ] Items List (Home Screen)" >> "$REPORT_FILE"
    echo "- [ ] Item Detail View" >> "$REPORT_FILE"
    echo "- [ ] Add/Edit Item" >> "$REPORT_FILE"
    echo "- [ ] Barcode Scanner" >> "$REPORT_FILE"
    echo "- [ ] Analytics Dashboard" >> "$REPORT_FILE"
    echo "- [ ] Collections" >> "$REPORT_FILE"
    echo "- [ ] Search" >> "$REPORT_FILE"
    echo "- [ ] Settings" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "### Premium Features:" >> "$REPORT_FILE"
    echo "- [ ] Budget Management" >> "$REPORT_FILE"
    echo "- [ ] Insurance Dashboard" >> "$REPORT_FILE"
    echo "- [ ] Warranty Tracking" >> "$REPORT_FILE"
    echo "- [ ] Purchase Patterns" >> "$REPORT_FILE"
    echo "- [ ] Export Options" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "### iPad-Specific:" >> "$REPORT_FILE"
    echo "- [ ] Split View" >> "$REPORT_FILE"
    echo "- [ ] Multi-Column Layout" >> "$REPORT_FILE"
    echo "- [ ] Context Menus" >> "$REPORT_FILE"
    
    echo -e "${GREEN}✅ Report generated at: $REPORT_FILE${NC}"
}

# Function to open results
open_results() {
    echo ""
    echo "🎉 Screenshot capture complete!"
    echo ""
    echo "📂 Screenshots saved to:"
    echo "   - Raw: fastlane/screenshots/"
    echo "   - Organized: AppStoreAssets/Screenshots/"
    echo ""
    
    # Ask if user wants to open the results
    read -p "Would you like to open the screenshot results? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        open "fastlane/screenshots/screenshots.html" 2>/dev/null || open "AppStoreAssets/Screenshots/"
    fi
}

# Main execution
main() {
    echo "🚀 Starting comprehensive screenshot capture..."
    echo ""
    
    # Run all steps
    check_prerequisites
    prepare_mock_data
    clean_screenshots
    build_ui_tests
    capture_screenshots
    organize_screenshots
    generate_report
    open_results
    
    echo ""
    echo "✨ All done! Your screenshots are ready for App Store submission."
    echo ""
    echo "📝 Next steps:"
    echo "1. Review screenshots in AppStoreAssets/Screenshots/"
    echo "2. Edit/enhance screenshots if needed"
    echo "3. Upload to App Store Connect"
    echo "4. Add localized descriptions for each screenshot"
}

# Handle interrupts
trap 'echo -e "\n${RED}Interrupted! Cleaning up...${NC}"; exit 1' INT

# Run main function
main