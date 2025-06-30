#!/bin/bash

echo "🧪 Running comprehensive snapshot tests..."
echo "=================================="

# Clean derived data
echo "🧹 Cleaning..."
rm -rf ~/Library/Developer/Xcode/DerivedData/HomeInventoryModular-*

# Build
echo "🔨 Building..."
xcodebuild build-for-testing \
  -project HomeInventoryModular.xcodeproj \
  -scheme HomeInventoryModular \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
  -quiet || { echo "❌ Build failed"; exit 1; }

echo "✅ Build succeeded!"

# Run tests
echo "🧪 Running all snapshot tests..."
xcodebuild test-without-building \
  -project HomeInventoryModular.xcodeproj \
  -scheme HomeInventoryModular \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
  RECORD_SNAPSHOTS=YES \
  -quiet || echo "⚠️  Tests completed with warnings (expected for recording mode)"

# Count snapshots
echo ""
echo "📸 Snapshot Summary:"
echo "==================="
find HomeInventoryModularTests -name "*.png" -path "*__Snapshots__*" | wc -l | xargs echo "Total snapshots:"

echo ""
echo "📂 Snapshots by module:"
for dir in HomeInventoryModularTests/*/; do
  if [ -d "$dir/__Snapshots__" ]; then
    module=$(basename "$dir")
    count=$(find "$dir/__Snapshots__" -name "*.png" | wc -l)
    echo "  $module: $count snapshots"
  fi
done

echo ""
echo "✅ Done!"
