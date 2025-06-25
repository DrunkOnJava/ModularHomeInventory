#!/bin/bash

# Script to capture real app screenshots quickly

set -e

echo "📸 Capturing Real App Screenshots"
echo "================================="
echo ""

# Configuration
SIMULATOR_ID="DD192264-DFAA-4582-B2FE-D6FC444C9DDF"
APP_BUNDLE_ID="com.homeinventory.app"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="$PROJECT_DIR/Screenshots"

# Create output directories
mkdir -p "$OUTPUT_DIR/RealApp"

echo "📱 Starting iPhone simulator..."
xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || true
open -a Simulator

echo "🚀 Installing and launching app..."
# Find the app
APP_PATH=$(find "$PROJECT_DIR/build/Build/Products" -name "*.app" -type d | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ App not found. Building first..."
    cd "$PROJECT_DIR"
    make build
    APP_PATH=$(find "$PROJECT_DIR/build/Build/Products" -name "*.app" -type d | head -1)
fi

if [ -n "$APP_PATH" ]; then
    echo "📦 Installing app from: $APP_PATH"
    xcrun simctl install "$SIMULATOR_ID" "$APP_PATH"
    
    echo "🚀 Launching app..."
    xcrun simctl launch "$SIMULATOR_ID" "$APP_BUNDLE_ID"
    
    # Wait for app to launch
    sleep 3
    
    echo "📸 Capturing screenshots..."
    
    # Take a series of screenshots
    for i in {1..5}; do
        echo "  📱 Screenshot $i..."
        xcrun simctl io "$SIMULATOR_ID" screenshot "$OUTPUT_DIR/RealApp/app_screenshot_$i.png"
        
        # Simulate some interaction (tap center of screen)
        xcrun simctl io "$SIMULATOR_ID" spawn tap 200 400
        sleep 1
    done
    
    echo ""
    echo "✅ Real app screenshots captured!"
    echo "📁 Location: $OUTPUT_DIR/RealApp/"
    echo ""
    
    # Show file sizes
    echo "📊 Generated files:"
    ls -lh "$OUTPUT_DIR/RealApp/"*.png
    
    echo ""
    echo "🎯 To capture specific screens:"
    echo "1. Navigate to the screen you want in the simulator"
    echo "2. Run: xcrun simctl io $SIMULATOR_ID screenshot screenshot_name.png"
    
else
    echo "❌ Could not find app bundle"
    exit 1
fi