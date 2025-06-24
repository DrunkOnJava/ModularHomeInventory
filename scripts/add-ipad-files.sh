#!/bin/bash

# Script to add iPad files to Xcode project
# This script creates necessary references in the project file

echo "📱 Adding iPad files to Xcode project..."

# Define the iPad Swift files
IPAD_FILES=(
    "iPadApp.swift"
    "iPadSidebarView.swift"
    "iPadColumnView.swift"
    "iPadKeyboardShortcuts.swift"
    "iPadContextMenus.swift"
    "iPadDragDrop.swift"
)

# Check if all files exist
echo "Checking for iPad files..."
for file in "${IPAD_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ Missing file: $file"
        exit 1
    fi
done

echo "✅ All iPad files found"

# Create a temporary project.yml for xcodegen if it doesn't exist
if [ ! -f "project.yml" ]; then
    echo "Creating project.yml for xcodegen..."
    cat > project.yml << EOF
name: HomeInventoryModular
options:
  bundleIdPrefix: com.homeinventory
  deploymentTarget:
    iOS: "17.0"
targets:
  HomeInventoryModular:
    type: application
    platform: iOS
    sources:
      - path: .
        excludes:
          - "**/.DS_Store"
          - "**/*.xcodeproj"
          - "**/build"
          - "**/DerivedData"
          - "Modules"
        includes:
          - "*.swift"
          - "Assets.xcassets"
          - "Info.plist"
          - "HomeInventoryWidgets"
    dependencies:
      - package: Core
        product: Core
      - package: SharedUI
        product: SharedUI
      - package: Items
        product: Items
      - package: BarcodeScanner
        product: BarcodeScanner
      - package: AppSettings
        product: AppSettings
      - package: Receipts
        product: Receipts
      - package: Sync
        product: Sync
      - package: Premium
        product: Premium
      - package: Onboarding
        product: Onboarding
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: com.homeinventory.modular
      INFOPLIST_FILE: Info.plist
      DEVELOPMENT_TEAM: ""
      TARGETED_DEVICE_FAMILY: "1,2"
      SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD: YES
packages:
  Core:
    path: Modules/Core
  SharedUI:
    path: Modules/SharedUI
  Items:
    path: Modules/Items
  BarcodeScanner:
    path: Modules/BarcodeScanner
  AppSettings:
    path: Modules/AppSettings
  Receipts:
    path: Modules/Receipts
  Sync:
    path: Modules/Sync
  Premium:
    path: Modules/Premium
  Onboarding:
    path: Modules/Onboarding
EOF
fi

# Run xcodegen to regenerate project with all files
echo "Regenerating Xcode project..."
if command -v xcodegen &> /dev/null; then
    xcodegen generate
    echo "✅ Project regenerated with iPad files"
else
    echo "⚠️  xcodegen not found. Please install it with: brew install xcodegen"
    echo "   Then run: make generate"
fi

echo "✅ iPad files added to project!"
echo ""
echo "Next steps:"
echo "1. Open the project in Xcode: make xcode"
echo "2. Build for iPad: make build-ipad"
echo "3. Run on iPad: make run-ipad"
echo ""
echo "Or use the shortcut: make bri (build and run on iPad)"