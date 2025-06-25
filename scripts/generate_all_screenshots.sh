#!/bin/bash

# Script to generate all screenshots using both ImageRenderer and XCUITest approaches

set -e

echo "📸 Home Inventory Screenshot Generation"
echo "======================================"
echo ""

# Configuration
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="$PROJECT_DIR/Screenshots"
SIMULATOR_ID="${SIMULATOR_ID:-DD192264-DFAA-4582-B2FE-D6FC444C9DDF}"

# Create output directories
mkdir -p "$OUTPUT_DIR/Components"
mkdir -p "$OUTPUT_DIR/AppFlow"
mkdir -p "$OUTPUT_DIR/AppStore"

echo "📁 Output directory: $OUTPUT_DIR"
echo ""

# Step 1: Run Unit Tests for Component Screenshots
echo "1️⃣ Generating component screenshots with ImageRenderer..."
echo "--------------------------------------------------------"

xcodebuild test \
    -project "$PROJECT_DIR/HomeInventoryModular.xcodeproj" \
    -scheme "HomeInventoryModular" \
    -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
    -only-testing:HomeInventoryModularTests/ViewScreenshotTests \
    2>&1 | xcbeautify

# Copy component screenshots
if [ -d ~/Documents/ComponentScreenshots ]; then
    cp ~/Documents/ComponentScreenshots/*.png "$OUTPUT_DIR/Components/" 2>/dev/null || true
    echo "✅ Component screenshots copied to $OUTPUT_DIR/Components/"
fi

echo ""

# Step 2: Build the app first
echo "2️⃣ Building app for UI tests..."
echo "--------------------------------"

xcodebuild build-for-testing \
    -project "$PROJECT_DIR/HomeInventoryModular.xcodeproj" \
    -scheme "HomeInventoryModular" \
    -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
    -derivedDataPath "$PROJECT_DIR/DerivedData" \
    2>&1 | xcbeautify

echo "✅ App built successfully"
echo ""

# Step 3: Run UI Tests for App Flow Screenshots
echo "3️⃣ Capturing app flow screenshots with XCUITest..."
echo "------------------------------------------------"

xcodebuild test-without-building \
    -project "$PROJECT_DIR/HomeInventoryModular.xcodeproj" \
    -scheme "HomeInventoryModular" \
    -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
    -derivedDataPath "$PROJECT_DIR/DerivedData" \
    -only-testing:HomeInventoryModularUITests/HomeInventoryModularUITests/testTakeScreenshots \
    2>&1 | xcbeautify

# Copy UI test screenshots
if [ -d ~/Documents/UITestScreenshots ]; then
    cp ~/Documents/UITestScreenshots/*.png "$OUTPUT_DIR/AppFlow/" 2>/dev/null || true
    echo "✅ App flow screenshots copied to $OUTPUT_DIR/AppFlow/"
fi

echo ""

# Step 4: Run Fastlane for App Store screenshots (if configured)
echo "4️⃣ Generating App Store screenshots with Fastlane..."
echo "-------------------------------------------------"

if command -v bundle &> /dev/null && [ -f "$PROJECT_DIR/fastlane/Fastfile" ]; then
    cd "$PROJECT_DIR/fastlane"
    bundle exec fastlane screenshots || true
    
    # Copy Fastlane screenshots
    if [ -d "$PROJECT_DIR/fastlane/screenshots" ]; then
        cp -r "$PROJECT_DIR/fastlane/screenshots/"* "$OUTPUT_DIR/AppStore/" 2>/dev/null || true
        echo "✅ App Store screenshots copied to $OUTPUT_DIR/AppStore/"
    fi
else
    echo "⚠️  Fastlane not configured or not installed"
fi

echo ""

# Step 5: Generate screenshot summary
echo "5️⃣ Generating screenshot summary..."
echo "-----------------------------------"

cat > "$OUTPUT_DIR/README.md" << EOF
# Home Inventory Screenshots

Generated on: $(date)

## Directory Structure

- **Components/** - Individual UI components captured with ImageRenderer
- **AppFlow/** - Full app flow screenshots from XCUITest
- **AppStore/** - App Store formatted screenshots from Fastlane

## Screenshot Inventory

### Components (ImageRenderer)
$(ls -1 "$OUTPUT_DIR/Components/" 2>/dev/null | grep -E '\.png$' || echo "No component screenshots found")

### App Flow (XCUITest)
$(ls -1 "$OUTPUT_DIR/AppFlow/" 2>/dev/null | grep -E '\.png$' || echo "No app flow screenshots found")

### App Store (Fastlane)
$(find "$OUTPUT_DIR/AppStore/" -name "*.png" -type f 2>/dev/null | sed "s|$OUTPUT_DIR/AppStore/||" || echo "No App Store screenshots found")

## Usage

1. **For Documentation**: Use screenshots from Components/ folder
2. **For Testing**: Review AppFlow/ screenshots for UI verification
3. **For App Store**: Use screenshots from AppStore/ folder

## Regenerating Screenshots

Run: \`./scripts/generate_all_screenshots.sh\`
EOF

echo "✅ Screenshot summary created at $OUTPUT_DIR/README.md"
echo ""

# Final summary
echo "✨ Screenshot generation complete!"
echo "=================================="
echo ""
echo "📊 Summary:"
echo "  - Components: $(ls -1 "$OUTPUT_DIR/Components/"*.png 2>/dev/null | wc -l | tr -d ' ') screenshots"
echo "  - App Flow: $(ls -1 "$OUTPUT_DIR/AppFlow/"*.png 2>/dev/null | wc -l | tr -d ' ') screenshots"
echo "  - App Store: $(find "$OUTPUT_DIR/AppStore/" -name "*.png" -type f 2>/dev/null | wc -l | tr -d ' ') screenshots"
echo ""
echo "📁 All screenshots saved to: $OUTPUT_DIR"