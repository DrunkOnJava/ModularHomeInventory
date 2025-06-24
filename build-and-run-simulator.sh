#!/bin/bash

# Build and run the HomeInventory app on iOS Simulator

echo "🔨 Building HomeInventory for iOS Simulator..."

# Clean build folder
rm -rf build/

# Build for simulator
xcodebuild \
    -scheme HomeInventoryModular \
    -configuration Debug \
    -sdk iphonesimulator \
    -derivedDataPath build \
    build

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    
    # Find the app
    APP_PATH="build/Build/Products/Debug-iphonesimulator/HomeInventoryModular.app"
    
    if [ -d "$APP_PATH" ]; then
        echo "📱 Installing on simulator..."
        
        # Get booted simulator
        SIMULATOR_ID=$(xcrun simctl list devices | grep -E "iPhone.*Booted" | head -1 | grep -oE "[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}")
        
        if [ -z "$SIMULATOR_ID" ]; then
            echo "⚠️  No booted simulator found. Booting iPhone 16 Pro..."
            SIMULATOR_ID=$(xcrun simctl list devices | grep "iPhone 16 Pro" | head -1 | grep -oE "[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}")
            xcrun simctl boot "$SIMULATOR_ID"
            sleep 5
        fi
        
        # Install and launch
        xcrun simctl install "$SIMULATOR_ID" "$APP_PATH"
        xcrun simctl launch "$SIMULATOR_ID" com.homeinventory.modular
        
        echo "🚀 App launched on simulator!"
    else
        echo "❌ App not found at $APP_PATH"
    fi
else
    echo "❌ Build failed!"
    exit 1
fi