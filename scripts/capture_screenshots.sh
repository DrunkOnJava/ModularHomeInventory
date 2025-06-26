#!/bin/bash

echo "📸 Capturing screenshots for HomeInventory app"

# Create screenshots directory
mkdir -p ./screenshots

# Clean build folder
echo "🧹 Cleaning build folder..."
xcodebuild clean -workspace HomeInventoryModular.xcworkspace -scheme HomeInventoryModular

# Run UI tests
echo "🏃 Running UI tests..."
xcodebuild test \
  -workspace HomeInventoryModular.xcworkspace \
  -scheme HomeInventoryModular \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
  -only-testing:HomeInventoryModularUITests/SimpleScreenshotTest/testCaptureScreenshots \
  -resultBundlePath ./TestResults.xcresult

# Extract screenshots from test results
echo "📤 Extracting screenshots..."
if [ -d "./TestResults.xcresult" ]; then
  xcparse screenshots ./TestResults.xcresult ./screenshots --test
  echo "✅ Screenshots saved to ./screenshots"
else
  echo "❌ Test results not found"
fi