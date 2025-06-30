#!/bin/bash

echo "📸 Generating SwiftUI Component Snapshots"
echo "========================================"

# Clean previous results
rm -rf TestResults.xcresult
rm -rf __Snapshots__

# Build the tests first
echo "🔨 Building test targets..."
xcodebuild build-for-testing \
  -project HomeInventoryModular.xcodeproj \
  -scheme HomeInventoryModular \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro Max" \
  -derivedDataPath build \
  -quiet || { echo "❌ Build failed"; exit 1; }

echo "✅ Build successful!"

# Run specific tests that should work
echo ""
echo "📸 Running working snapshot tests..."

# Run SimpleSnapshotTest
echo "1️⃣ Running SimpleSnapshotTest..."
RECORD_SNAPSHOTS=true xcodebuild test-without-building \
  -project HomeInventoryModular.xcodeproj \
  -scheme HomeInventoryModular \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro Max" \
  -derivedDataPath build \
  -only-testing:HomeInventoryModularTests/SimpleSnapshotTest \
  2>&1 | grep -E "(Test.*passed|failed|Recorded|\.png)" || true

# Run LoadingOverlaySnapshotTests
echo ""
echo "2️⃣ Running LoadingOverlaySnapshotTests..."
RECORD_SNAPSHOTS=true xcodebuild test-without-building \
  -project HomeInventoryModular.xcodeproj \
  -scheme HomeInventoryModular \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro Max" \
  -derivedDataPath build \
  -only-testing:HomeInventoryModularTests/LoadingOverlaySnapshotTests \
  2>&1 | grep -E "(Test.*passed|failed|Recorded|\.png)" || true

# Run PrimaryButtonSnapshotTests
echo ""
echo "3️⃣ Running PrimaryButtonSnapshotTests..."
RECORD_SNAPSHOTS=true xcodebuild test-without-building \
  -project HomeInventoryModular.xcodeproj \
  -scheme HomeInventoryModular \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro Max" \
  -derivedDataPath build \
  -only-testing:HomeInventoryModularTests/PrimaryButtonSnapshotTests \
  2>&1 | grep -E "(Test.*passed|failed|Recorded|\.png)" || true

echo ""
echo "🔍 Looking for generated snapshots..."
echo "===================================="

# Find all __Snapshots__ directories and list their contents
find . -name "__Snapshots__" -type d 2>/dev/null | while read dir; do
  if [ -d "$dir" ]; then
    png_count=$(find "$dir" -name "*.png" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [ "$png_count" -gt 0 ]; then
      echo ""
      echo "📁 Found snapshots in: $dir"
      echo "   Total images: $png_count"
      find "$dir" -name "*.png" -type f 2>/dev/null | while read png; do
        size=$(ls -lh "$png" | awk '{print $5}')
        echo "   📸 $(basename "$png") ($size)"
      done
    fi
  fi
done

echo ""
echo "✨ Snapshot generation complete!"