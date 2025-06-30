#!/bin/bash

echo "📸 Running Minimal Snapshot Demo"
echo "=============================="

# Clean and build
echo "🔨 Building..."
xcodebuild build-for-testing \
  -project HomeInventoryModular.xcodeproj \
  -scheme HomeInventoryModular \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro Max" \
  -derivedDataPath build \
  -quiet || { echo "❌ Build failed"; exit 1; }

echo "✅ Build successful!"

# Run the minimal snapshot test
echo ""
echo "📸 Running MinimalSnapshotDemo..."
xcodebuild test-without-building \
  -project HomeInventoryModular.xcodeproj \
  -scheme HomeInventoryModular \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro Max" \
  -derivedDataPath build \
  -only-testing:HomeInventoryModularTests/MinimalSnapshotDemo \
  2>&1 | grep -E "(Test.*started|passed|failed|\.png|Recorded|snapshot)" || true

echo ""
echo "🔍 Looking for generated snapshots..."
find HomeInventoryModularTests -name "__Snapshots__" -type d 2>/dev/null | while read dir; do
  if [ -d "$dir" ]; then
    echo "📁 Found: $dir"
    ls -la "$dir"/*.png 2>/dev/null || echo "  No PNG files yet"
  fi
done

# Also check derived data
echo ""
echo "🔍 Checking derived data for snapshots..."
find build -name "__Snapshots__" -type d 2>/dev/null | while read dir; do
  if [ -d "$dir" ]; then
    echo "📁 Found: $dir"
    ls -la "$dir"/*.png 2>/dev/null || echo "  No PNG files yet"
  fi
done