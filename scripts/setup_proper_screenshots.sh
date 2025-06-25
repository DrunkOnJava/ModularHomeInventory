#!/bin/bash

# Set up proper screenshot capture for the Home Inventory app

set -e

echo "📸 Setting Up Proper App Screenshots"
echo "==================================="
echo ""

# Configuration
SIMULATOR_ID="DD192264-DFAA-4582-B2FE-D6FC444C9DDF"
APP_BUNDLE_ID="com.homeinventory.app"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="$PROJECT_DIR/Screenshots/AppScreens"

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "🎯 This will help you capture actual useful screenshots of your app"
echo ""
echo "📋 Prerequisites:"
echo "   ✅ App should be built and running in simulator"
echo "   ✅ Add some test data to your app first (items, categories, etc.)"
echo "   ✅ Navigate manually to capture different screens"
echo ""

# Check if simulator is running
if ! xcrun simctl list devices | grep "$SIMULATOR_ID" | grep -q "Booted"; then
    echo "🚀 Starting simulator..."
    xcrun simctl boot "$SIMULATOR_ID"
    open -a Simulator
    echo "⏳ Waiting for simulator to start..."
    sleep 5
fi

# Check if app is installed and launch it
echo "📱 Launching Home Inventory app..."
if xcrun simctl launch "$SIMULATOR_ID" "$APP_BUNDLE_ID" 2>/dev/null; then
    echo "✅ App launched successfully"
else
    echo "❌ Could not launch app. Building and installing..."
    cd "$PROJECT_DIR"
    make build
    
    # Find and install the app
    APP_PATH=$(find "$PROJECT_DIR/build/Build/Products" -name "*.app" -type d | head -1)
    if [ -n "$APP_PATH" ]; then
        xcrun simctl install "$SIMULATOR_ID" "$APP_PATH"
        xcrun simctl launch "$SIMULATOR_ID" "$APP_BUNDLE_ID"
        echo "✅ App installed and launched"
    else
        echo "❌ Could not find app bundle"
        exit 1
    fi
fi

echo ""
echo "🎯 Now follow these steps to capture useful screenshots:"
echo ""
echo "1️⃣ MAIN SCREENS TO CAPTURE:"
echo "   📋 Items List (main screen)"
echo "   ➕ Add Item screen"
echo "   📱 Barcode Scanner"
echo "   📄 Item Details"
echo "   🧾 Receipts"
echo "   📊 Analytics/Statistics"
echo "   ⚙️  Settings"
echo "   💎 Premium features"
echo ""

echo "2️⃣ FOR EACH SCREEN:"
echo "   a) Navigate to the screen in the simulator"
echo "   b) Press ENTER to capture"
echo "   c) Type a descriptive name"
echo ""

# Function to capture a specific screen
capture_screen() {
    local default_name="$1"
    local description="$2"
    
    echo "📱 $description"
    echo "   Navigate to this screen, then press ENTER..."
    read -r
    
    echo "📝 Enter filename (or press ENTER for '$default_name'):"
    read -r custom_name
    
    if [ -z "$custom_name" ]; then
        filename="$default_name"
    else
        filename=$(echo "$custom_name" | tr ' ' '_' | tr -cd '[:alnum:]_-')
    fi
    
    if xcrun simctl io "$SIMULATOR_ID" screenshot "$OUTPUT_DIR/${filename}.png"; then
        file_size=$(ls -lh "$OUTPUT_DIR/${filename}.png" | awk '{print $5}')
        echo "   ✅ Captured: ${filename}.png ($file_size)"
        echo ""
    else
        echo "   ❌ Failed to capture screenshot"
        echo ""
    fi
}

# Guide through capturing each important screen
echo "🎬 Starting guided screenshot capture..."
echo ""

capture_screen "01_items_list" "📋 ITEMS LIST - Main screen showing your inventory items"
capture_screen "02_add_item" "➕ ADD ITEM - Screen for adding new items (tap + button)"
capture_screen "03_barcode_scanner" "📱 BARCODE SCANNER - Camera/scanner view"
capture_screen "04_item_detail" "📄 ITEM DETAIL - Detailed view of a single item"
capture_screen "05_receipts" "🧾 RECEIPTS - Receipts management screen"
capture_screen "06_analytics" "📊 ANALYTICS - Statistics and analytics view"
capture_screen "07_settings" "⚙️ SETTINGS - App settings and preferences"
capture_screen "08_premium" "💎 PREMIUM - Premium features screen"

echo "🎉 Screenshot capture complete!"
echo ""

# Show results
echo "📊 Captured Screenshots:"
if ls "$OUTPUT_DIR"/*.png > /dev/null 2>&1; then
    total_size=$(du -sh "$OUTPUT_DIR" | cut -f1)
    count=$(ls -1 "$OUTPUT_DIR"/*.png | wc -l | tr -d ' ')
    echo "   📱 Total: $count screenshots ($total_size)"
    echo ""
    ls -lh "$OUTPUT_DIR"/*.png | while read -r line; do
        filename=$(basename "$(echo "$line" | awk '{print $9}')")
        size=$(echo "$line" | awk '{print $5}')
        echo "   📸 $filename ($size)"
    done
else
    echo "   ❌ No screenshots captured"
fi

echo ""
echo "📁 Screenshots saved to: $OUTPUT_DIR"
echo ""
echo "💡 Tips for better screenshots:"
echo "   • Add sample data to your app first"
echo "   • Use realistic item names and prices"
echo "   • Fill in some categories and locations"
echo "   • Take screenshots with different content visible"
echo "   • Consider both light and dark mode"
echo ""
echo "🔄 To capture more screens:"
echo "   ./scripts/setup_proper_screenshots.sh"