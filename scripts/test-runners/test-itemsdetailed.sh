#!/bin/bash

echo "📸 Running ItemsDetailedSnapshotTests"
echo "====================================="

# Optional: Set to record new snapshots
# export RECORD_SNAPSHOTS=YES

# Clean previous test results
rm -rf TestResults/Enhanced/ItemsDetailedSnapshotTests
mkdir -p TestResults/Enhanced/ItemsDetailedSnapshotTests

# Run the specific test
xcodebuild test \
  -project HomeInventoryModular.xcodeproj \
  -scheme HomeInventoryModular \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
  -only-testing:HomeInventoryModularTests/ItemsDetailedSnapshotTests \
  -resultBundlePath TestResults/Enhanced/ItemsDetailedSnapshotTests/ItemsDetailedSnapshotTests.xcresult \
  ${RECORD_SNAPSHOTS:+RECORD_SNAPSHOTS=$RECORD_SNAPSHOTS} \
  -quiet || echo "⚠️  Some tests may have failed (expected in record mode)"

# Count snapshots
echo ""
echo "📊 Snapshot Summary:"
find HomeInventoryModularTests -name "*.png" -path "*ItemsDetailedSnapshotTests*" | wc -l | xargs echo "Total snapshots:"

echo ""
echo "✅ Done!"
