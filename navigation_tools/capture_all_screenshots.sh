#!/bin/bash

# Screenshot Capture Script using xcparse
# This script runs UI tests and extracts all screenshots

echo "📸 Screenshot Capture Tool"
echo "========================"

# Configuration
SCHEME="HomeInventoryModular"
TEST_CLASS="ScreenshotCaptureTests"
OUTPUT_DIR="./screenshots_output"
XCRESULT_PATH="./screenshots.xcresult"

# Clean previous results
echo "🧹 Cleaning previous results..."
rm -rf "$XCRESULT_PATH"
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Device configurations
DEVICES=(
    "iPhone 15 Pro"
    "iPhone 15 Pro Max"
    "iPad Pro (13-inch) (M4)"
)

# Function to run tests for a device
run_tests_for_device() {
    local device="$1"
    local device_safe=$(echo "$device" | tr ' ' '_' | tr '(' '_' | tr ')' '_')
    
    echo ""
    echo "📱 Running tests on: $device"
    echo "================================"
    
    # Run the test
    xcodebuild test \
        -scheme "$SCHEME" \
        -destination "platform=iOS Simulator,name=$device" \
        -only-testing:"HomeInventoryModularUITests/$TEST_CLASS" \
        -resultBundlePath "${XCRESULT_PATH%.xcresult}_${device_safe}.xcresult" \
        -quiet || {
            echo "⚠️  Tests failed for $device, but continuing to extract screenshots..."
        }
    
    # Extract screenshots
    echo "📤 Extracting screenshots for $device..."
    local device_output="$OUTPUT_DIR/$device_safe"
    mkdir -p "$device_output"
    
    xcparse screenshots \
        "${XCRESULT_PATH%.xcresult}_${device_safe}.xcresult" \
        "$device_output" || {
            echo "❌ Failed to extract screenshots for $device"
        }
    
    # Count screenshots
    local count=$(find "$device_output" -name "*.png" -o -name "*.jpg" | wc -l | tr -d ' ')
    echo "✅ Extracted $count screenshots for $device"
}

# Main execution
echo ""
echo "🚀 Starting screenshot capture process..."

# Check if running on specific device or all
if [ "$1" == "--device" ] && [ -n "$2" ]; then
    # Run for specific device
    run_tests_for_device "$2"
else
    # Run for all devices
    for device in "${DEVICES[@]}"; do
        run_tests_for_device "$device"
    done
fi

# Organize screenshots
echo ""
echo "📁 Organizing screenshots..."

# Create organized structure
mkdir -p "$OUTPUT_DIR/organized"
mkdir -p "$OUTPUT_DIR/organized/by_screen"
mkdir -p "$OUTPUT_DIR/organized/by_device"

# Copy and organize by screen name
find "$OUTPUT_DIR" -name "*.png" -o -name "*.jpg" | while read -r file; do
    filename=$(basename "$file")
    screen_name=$(echo "$filename" | sed -E 's/^[0-9]+_//' | sed -E 's/\.[^.]+$//')
    device_name=$(basename "$(dirname "$file")")
    
    # By screen
    mkdir -p "$OUTPUT_DIR/organized/by_screen/$screen_name"
    cp "$file" "$OUTPUT_DIR/organized/by_screen/$screen_name/${device_name}_${filename}"
    
    # By device
    mkdir -p "$OUTPUT_DIR/organized/by_device/$device_name"
    cp "$file" "$OUTPUT_DIR/organized/by_device/$device_name/"
done

# Generate HTML gallery
echo ""
echo "🌐 Generating HTML gallery..."

cat > "$OUTPUT_DIR/gallery.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Screenshot Gallery - Home Inventory App</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
        }
        h1, h2 {
            color: #333;
        }
        .device-section {
            margin-bottom: 40px;
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .screenshot-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            gap: 20px;
            margin-top: 20px;
        }
        .screenshot {
            background: #f9f9f9;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        .screenshot img {
            width: 100%;
            height: auto;
            display: block;
        }
        .screenshot-title {
            padding: 10px;
            font-size: 14px;
            color: #666;
            text-align: center;
        }
    </style>
</head>
<body>
    <h1>📱 Home Inventory App - Screenshot Gallery</h1>
    <p>Generated on: <script>document.write(new Date().toLocaleString());</script></p>
EOF

# Add screenshots to HTML
for device_dir in "$OUTPUT_DIR"/organized/by_device/*/; do
    if [ -d "$device_dir" ]; then
        device_name=$(basename "$device_dir")
        echo "<div class='device-section'>" >> "$OUTPUT_DIR/gallery.html"
        echo "<h2>$device_name</h2>" >> "$OUTPUT_DIR/gallery.html"
        echo "<div class='screenshot-grid'>" >> "$OUTPUT_DIR/gallery.html"
        
        for img in "$device_dir"/*.png "$device_dir"/*.jpg; do
            if [ -f "$img" ]; then
                img_name=$(basename "$img")
                echo "<div class='screenshot'>" >> "$OUTPUT_DIR/gallery.html"
                echo "<img src='organized/by_device/$device_name/$img_name' alt='$img_name'>" >> "$OUTPUT_DIR/gallery.html"
                echo "<div class='screenshot-title'>$img_name</div>" >> "$OUTPUT_DIR/gallery.html"
                echo "</div>" >> "$OUTPUT_DIR/gallery.html"
            fi
        done
        
        echo "</div></div>" >> "$OUTPUT_DIR/gallery.html"
    fi
done

echo "</body></html>" >> "$OUTPUT_DIR/gallery.html"

# Summary
echo ""
echo "📊 Summary"
echo "========="
echo "Output directory: $OUTPUT_DIR"
echo "Gallery: $OUTPUT_DIR/gallery.html"
echo ""
echo "Total screenshots captured:"
find "$OUTPUT_DIR" -name "*.png" -o -name "*.jpg" | wc -l

echo ""
echo "✨ Done! Open $OUTPUT_DIR/gallery.html to view all screenshots"
echo ""
echo "Tips:"
echo "- Use --device \"iPhone 15 Pro\" to capture for a specific device"
echo "- Screenshots are organized by screen and by device"
echo "- The HTML gallery provides an easy way to browse all screenshots"