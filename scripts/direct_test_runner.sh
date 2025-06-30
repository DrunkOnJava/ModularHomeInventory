#!/bin/bash

# Direct test runner for snapshot tests
set -e

echo "🧪 Direct Snapshot Test Runner"
echo "=============================="

# Clean build directory
echo "🧹 Cleaning build directory..."
rm -rf build/ || true

# Set environment for recording snapshots
export RECORD_SNAPSHOTS=true

# Build and test in one command with proper destination
echo "🔨 Building and testing..."
xcodebuild test \
  -project HomeInventoryModular.xcodeproj \
  -scheme HomeInventoryModular \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -derivedDataPath build \
  RECORD_SNAPSHOTS=YES \
  2>&1 | tee test_output.log | grep -E "(Test Suite|Test Case|passed|failed|error:|warning:|Executed)"

# Check if tests passed
if [ ${PIPESTATUS[0]} -eq 0 ]; then
  echo ""
  echo "✅ Tests completed successfully!"
  
  # Count and list snapshots
  echo ""
  echo "📸 Generated snapshots:"
  find . -name "*.png" -path "*__Snapshots__*" | grep -v build | sort | while read -r file; do
    echo "  ✓ $file"
  done
  
  SNAPSHOT_COUNT=$(find . -name "*.png" -path "*__Snapshots__*" | grep -v build | wc -l)
  echo ""
  echo "Total snapshots: $SNAPSHOT_COUNT"
else
  echo ""
  echo "❌ Tests failed! Check test_output.log for details"
  
  # Show errors from log
  echo ""
  echo "Errors found:"
  grep -E "(error:|failed:|Error:|Failed:)" test_output.log | tail -20
fi