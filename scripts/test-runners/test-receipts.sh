#!/bin/bash

echo "📸 Running Receipts Snapshot Tests"
echo "===================================="

# Optional: Set to record new snapshots
# export RECORD_SNAPSHOTS=YES

# Clean previous test results
rm -rf TestResults/Receipts
mkdir -p TestResults/Receipts

# Run the specific test
xcodebuild test \
  -project HomeInventoryModular.xcodeproj \
  -scheme HomeInventoryModular \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
  -only-testing:HomeInventoryModularTests/ReceiptsSnapshotTests \
  -resultBundlePath TestResults/Receipts/Receipts.xcresult \
  ${RECORD_SNAPSHOTS:+RECORD_SNAPSHOTS=$RECORD_SNAPSHOTS} \
  -quiet || echo "⚠️  Some tests may have failed (expected in record mode)"

# Count snapshots
echo ""
echo "📊 Snapshot Summary:"
find HomeInventoryModularTests -name "*.png" -path "*ReceiptsSnapshotTests*" | wc -l | xargs echo "Total snapshots for Receipts:"

# List snapshot files
echo ""
echo "📁 Generated files:"
find HomeInventoryModularTests -name "*.png" -path "*ReceiptsSnapshotTests*" -exec basename {} \; | sort | uniq

echo ""
echo "✅ Done!"
echo ""
echo "💡 Tips:"
echo "   - To record new snapshots: RECORD_SNAPSHOTS=YES ./scripts/test-runners/test-receipts.sh"
echo "   - To view results: open TestResults/Receipts/Receipts.xcresult"
echo "   - Snapshots location: HomeInventoryModularTests/__Snapshots__/ReceiptsSnapshotTests/"
