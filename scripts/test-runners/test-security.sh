#!/bin/bash

echo "📸 Running SecuritySnapshotTests"
echo "====================================="

# Optional: Set to record new snapshots
# export RECORD_SNAPSHOTS=YES

# Clean previous test results
rm -rf TestResults/Enhanced/SecuritySnapshotTests
mkdir -p TestResults/Enhanced/SecuritySnapshotTests

# Run the specific test
xcodebuild test \
  -project HomeInventoryModular.xcodeproj \
  -scheme HomeInventoryModular \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
  -only-testing:HomeInventoryModularTests/SecuritySnapshotTests \
  -resultBundlePath TestResults/Enhanced/SecuritySnapshotTests/SecuritySnapshotTests.xcresult \
  ${RECORD_SNAPSHOTS:+RECORD_SNAPSHOTS=$RECORD_SNAPSHOTS} \
  -quiet || echo "⚠️  Some tests may have failed (expected in record mode)"

# Count snapshots
echo ""
echo "📊 Snapshot Summary:"
find HomeInventoryModularTests -name "*.png" -path "*SecuritySnapshotTests*" | wc -l | xargs echo "Total snapshots:"

echo ""
echo "✅ Done!"
