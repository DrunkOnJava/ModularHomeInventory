#!/bin/bash

echo "🚀 Building with Swift 5.9"
echo "========================"
echo ""

# Set toolchain
export TOOLCHAINS=swift-5.9-RELEASE

# Verify Swift 5.9
echo "Verifying Swift 5.9..."
xcrun --toolchain swift-5.9-RELEASE swift --version
echo ""

# Change to project directory
cd /Users/griffin/Projects/ModularHomeInventory

# Build and archive
echo "Building and archiving for TestFlight..."
xcodebuild -toolchain swift-5.9-RELEASE \
    -project HomeInventoryModular.xcodeproj \
    -scheme HomeInventoryModular \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -derivedDataPath build/DerivedData \
    CODE_SIGN_IDENTITY='Apple Development' \
    DEVELOPMENT_TEAM='2VXBQV4XC9' \
    -allowProvisioningUpdates \
    clean build archive \
    -archivePath build/HomeInventory.xcarchive

echo ""
echo "✅ Build complete! Archive at: build/HomeInventory.xcarchive"