#!/bin/bash

echo "📸 Running Onboarding Snapshot Tests"
echo "===================================="

# Optional: Set to record new snapshots
# export RECORD_SNAPSHOTS=YES

# Clean previous test results
rm -rf TestResults/Onboarding
mkdir -p TestResults/Onboarding

# Run the specific test
xcodebuild test \
  -project HomeInventoryModular.xcodeproj \
  -scheme HomeInventoryModular \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
  -only-testing:HomeInventoryModularTests/OnboardingSnapshotTests \
  -resultBundlePath TestResults/Onboarding/Onboarding.xcresult \
  ${RECORD_SNAPSHOTS:+RECORD_SNAPSHOTS=$RECORD_SNAPSHOTS} \
  -quiet || echo "⚠️  Some tests may have failed (expected in record mode)"

# Count snapshots
echo ""
echo "📊 Snapshot Summary:"
find HomeInventoryModularTests -name "*.png" -path "*OnboardingSnapshotTests*" | wc -l | xargs echo "Total snapshots for Onboarding:"

# List snapshot files
echo ""
echo "📁 Generated files:"
find HomeInventoryModularTests -name "*.png" -path "*OnboardingSnapshotTests*" -exec basename {} \; | sort | uniq

echo ""
echo "✅ Done!"
echo ""
echo "💡 Tips:"
echo "   - To record new snapshots: RECORD_SNAPSHOTS=YES ./scripts/test-runners/test-onboarding.sh"
echo "   - To view results: open TestResults/Onboarding/Onboarding.xcresult"
echo "   - Snapshots location: HomeInventoryModularTests/__Snapshots__/OnboardingSnapshotTests/"
