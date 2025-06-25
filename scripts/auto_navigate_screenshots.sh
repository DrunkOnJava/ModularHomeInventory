#!/bin/bash

# Automated navigation and screenshot capture

set -e

echo "📸 Automated App Navigation & Screenshots"
echo "========================================"
echo ""

# Configuration
SIMULATOR_ID="DD192264-DFAA-4582-B2FE-D6FC444C9DDF"
APP_BUNDLE_ID="com.homeinventory.app"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="$PROJECT_DIR/Screenshots/RealApp"

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "🚀 Starting automated screenshot capture..."

# Function to take screenshot with name
take_screenshot() {
    local name="$1"
    echo "📸 Capturing: $name"
    xcrun simctl io "$SIMULATOR_ID" screenshot "$OUTPUT_DIR/$name.png"
    sleep 1
}

# Function to tap at coordinates
tap_screen() {
    local x="$1"
    local y="$2"
    echo "👆 Tapping at ($x, $y)"
    xcrun simctl io "$SIMULATOR_ID" spawn tap "$x" "$y" 2>/dev/null || true
    sleep 2
}

# Start the sequence
echo "📱 Taking initial screenshot..."
take_screenshot "01_main_screen"

echo "🧭 Attempting to navigate through app..."

# Try tapping different areas to navigate
echo "   Trying tab navigation..."

# Tap bottom tab bar areas (common positions for tabs)
tap_screen 50 800   # First tab
take_screenshot "02_after_tab1"

tap_screen 150 800  # Second tab
take_screenshot "03_after_tab2"

tap_screen 250 800  # Third tab
take_screenshot "04_after_tab3"

tap_screen 350 800  # Fourth tab
take_screenshot "05_after_tab4"

# Try navigation buttons
echo "   Trying navigation buttons..."

# Top right area (likely + or menu button)
tap_screen 350 100
take_screenshot "06_after_nav_button"

# Back button area (top left)
tap_screen 50 100
take_screenshot "07_after_back_button"

# Center of screen (main content)
tap_screen 200 400
take_screenshot "08_after_content_tap"

# Settings or profile area
tap_screen 350 150
take_screenshot "09_after_settings_tap"

echo ""
echo "✅ Automated screenshot sequence complete!"
echo "📁 Location: $OUTPUT_DIR"

echo ""
echo "📊 Captured screenshots:"
ls -lh "$OUTPUT_DIR"/*.png | while read -r line; do
    filename=$(basename "$(echo "$line" | awk '{print $9}')")
    size=$(echo "$line" | awk '{print $5}')
    echo "   📱 $filename ($size)"
done

echo ""
echo "💡 Next steps:"
echo "   1. Check the screenshots to see which ones show different screens"
echo "   2. Delete duplicates manually"
echo "   3. Use the interactive script for more precise navigation:"
echo "      ./scripts/interactive_screenshots.sh"