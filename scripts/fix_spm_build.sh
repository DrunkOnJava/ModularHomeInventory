#!/bin/bash

# Fix SPM build issues by resolving packages and setting up proper build order

set -e

echo "🔧 Fixing SPM Build Issues"
echo "========================="
echo ""

# Step 1: Clean
echo "🧹 Cleaning build artifacts..."
xcodebuild clean \
    -workspace HomeInventoryModular.xcworkspace \
    -scheme HomeInventoryModular \
    -quiet

rm -rf ~/Library/Developer/Xcode/DerivedData/HomeInventoryModular-*
rm -rf DerivedData
echo "✅ Clean complete"
echo ""

# Step 2: Resolve packages
echo "📦 Resolving Swift packages..."
xcodebuild -resolvePackageDependencies \
    -workspace HomeInventoryModular.xcworkspace \
    -scheme HomeInventoryModular \
    -quiet

echo "✅ Packages resolved"
echo ""

# Step 3: Build workspace with all schemes
echo "🏗️ Building workspace (this may take a few minutes)..."

# Build with explicit module search paths
xcodebuild build \
    -workspace HomeInventoryModular.xcworkspace \
    -scheme HomeInventoryModular \
    -destination "platform=iOS Simulator,name=iPhone 16 Pro Max" \
    -configuration Debug \
    -derivedDataPath DerivedData \
    SWIFT_SUPPRESS_WARNINGS=YES \
    SWIFT_STRICT_CONCURRENCY=minimal \
    OTHER_SWIFT_FLAGS="-Xfrontend -enable-explicit-existential-types" \
    ENABLE_TESTABILITY=YES \
    BUILD_LIBRARIES_FOR_DISTRIBUTION=YES \
    -quiet

if [ $? -eq 0 ]; then
    echo "✅ Build succeeded!"
    echo ""
    echo "The SPM dependency issues should now be resolved."
    echo "You can run UI tests or capture screenshots."
else
    echo "❌ Build failed"
    echo ""
    echo "Try these manual fixes:"
    echo "1. Open Xcode and build each scheme manually in order:"
    echo "   Core → SharedUI → other modules → HomeInventoryModular"
    echo "2. Reset package caches:"
    echo "   File → Packages → Reset Package Caches"
    echo "3. Update to latest Xcode if available"
    exit 1
fi