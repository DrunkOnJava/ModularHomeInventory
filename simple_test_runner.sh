#!/bin/bash

echo "🚀 Simple Test Runner"
echo "===================="

# Clean
echo "🧹 Cleaning derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/HomeInventoryModular-*

# Build
echo "🔨 Building app and tests..."
xcodebuild build-for-testing \
  -project HomeInventoryModular.xcodeproj \
  -scheme HomeInventoryModular \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
  -derivedDataPath build \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_ENTITLEMENTS="" \
  CODE_SIGNING_ALLOWED=NO

if [ $? -ne 0 ]; then
  echo "❌ Build failed!"
  echo "Trying to diagnose..."
  
  # Try building just the app
  echo "🔨 Building app only..."
  xcodebuild build \
    -project HomeInventoryModular.xcodeproj \
    -scheme HomeInventoryModular \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
    -derivedDataPath build \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO
    
  exit 1
fi

echo "✅ Build succeeded!"

# List what was built
echo "📦 Built products:"
find build/Build/Products -name "*.app" -o -name "*.xctest" 2>/dev/null

# Try to run a single test
echo "🧪 Running SimpleSnapshotTest..."
xcodebuild test-without-building \
  -project HomeInventoryModular.xcodeproj \
  -scheme HomeInventoryModular \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
  -derivedDataPath build \
  -only-testing:HomeInventoryModularTests/SimpleSnapshotTest/testSimpleView \
  RECORD_SNAPSHOTS=YES

echo "✅ Test run complete!"

# Check for snapshots
echo "📸 Looking for snapshots..."
find . -name "*.png" -path "*__Snapshots__*" 2>/dev/null | sort
