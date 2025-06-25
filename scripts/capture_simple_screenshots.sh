#!/bin/bash

# Simple script to capture app screenshots

set -e

echo "📸 Capturing App Screenshots"
echo "============================="

# Configuration
SIMULATOR_ID="DD192264-DFAA-4582-B2FE-D6FC444C9DDF"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="$PROJECT_DIR/Screenshots/RealApp"

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "📱 Taking screenshots from running app..."

# Take multiple screenshots with delays
for i in {1..8}; do
    echo "  📱 Screenshot $i..."
    xcrun simctl io "$SIMULATOR_ID" screenshot "$OUTPUT_DIR/app_screen_$i.png"
    sleep 2
done

echo ""
echo "✅ Screenshots captured!"
echo "📁 Location: $OUTPUT_DIR"

# Show results
echo ""
echo "📊 Generated files:"
ls -lh "$OUTPUT_DIR"/*.png

echo ""
echo "🎯 Manual instructions:"
echo "1. Navigate through the app in the simulator"
echo "2. Run this script again to capture more screens"
echo "3. Or take individual screenshots with:"
echo "   xcrun simctl io $SIMULATOR_ID screenshot my_screen.png"