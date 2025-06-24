#!/bin/bash

# Pre-build all SPM modules in dependency order
# This fixes "no such module" errors when building from command line

set -e

echo "🔨 Pre-building SPM modules in dependency order..."
echo "================================================"
echo ""

# Build configuration
CONFIGURATION="Debug"
DERIVED_DATA="DerivedData"

# Define module build order (dependencies first)
MODULES=(
    "Core"
    "SharedUI"
    "BarcodeScanner"
    "Receipts"
    "AppSettings"
    "Onboarding"
    "Premium"
    "Sync"
    "Items"
)

# Function to build a module
build_module() {
    local module=$1
    echo "📦 Building $module..."
    
    xcodebuild build \
        -scheme "$module" \
        -destination "platform=iOS Simulator,name=iPhone 16 Pro Max" \
        -configuration "$CONFIGURATION" \
        -derivedDataPath "$DERIVED_DATA" \
        SWIFT_SUPPRESS_WARNINGS=YES \
        SWIFT_STRICT_CONCURRENCY=minimal \
        -quiet
    
    if [ $? -eq 0 ]; then
        echo "✅ $module built successfully"
    else
        echo "❌ Failed to build $module"
        exit 1
    fi
    echo ""
}

# Clean if requested
if [ "$1" == "clean" ]; then
    echo "🧹 Cleaning derived data..."
    rm -rf "$DERIVED_DATA"
    echo ""
fi

# Build each module in order
for module in "${MODULES[@]}"; do
    build_module "$module"
done

echo "✅ All modules built successfully!"
echo ""
echo "You can now build the main app or run UI tests."