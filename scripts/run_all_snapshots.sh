#!/bin/bash

# Clean build folder
echo "🧹 Cleaning build folder..."
rm -rf build/

# Build the test target
echo "🔨 Building test target..."
xcodebuild build-for-testing \
  -project HomeInventoryModular.xcodeproj \
  -scheme HomeInventoryModular \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  -derivedDataPath build \
  -quiet

if [ $? -ne 0 ]; then
  echo "❌ Build failed!"
  exit 1
fi

echo "✅ Build succeeded!"

# Run the snapshot tests in record mode
echo "📸 Recording snapshots..."
export RECORD_SNAPSHOTS=true

xcodebuild test-without-building \
  -project HomeInventoryModular.xcodeproj \
  -scheme HomeInventoryModular \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  -derivedDataPath build \
  -only-testing:HomeInventoryModularTests \
  2>&1 | xcpretty

echo "✅ Snapshot recording complete!"

# List all generated snapshots
echo ""
echo "📸 Generated snapshots:"
find . -name "*.png" -path "*__Snapshots__*" | grep -v build | sort