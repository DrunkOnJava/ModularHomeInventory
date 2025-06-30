#!/bin/bash

echo "🚀 Comprehensive Snapshot Test Runner"
echo "===================================="
echo ""

# Step 1: Clean everything
echo "🧹 Step 1: Cleaning build artifacts..."
rm -rf ~/Library/Developer/Xcode/DerivedData/HomeInventoryModular-*
rm -rf build/
echo "✅ Clean complete"
echo ""

# Step 2: Resolve dependencies
echo "📦 Step 2: Resolving package dependencies..."
xcodebuild -resolvePackageDependencies -project HomeInventoryModular.xcodeproj -scheme HomeInventoryModular -quiet
echo "✅ Dependencies resolved"
echo ""

# Step 3: Build for testing
echo "🔨 Step 3: Building for testing..."
xcodebuild build-for-testing \
  -project HomeInventoryModular.xcodeproj \
  -scheme HomeInventoryModular \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -quiet \
  SWIFT_TREAT_WARNINGS_AS_ERRORS=NO \
  GCC_TREAT_WARNINGS_AS_ERRORS=NO

if [ $? -ne 0 ]; then
  echo "❌ Build failed!"
  exit 1
fi
echo "✅ Build complete"
echo ""

# Step 4: Run tests
echo "🧪 Step 4: Running snapshot tests..."
export RECORD_SNAPSHOTS=true

xcodebuild test-without-building \
  -project HomeInventoryModular.xcodeproj \
  -scheme HomeInventoryModular \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  RECORD_SNAPSHOTS=YES \
  -quiet

if [ $? -eq 0 ]; then
  echo "✅ Tests complete"
else
  echo "⚠️  Some tests may have failed, but snapshots might still be generated"
fi
echo ""

# Step 5: Report results
echo "📊 Step 5: Snapshot Report"
echo "========================="

# Count snapshots by module
echo ""
echo "Snapshots by module:"
for dir in HomeInventoryModularTests/*/; do
  if [ -d "$dir/__Snapshots__" ]; then
    count=$(find "$dir/__Snapshots__" -name "*.png" 2>/dev/null | wc -l)
    if [ $count -gt 0 ]; then
      module=$(basename "$dir")
      printf "  %-20s %d snapshots\n" "$module:" $count
    fi
  fi
done

# Total count
echo ""
total=$(find HomeInventoryModularTests -name "*.png" -path "*__Snapshots__*" 2>/dev/null | wc -l)
echo "Total snapshots generated: $total"
echo ""

# List all snapshots
echo "All snapshot files:"
find HomeInventoryModularTests -name "*.png" -path "*__Snapshots__*" 2>/dev/null | sort | while read -r file; do
  echo "  ✓ $file"
done

echo ""
echo "✅ Snapshot generation complete!"
echo ""
echo "To view snapshots, look in the __Snapshots__ directories"