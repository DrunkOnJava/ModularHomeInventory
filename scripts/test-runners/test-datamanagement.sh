#!/bin/bash

echo "📸 Running DataManagementSnapshotTests"
echo "====================================="

# Optional: Set to record new snapshots
# export RECORD_SNAPSHOTS=YES

# Clean previous test results
rm -rf TestResults/Enhanced/DataManagementSnapshotTests
mkdir -p TestResults/Enhanced/DataManagementSnapshotTests

# Run the specific test
xcodebuild test \
  -project HomeInventoryModular.xcodeproj \
  -scheme HomeInventoryModular \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
  -only-testing:HomeInventoryModularTests/DataManagementSnapshotTests \
  -resultBundlePath TestResults/Enhanced/DataManagementSnapshotTests/DataManagementSnapshotTests.xcresult \
  ${RECORD_SNAPSHOTS:+RECORD_SNAPSHOTS=$RECORD_SNAPSHOTS} \
  -quiet || echo "⚠️  Some tests may have failed (expected in record mode)"

# Count snapshots
echo ""
echo "📊 Snapshot Summary:"
find HomeInventoryModularTests -name "*.png" -path "*DataManagementSnapshotTests*" | wc -l | xargs echo "Total snapshots:"

echo ""
echo "✅ Done!"
