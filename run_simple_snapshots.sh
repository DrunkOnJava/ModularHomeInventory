#!/bin/bash

echo "📸 Running Snapshot Tests for SwiftUI Components"
echo "=============================================="

# Clean previous test results
rm -rf TestResults.xcresult

# First, let's just build the app and tests
echo "🔨 Building app and tests..."
xcodebuild build-for-testing \
  -project HomeInventoryModular.xcodeproj \
  -scheme HomeInventoryModular \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro Max" \
  -derivedDataPath build \
  -quiet || { echo "❌ Build failed"; exit 1; }

echo "✅ Build successful!"

# Now run just the SimpleSnapshotTest with recording enabled
echo ""
echo "📸 Running SimpleSnapshotTest with recording enabled..."
RECORD_SNAPSHOTS=true xcodebuild test-without-building \
  -project HomeInventoryModular.xcodeproj \
  -scheme HomeInventoryModular \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro Max" \
  -derivedDataPath build \
  -only-testing:HomeInventoryModularTests/SimpleSnapshotTest \
  -resultBundlePath TestResults.xcresult \
  2>&1 | grep -E "(Test|Recorded|snapshot|\.png|Snapshots)" || true

echo ""
echo "🔍 Looking for generated snapshots..."
echo "===================================="

# Find all __Snapshots__ directories
find . -name "__Snapshots__" -type d 2>/dev/null | while read dir; do
  if [ -d "$dir" ]; then
    echo "📁 Found snapshot directory: $dir"
    find "$dir" -name "*.png" -type f 2>/dev/null | while read png; do
      echo "  📸 $(basename "$png")"
    done
  fi
done

# Also check in the test results
echo ""
echo "📊 Checking test results..."
if [ -d "TestResults.xcresult" ]; then
  echo "✅ Test results bundle created"
  # Try to extract any attachments
  find TestResults.xcresult -name "*.png" -type f 2>/dev/null | while read png; do
    echo "  📸 Found in results: $(basename "$png")"
  done
fi

echo ""
echo "✨ Done! If no snapshots were found, the tests may need to be fixed first."