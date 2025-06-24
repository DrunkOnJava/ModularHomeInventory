#!/bin/bash

# Screenshot Generation Script for App Store
# This script helps capture screenshots for all required device sizes

echo "📸 App Store Screenshot Generator"
echo "================================"
echo ""
echo "This script will help you capture screenshots for App Store submission."
echo ""

# Define device configurations
declare -A DEVICES=(
    ["iPhone 15 Pro Max"]="iPhone 6.7 inch"
    ["iPhone 15 Pro"]="iPhone 6.1 inch"  
    ["iPhone SE (3rd generation)"]="iPhone 4.7 inch"
    ["iPad Pro (12.9-inch) (6th generation)"]="iPad Pro 12.9 inch"
    ["iPad Pro (11-inch) (4th generation)"]="iPad Pro 11 inch"
)

# Create screenshots directory
SCREENSHOT_DIR="./AppStoreAssets/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

echo "📱 Available simulators for screenshots:"
echo ""

# List available simulators
xcrun simctl list devices | grep -E "iPhone|iPad" | grep -v "unavailable"

echo ""
echo "🎯 Required screenshots for App Store:"
echo ""
echo "1. iPhone 6.7\" (1290 × 2796) - iPhone 15 Pro Max"
echo "2. iPhone 6.5\" (1242 × 2688) - iPhone 11 Pro Max" 
echo "3. iPhone 5.5\" (1242 × 2208) - iPhone 8 Plus"
echo "4. iPad Pro 12.9\" (2048 × 2732)"
echo "5. iPad Pro 11\" (1668 × 2388)"
echo ""

# Function to capture screenshot
capture_screenshot() {
    local device_name="$1"
    local screenshot_name="$2"
    local device_id=$(xcrun simctl list devices | grep "$device_name" | grep -v "unavailable" | head -1 | awk -F'[()]' '{print $2}')
    
    if [ -z "$device_id" ]; then
        echo "❌ Device '$device_name' not found"
        return 1
    fi
    
    echo "📸 Capturing screenshot on $device_name..."
    
    # Boot device if needed
    xcrun simctl boot "$device_id" 2>/dev/null || true
    
    # Wait for device to boot
    sleep 3
    
    # Launch app
    xcrun simctl launch "$device_id" "com.homeinventory.app"
    
    # Wait for app to load
    sleep 2
    
    # Capture screenshot
    xcrun simctl io "$device_id" screenshot "$SCREENSHOT_DIR/${screenshot_name}.png"
    
    echo "✅ Screenshot saved: $SCREENSHOT_DIR/${screenshot_name}.png"
}

# Suggested screenshot scenarios
echo "📋 Suggested screenshots to capture:"
echo ""
echo "1. Home/Items List - Show main inventory"
echo "2. Item Detail - Show rich item information"
echo "3. Barcode Scanner - Show scanning in action"
echo "4. Analytics Dashboard - Show insights"
echo "5. Collections - Show organization features"
echo "6. Search - Show powerful search"
echo ""

echo "🚀 To capture screenshots manually:"
echo ""
echo "1. Open Simulator"
echo "2. Select device from Device menu"
echo "3. Run: make run"
echo "4. Navigate to desired screen"
echo "5. Press Cmd+S to save screenshot"
echo ""

echo "🤖 To use Fastlane snapshot (automated):"
echo ""
echo "1. Run: bundle exec fastlane snapshot"
echo ""

# Create App Store asset directories
mkdir -p "$SCREENSHOT_DIR/iPhone-6.7"
mkdir -p "$SCREENSHOT_DIR/iPhone-6.5"
mkdir -p "$SCREENSHOT_DIR/iPhone-5.5"
mkdir -p "$SCREENSHOT_DIR/iPad-Pro-12.9"
mkdir -p "$SCREENSHOT_DIR/iPad-Pro-11"

echo "✅ Screenshot directories created in: $SCREENSHOT_DIR"
echo ""
echo "📝 Next steps:"
echo "1. Capture screenshots for each device size"
echo "2. Name them descriptively (e.g., 01_ItemsList.png)"
echo "3. Edit/enhance in image editor if needed"
echo "4. Upload to App Store Connect"

# Make script executable
chmod +x "$0"