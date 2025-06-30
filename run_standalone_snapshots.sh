#!/bin/bash

echo "🚀 Running Standalone Snapshot Tests"
echo "==================================="

# Clean
echo "🧹 Cleaning..."
rm -rf ~/Library/Developer/Xcode/DerivedData/HomeInventoryModular-*

# Build the app first
echo "🔨 Building app..."
xcodebuild build \
  -project HomeInventoryModular.xcodeproj \
  -scheme HomeInventoryModular \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
  -derivedDataPath build \
  SWIFT_TREAT_WARNINGS_AS_ERRORS=NO \
  GCC_TREAT_WARNINGS_AS_ERRORS=NO

if [ $? -ne 0 ]; then
  echo "❌ Build failed!"
  exit 1
fi

echo "✅ Build succeeded!"

# Try to run just the standalone test
echo "📸 Running standalone snapshot test..."
xcodebuild test \
  -project HomeInventoryModular.xcodeproj \
  -scheme HomeInventoryModular \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
  -only-testing:HomeInventoryModularTests/StandaloneSnapshotTest \
  -derivedDataPath build \
  RECORD_SNAPSHOTS=YES \
  2>&1 | grep -E "(Test Case|Executed|Recording snapshot|Saving snapshot|\.png|testMainTabView|testItemsListView|testAddItemView)"

# Find and list snapshots
echo ""
echo "📸 Looking for generated snapshots..."
find . -name "*.png" -path "*StandaloneSnapshotTest*" -o -name "*.png" -path "*__Snapshots__*" -newer /tmp/.before_test 2>/dev/null | sort

echo ""
echo "✅ Done!"