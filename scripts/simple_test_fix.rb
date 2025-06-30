#!/usr/bin/env ruby

require 'xcodeproj'

PROJECT_PATH = 'HomeInventoryModular.xcodeproj'

puts "🔧 Simple test target fix..."

# Open project
project = Xcodeproj::Project.open(PROJECT_PATH)

# Find test target
test_target = project.targets.find { |t| t.name == 'HomeInventoryModularTests' }
unless test_target
  puts "❌ Test target not found!"
  exit 1
end

puts "✅ Found test target"

# Just update the basic settings needed for tests to run
test_target.build_configurations.each do |config|
  # Minimal required settings
  config.build_settings['INFOPLIST_FILE'] = 'HomeInventoryModularTests/Info.plist'
  config.build_settings['TEST_HOST'] = '$(BUILT_PRODUCTS_DIR)/HomeInventoryModular.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/HomeInventoryModular'
  config.build_settings['BUNDLE_LOADER'] = '$(TEST_HOST)'
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks', '@loader_path/Frameworks']
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.homeinventory.app.tests'
  config.build_settings['PRODUCT_NAME'] = 'HomeInventoryModularTests'
  
  puts "  ✓ Updated #{config.name} settings"
end

# Save
project.save

puts "\n✅ Test target settings updated!"
puts "\nNow let's try a manual test run..."

# Create a very simple test runner
simple_runner = <<-BASH
#!/bin/bash

echo "🚀 Simple Test Runner"
echo "===================="

# Clean
echo "🧹 Cleaning derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/HomeInventoryModular-*

# Build
echo "🔨 Building app and tests..."
xcodebuild build-for-testing \\
  -project HomeInventoryModular.xcodeproj \\
  -scheme HomeInventoryModular \\
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \\
  -derivedDataPath build \\
  CODE_SIGN_IDENTITY="" \\
  CODE_SIGNING_REQUIRED=NO \\
  CODE_SIGN_ENTITLEMENTS="" \\
  CODE_SIGNING_ALLOWED=NO

if [ $? -ne 0 ]; then
  echo "❌ Build failed!"
  echo "Trying to diagnose..."
  
  # Try building just the app
  echo "🔨 Building app only..."
  xcodebuild build \\
    -project HomeInventoryModular.xcodeproj \\
    -scheme HomeInventoryModular \\
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \\
    -derivedDataPath build \\
    CODE_SIGN_IDENTITY="" \\
    CODE_SIGNING_REQUIRED=NO
    
  exit 1
fi

echo "✅ Build succeeded!"

# List what was built
echo "📦 Built products:"
find build/Build/Products -name "*.app" -o -name "*.xctest" 2>/dev/null

# Try to run a single test
echo "🧪 Running SimpleSnapshotTest..."
xcodebuild test-without-building \\
  -project HomeInventoryModular.xcodeproj \\
  -scheme HomeInventoryModular \\
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \\
  -derivedDataPath build \\
  -only-testing:HomeInventoryModularTests/SimpleSnapshotTest/testSimpleView \\
  RECORD_SNAPSHOTS=YES

echo "✅ Test run complete!"

# Check for snapshots
echo "📸 Looking for snapshots..."
find . -name "*.png" -path "*__Snapshots__*" 2>/dev/null | sort
BASH

File.write('simple_test_runner.sh', simple_runner)
system('chmod +x simple_test_runner.sh')

puts "\n📝 Created simple_test_runner.sh"
puts "Run: ./simple_test_runner.sh"