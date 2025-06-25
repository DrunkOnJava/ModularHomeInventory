#!/bin/bash

# Interactive script to capture different app screens

set -e

echo "📸 Interactive App Screenshot Capture"
echo "===================================="
echo ""

# Configuration
SIMULATOR_ID="DD192264-DFAA-4582-B2FE-D6FC444C9DDF"
APP_BUNDLE_ID="com.homeinventory.app"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="$PROJECT_DIR/Screenshots/RealApp"

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "📱 This script will help you capture different screens of your app."
echo "📋 Instructions:"
echo "   1. Make sure the iOS Simulator is open"
echo "   2. Navigate to the screen you want to capture"
echo "   3. Press ENTER when ready to take a screenshot"
echo "   4. Type 'done' when finished"
echo ""

# Check if simulator is running
if ! pgrep -f "iPhone.*Simulator" > /dev/null; then
    echo "🚀 Starting simulator..."
    xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || true
    open -a Simulator
    sleep 3
fi

# Launch app if not running
echo "🚀 Launching app..."
xcrun simctl launch "$SIMULATOR_ID" "$APP_BUNDLE_ID" 2>/dev/null || echo "App may already be running"

echo ""
echo "✅ Ready to capture screenshots!"
echo ""

# Interactive screenshot capture
screen_counter=1
while true; do
    echo "🎯 Navigate to the screen you want to capture, then press ENTER"
    echo "   (or type 'done' to finish, 'list' to see captured screens)"
    read -r input
    
    case "$input" in
        "done")
            break
            ;;
        "list")
            echo "📋 Captured screens:"
            ls -la "$OUTPUT_DIR"/*.png 2>/dev/null | awk '{print "   - " $9}' || echo "   No screens captured yet"
            echo ""
            continue
            ;;
        *)
            # Capture screenshot
            echo "📸 Capturing screen $screen_counter..."
            
            # Ask for screen name
            echo "📝 Enter a name for this screen (or press ENTER for auto-name):"
            read -r screen_name
            
            if [ -z "$screen_name" ]; then
                filename="screen_$screen_counter.png"
            else
                # Clean filename
                filename=$(echo "$screen_name" | tr ' ' '_' | tr -cd '[:alnum:]_-').png
            fi
            
            # Take screenshot
            if xcrun simctl io "$SIMULATOR_ID" screenshot "$OUTPUT_DIR/$filename"; then
                file_size=$(ls -lh "$OUTPUT_DIR/$filename" | awk '{print $5}')
                echo "   ✅ Saved: $filename ($file_size)"
                screen_counter=$((screen_counter + 1))
            else
                echo "   ❌ Failed to capture screenshot"
            fi
            echo ""
            ;;
    esac
done

echo ""
echo "🎉 Screenshot capture complete!"
echo "📁 Location: $OUTPUT_DIR"
echo ""

# Show summary
echo "📊 Captured screens:"
if ls "$OUTPUT_DIR"/*.png > /dev/null 2>&1; then
    ls -lh "$OUTPUT_DIR"/*.png | while read -r line; do
        echo "   📱 $(echo "$line" | awk '{print $9 " (" $5 ")"}')"
    done
else
    echo "   No screenshots captured"
fi

echo ""
echo "💡 Tips for better screenshots:"
echo "   • Navigate to Settings → Display → Text Size → Use smallest text"
echo "   • Take screenshots of: Items list, Add item, Scanner, Settings, Premium"
echo "   • Use different data in each screen for variety"