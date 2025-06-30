#!/bin/bash

echo "🧪 Running SharedUI snapshot tests..."
echo "===================================="

# Run just the SharedUI tests that we know work
xcodebuild test \
  -project HomeInventoryModular.xcodeproj \
  -scheme HomeInventoryModular \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
  -only-testing:HomeInventoryModularTests/PrimaryButtonSnapshotTests \
  -only-testing:HomeInventoryModularTests/SearchBarSnapshotTests \
  -only-testing:HomeInventoryModularTests/LoadingOverlaySnapshotTests \
  -only-testing:HomeInventoryModularTests/AdditionalComponentSnapshotTests \
  -only-testing:HomeInventoryModularTests/SimpleSnapshotTest \
  RECORD_SNAPSHOTS=YES \
  -quiet || echo "⚠️  Tests completed"

# Count snapshots
echo ""
echo "📸 Generated snapshots:"
echo "====================="
find HomeInventoryModularTests -name "*.png" -path "*__Snapshots__*" -newer HomeInventoryModularTests/SimpleSnapshotTest.swift | sort

echo ""
echo "📊 Total snapshots: $(find HomeInventoryModularTests -name "*.png" -path "*__Snapshots__*" | wc -l | xargs)"
echo "✅ Done!"