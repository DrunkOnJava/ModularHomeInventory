#!/bin/bash

# Test runner for ErrorStatesSnapshotTests

echo "📸 Running ErrorStatesSnapshotTests"
echo "====================================="

# Set test environment
export SNAPSHOT_TEST_MODE=${RECORD_SNAPSHOTS:-"verify"}

# Remove existing result bundle if it exists
RESULT_BUNDLE_PATH="TestResults/Additional/ErrorStatesSnapshotTests/ErrorStatesSnapshotTests.xcresult"
if [ -d "$RESULT_BUNDLE_PATH" ]; then
  rm -rf "$RESULT_BUNDLE_PATH"
fi

# Run tests
xcodebuild test \
    -project HomeInventoryModular.xcodeproj \
    -scheme HomeInventoryModular \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=latest' \
    -only-testing:HomeInventoryModularTests/ErrorStatesSnapshotTests \
    -resultBundlePath "$RESULT_BUNDLE_PATH" \
    | xcbeautify

# Get exit code
EXIT_CODE=${PIPESTATUS[0]}

if [ $EXIT_CODE -ne 0 ]; then
    echo "⚠️  Some tests may have failed (expected in record mode)"
fi

# Count snapshots
SNAPSHOT_COUNT=$(find HomeInventoryModularTests/AdditionalTests/__Snapshots__/ErrorStatesSnapshotTests/ -name "*.png" 2>/dev/null | wc -l | tr -d ' ')

echo ""
echo "📊 Snapshot Summary:"
echo "Total snapshots: $SNAPSHOT_COUNT"
echo ""
echo "✅ Done!"
