#!/bin/bash

# Final screenshot generation that creates both placeholder and real app screenshots

set -e

echo "📸 Home Inventory Complete Screenshot Generation"
echo "==============================================="
echo ""

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="$PROJECT_DIR/Screenshots"

# Step 1: Generate placeholder images
echo "1️⃣ Generating placeholder screenshots..."
swift "$PROJECT_DIR/scripts/generate_real_screenshots_simple.swift"

# Step 2: Capture real app screenshots if app is running
echo ""
echo "2️⃣ Capturing real app screenshots..."
if "$PROJECT_DIR/scripts/capture_simple_screenshots.sh"; then
    echo "✅ Real app screenshots captured"
else
    echo "⚠️  Could not capture real app screenshots (app may not be running)"
fi

# Step 3: Create comprehensive summary
echo ""
echo "3️⃣ Creating comprehensive summary..."

cat > "$OUTPUT_DIR/SCREENSHOT_SUMMARY.md" << EOF
# Home Inventory Screenshot Collection

Generated on: $(date)

## Screenshot Types

### 🎨 Placeholder Screenshots
Professional placeholder images showing the expected layout and design:

**Components (UI Elements)**
$(ls -1 "$OUTPUT_DIR/Components/" 2>/dev/null | sed 's/^/- /' || echo "- None generated")

**App Flow (Full Screens)**
$(ls -1 "$OUTPUT_DIR/AppFlow/" 2>/dev/null | sed 's/^/- /' || echo "- None generated")

**App Store (Device Sizes)**
$(find "$OUTPUT_DIR/AppStore/" -name "*.png" -type f 2>/dev/null | sed "s|$OUTPUT_DIR/AppStore/||" | sed 's/^/- /' || echo "- None generated")

### 📱 Real App Screenshots
Actual screenshots from the running app:

$(ls -1 "$OUTPUT_DIR/RealApp/" 2>/dev/null | sed 's/^/- /' || echo "- None captured yet")

## File Statistics

| Type | Count | Total Size |
|------|-------|------------|
| Components | $(ls -1 "$OUTPUT_DIR/Components/"*.png 2>/dev/null | wc -l | tr -d ' ') | $(du -sh "$OUTPUT_DIR/Components/" 2>/dev/null | cut -f1 || echo "0B") |
| App Flow | $(ls -1 "$OUTPUT_DIR/AppFlow/"*.png 2>/dev/null | wc -l | tr -d ' ') | $(du -sh "$OUTPUT_DIR/AppFlow/" 2>/dev/null | cut -f1 || echo "0B") |
| App Store | $(find "$OUTPUT_DIR/AppStore/" -name "*.png" -type f 2>/dev/null | wc -l | tr -d ' ') | $(du -sh "$OUTPUT_DIR/AppStore/" 2>/dev/null | cut -f1 || echo "0B") |
| Real App | $(ls -1 "$OUTPUT_DIR/RealApp/"*.png 2>/dev/null | wc -l | tr -d ' ') | $(du -sh "$OUTPUT_DIR/RealApp/" 2>/dev/null | cut -f1 || echo "0B") |

## Usage

### For Development
- Use **Real App** screenshots to see actual app state
- Use **Components** for UI documentation

### For App Store
- Use **App Store** screenshots for store submission
- Use **Real App** screenshots after manual navigation

### For Testing
- Compare **Real App** vs **Placeholder** for visual regression testing

## Regenerating Screenshots

\`\`\`bash
# All screenshots
make screenshots

# Just real app screenshots
./scripts/capture_simple_screenshots.sh

# Just placeholders
swift scripts/generate_real_screenshots_simple.swift
\`\`\`

## Manual Screenshot Capture

\`\`\`bash
# Capture current screen
xcrun simctl io DD192264-DFAA-4582-B2FE-D6FC444C9DDF screenshot my_screen.png

# Navigate app manually, then run:
./scripts/capture_simple_screenshots.sh
\`\`\`
EOF

echo "✅ Summary created at $OUTPUT_DIR/SCREENSHOT_SUMMARY.md"

echo ""
echo "🎯 Final Summary:"
echo "=================="
echo ""
echo "📊 Screenshot Statistics:"
echo "  - Placeholder Components: $(ls -1 "$OUTPUT_DIR/Components/"*.png 2>/dev/null | wc -l | tr -d ' ') files"
echo "  - Placeholder App Flow: $(ls -1 "$OUTPUT_DIR/AppFlow/"*.png 2>/dev/null | wc -l | tr -d ' ') files"
echo "  - Placeholder App Store: $(find "$OUTPUT_DIR/AppStore/" -name "*.png" -type f 2>/dev/null | wc -l | tr -d ' ') files"
echo "  - Real App Screenshots: $(ls -1 "$OUTPUT_DIR/RealApp/"*.png 2>/dev/null | wc -l | tr -d ' ') files (~$(du -sh "$OUTPUT_DIR/RealApp/" 2>/dev/null | cut -f1 || echo "0B"))"
echo ""
echo "📁 All screenshots saved to: $OUTPUT_DIR"
echo ""
echo "✨ You now have both placeholder designs AND real app screenshots!"