#!/bin/bash

echo "🔨 Building app for testing..."
xcodebuild build-for-testing \
  -scheme HomeInventoryModular \
  -project HomeInventoryModular.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
  -derivedDataPath ./DerivedData

if [ $? -ne 0 ]; then
  echo "❌ Build failed"
  exit 1
fi

echo "✅ Build succeeded"
echo "📸 Running screenshot tests..."

bundle exec fastlane snapshot \
  --scheme HomeInventoryModular \
  --devices "iPhone 16 Pro Max" \
  --languages "en-US" \
  --skip_open_summary \
  --derived_data_path ./DerivedData

echo "✅ Screenshots complete!"