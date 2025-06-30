#!/bin/bash

echo "📸 Running BarcodeScanner Snapshot Tests"
echo "===================================="

# Optional: Set to record new snapshots
# export RECORD_SNAPSHOTS=YES

# Clean previous test results
rm -rf TestResults/BarcodeScanner
mkdir -p TestResults/BarcodeScanner

# Run the specific test
xcodebuild test \
  -project HomeInventoryModular.xcodeproj \
  -scheme HomeInventoryModular \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
  -only-testing:HomeInventoryModularTests/BarcodeScannerSnapshotTests \
  -resultBundlePath TestResults/BarcodeScanner/BarcodeScanner.xcresult \
  ${RECORD_SNAPSHOTS:+RECORD_SNAPSHOTS=$RECORD_SNAPSHOTS} \
  -quiet || echo "⚠️  Some tests may have failed (expected in record mode)"

# Count snapshots
echo ""
echo "📊 Snapshot Summary:"
find HomeInventoryModularTests -name "*.png" -path "*BarcodeScannerSnapshotTests*" | wc -l | xargs echo "Total snapshots for BarcodeScanner:"

# List snapshot files
echo ""
echo "📁 Generated files:"
find HomeInventoryModularTests -name "*.png" -path "*BarcodeScannerSnapshotTests*" -exec basename {} \; | sort | uniq

echo ""
echo "✅ Done!"
echo ""
echo "💡 Tips:"
echo "   - To record new snapshots: RECORD_SNAPSHOTS=YES ./scripts/test-runners/test-barcodescanner.sh"
echo "   - To view results: open TestResults/BarcodeScanner/BarcodeScanner.xcresult"
echo "   - Snapshots location: HomeInventoryModularTests/__Snapshots__/BarcodeScannerSnapshotTests/"
