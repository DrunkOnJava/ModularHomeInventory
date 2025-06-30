#!/bin/bash

echo "🚀 Step-by-step test runner"
echo "=========================="

# Clean
echo "🧹 Step 1: Cleaning..."
rm -rf ~/Library/Developer/Xcode/DerivedData/HomeInventoryModular-*
rm -rf build/

# Build the app first
echo "🔨 Step 2: Building app..."
xcodebuild build \
  -project HomeInventoryModular.xcodeproj \
  -scheme HomeInventoryModular \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
  -derivedDataPath build \
  ONLY_ACTIVE_ARCH=NO \
  BUILD_FOR_TESTING=YES

if [ $? -ne 0 ]; then
  echo "❌ App build failed!"
  exit 1
fi

echo "✅ App built successfully!"

# Build tests separately
echo "🧪 Step 3: Building tests..."
xcodebuild build-for-testing \
  -project HomeInventoryModular.xcodeproj \
  -scheme HomeInventoryModular \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
  -derivedDataPath build \
  ONLY_ACTIVE_ARCH=NO

if [ $? -ne 0 ]; then
  echo "❌ Test build failed!"
  exit 1
fi

echo "✅ Tests built successfully!"

# List what was built
echo ""
echo "📦 Build products:"
find build/Build/Products -name "*.app" -o -name "*.xctest" | sort

# Try to run tests
echo ""
echo "🏃 Step 4: Running tests..."
xcodebuild test-without-building \
  -project HomeInventoryModular.xcodeproj \
  -scheme HomeInventoryModular \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
  -derivedDataPath build \
  RECORD_SNAPSHOTS=YES \
  2>&1 | grep -E "(Test Suite|Test Case|test.*started|test.*passed|test.*failed|Executed|snapshot)"

echo ""
echo "✅ Done!"