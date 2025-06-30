#!/bin/bash

echo "📸 Generating SwiftUI Component Snapshots..."
echo "======================================"

# Set environment to record snapshots
export RECORD_SNAPSHOTS=true

# Run the simple snapshot test first
echo "🧪 Running SimpleSnapshotTest..."
xcodebuild test \
  -project HomeInventoryModular.xcodeproj \
  -scheme HomeInventoryModular \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro Max" \
  -only-testing:HomeInventoryModularTests/SimpleSnapshotTest \
  -enableCodeCoverage NO \
  RECORD_SNAPSHOTS=YES \
  isRecording=YES \
  2>&1 | grep -E "(Test Case|passed|failed|Recorded|snapshot)" || true

echo ""
echo "📁 Looking for generated snapshots..."
find . -path "./build" -prune -o -name "__Snapshots__" -type d -print | while read dir; do
  if [ -d "$dir" ]; then
    count=$(find "$dir" -name "*.png" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$count" -gt 0 ]; then
      echo "✅ Found $count snapshots in: $dir"
      ls -la "$dir"/*.png 2>/dev/null | head -10
    fi
  fi
done

echo ""
echo "🔍 Checking test results directory..."
if [ -d "TestResults.xcresult" ]; then
  echo "📊 Test results available at: TestResults.xcresult"
fi

echo ""
echo "✅ Snapshot generation complete!"
echo "💡 Note: The first run records baseline snapshots. Run again to verify they match."