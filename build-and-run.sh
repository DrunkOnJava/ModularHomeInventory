#!/bin/bash

# Build and run script for HomeInventory Modular App
# This script builds the app and launches it in iPhone 16 Pro Max simulator

set -e  # Exit on error

echo "🔨 Building HomeInventory Modular App..."

# Set variables
PROJECT_PATH="HomeInventoryModular.xcodeproj"
SCHEME="HomeInventoryModular"
SIMULATOR_ID="DD192264-DFAA-4582-B2FE-D6FC444C9DDF"
SIMULATOR_NAME="iPhone 16 Pro Max"
APP_BUNDLE_ID="com.homeinventory.modular"

# Boot simulator if needed
echo "📱 Checking simulator status..."
SIMULATOR_STATE=$(xcrun simctl list devices | grep "$SIMULATOR_ID" | grep -o "(.*)" | sed 's/[()]//g')
if [ "$SIMULATOR_STATE" != "Booted" ]; then
    echo "📱 Booting $SIMULATOR_NAME..."
    xcrun simctl boot $SIMULATOR_ID
    sleep 5  # Wait for simulator to boot
fi

# Open Simulator app
open -a Simulator

# Build the app
echo "🏗️ Building app for $SIMULATOR_NAME..."
xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -sdk iphonesimulator \
    -configuration Debug \
    -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
    -derivedDataPath build \
    clean build

# Check if build succeeded
if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    
    # Find the app bundle
    APP_PATH=$(find build/Build/Products -name "*.app" -type d | head -1)
    
    if [ -z "$APP_PATH" ]; then
        echo "❌ Error: Could not find built app"
        exit 1
    fi
    
    echo "📦 Found app at: $APP_PATH"
    
    # Install the app
    echo "📲 Installing app on simulator..."
    xcrun simctl install $SIMULATOR_ID "$APP_PATH"
    
    # Launch the app
    echo "🚀 Launching app..."
    xcrun simctl launch $SIMULATOR_ID $APP_BUNDLE_ID
    
    echo "✨ App launched successfully!"
else
    echo "❌ Build failed!"
    exit 1
fi