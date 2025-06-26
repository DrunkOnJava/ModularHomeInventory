#!/bin/bash

echo "🔨 Building with Legacy Build System"
echo "===================================="
echo ""

# Clean build folder
echo "🧹 Cleaning build folder..."
rm -rf build/
mkdir -p build

# Try to build with legacy build system
echo "📱 Building for iOS devices..."
echo ""

xcodebuild \
  -project HomeInventoryModular.xcodeproj \
  -scheme HomeInventoryModular \
  -configuration Release \
  -derivedDataPath build/DerivedData \
  -destination 'generic/platform=iOS' \
  -UseModernBuildSystem=NO \
  CODE_SIGN_IDENTITY="Apple Development" \
  DEVELOPMENT_TEAM="2VXBQV4XC9" \
  -allowProvisioningUpdates \
  clean build

if [ $? -eq 0 ]; then
  echo ""
  echo "✅ Build successful!"
  
  # Archive
  echo "📦 Creating archive..."
  xcodebuild \
    -project HomeInventoryModular.xcodeproj \
    -scheme HomeInventoryModular \
    -configuration Release \
    -derivedDataPath build/DerivedData \
    -archivePath build/HomeInventory.xcarchive \
    -destination 'generic/platform=iOS' \
    -UseModernBuildSystem=NO \
    CODE_SIGN_IDENTITY="Apple Development" \
    DEVELOPMENT_TEAM="2VXBQV4XC9" \
    -allowProvisioningUpdates \
    archive
    
  if [ $? -eq 0 ]; then
    echo "✅ Archive created!"
    
    # Export IPA
    echo "📤 Exporting IPA..."
    
    # Create export options plist
    cat > build/ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>2VXBQV4XC9</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
EOF
    
    xcodebuild \
      -exportArchive \
      -archivePath build/HomeInventory.xcarchive \
      -exportPath build \
      -exportOptionsPlist build/ExportOptions.plist \
      -UseModernBuildSystem=NO
      
    if [ $? -eq 0 ]; then
      echo ""
      echo "✅ IPA exported successfully!"
      echo "📦 IPA location: build/HomeInventoryModular.ipa"
      echo ""
      echo "📤 Upload to TestFlight:"
      echo "   xcrun altool --upload-app -f build/HomeInventoryModular.ipa -u griffinradcliffe@gmail.com -p lyto-qjbu-uffy-hsgb"
    else
      echo "❌ Export failed"
    fi
  else
    echo "❌ Archive failed"
  fi
else
  echo "❌ Build failed"
  echo ""
  echo "This is likely due to Swift 6 package resolution issues."
  echo "Alternative: Use Xcode GUI to build and upload manually."
fi