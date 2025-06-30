#!/usr/bin/env ruby

require 'xcodeproj'
require 'fileutils'

PROJECT_PATH = 'HomeInventoryModular.xcodeproj'

puts "🔧 Final build settings fix..."

# Open the project
project = Xcodeproj::Project.open(PROJECT_PATH)

# Find targets
app_target = project.targets.find { |t| t.name == 'HomeInventoryModular' }
test_target = project.targets.find { |t| t.name == 'HomeInventoryModularTests' }

unless app_target && test_target
  puts "❌ Required targets not found!"
  exit 1
end

puts "✅ Found targets"

# Fix test target
puts "\n🧪 Configuring test target..."

# Basic build settings
test_target.build_configurations.each do |config|
  settings = {
    'PRODUCT_NAME' => 'HomeInventoryModularTests',
    'PRODUCT_BUNDLE_IDENTIFIER' => 'com.homeinventory.app.tests',
    'INFOPLIST_FILE' => 'HomeInventoryModularTests/Info.plist',
    'SWIFT_VERSION' => '5.9',
    'IPHONEOS_DEPLOYMENT_TARGET' => '17.0',
    'TEST_HOST' => '$(BUILT_PRODUCTS_DIR)/HomeInventoryModular.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/HomeInventoryModular',
    'BUNDLE_LOADER' => '$(TEST_HOST)',
    'LD_RUNPATH_SEARCH_PATHS' => ['$(inherited)', '@executable_path/Frameworks', '@loader_path/Frameworks'],
    'FRAMEWORK_SEARCH_PATHS' => ['$(inherited)', '$(PLATFORM_DIR)/Developer/Library/Frameworks'],
    'ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES' => 'YES',
    'CLANG_ENABLE_MODULES' => 'YES',
    'SWIFT_OPTIMIZATION_LEVEL' => '-Onone',
    'ENABLE_TESTABILITY' => 'YES',
    'CODE_SIGN_STYLE' => 'Automatic'
  }
  
  settings.each do |key, value|
    config.build_settings[key] = value
  end
  
  puts "  ✓ #{config.name} settings updated"
end

# Add package product dependencies manually
puts "\n📦 Adding package dependencies..."

# Check if test target already has SnapshotTesting
has_snapshot_testing = test_target.package_product_dependencies.any? { |dep|
  dep.product_name == 'SnapshotTesting'
}

unless has_snapshot_testing
  # Create new package product dependency
  snapshot_dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  snapshot_dep.product_name = 'SnapshotTesting'
  
  # Find the package reference by looking for swift-snapshot-testing
  package_ref = project.root_object.package_references.find { |ref|
    ref.class == Xcodeproj::Project::Object::XCRemoteSwiftPackageReference &&
    ref.remote_ref && ref.remote_ref.include?('swift-snapshot-testing')
  }
  
  if package_ref
    snapshot_dep.package = package_ref
    test_target.package_product_dependencies << snapshot_dep
    puts "  ✓ Added SnapshotTesting dependency"
  else
    puts "  ⚠️  Could not find swift-snapshot-testing package reference"
  end
end

# Ensure frameworks build phase exists
unless test_target.frameworks_build_phase
  test_target.new_frameworks_build_phase
  puts "  ✓ Created frameworks build phase"
end

# Clean up source build phase
puts "\n🧹 Cleaning source files..."
files_to_remove = []
test_target.source_build_phase.files.each do |file|
  if file.file_ref.nil? || !File.exist?(file.file_ref.real_path.to_s)
    files_to_remove << file
  end
end

files_to_remove.each do |file|
  test_target.source_build_phase.files.delete(file)
end
puts "  ✓ Removed #{files_to_remove.count} invalid files"

# Update app target for testability
puts "\n📱 Ensuring app target testability..."
app_target.build_configurations.each do |config|
  if config.name == 'Debug'
    config.build_settings['ENABLE_TESTABILITY'] = 'YES'
    puts "  ✓ Enabled testability for #{config.name}"
  end
end

# Save
project.save
puts "\n✅ Build configuration complete!"

# Now let's create a simple build script
puts "\n📝 Creating build verification script..."

build_script = <<-SCRIPT
#!/bin/bash

echo "🧹 Cleaning..."
rm -rf ~/Library/Developer/Xcode/DerivedData/HomeInventoryModular-*

echo "🔨 Building app..."
xcodebuild build \\
  -project HomeInventoryModular.xcodeproj \\
  -scheme HomeInventoryModular \\
  -sdk iphonesimulator \\
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \\
  -quiet || { echo "❌ App build failed"; exit 1; }

echo "✅ App built successfully!"

echo "🧪 Building tests..."
xcodebuild build-for-testing \\
  -project HomeInventoryModular.xcodeproj \\
  -scheme HomeInventoryModular \\
  -sdk iphonesimulator \\
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \\
  -quiet || { echo "❌ Test build failed"; exit 1; }

echo "✅ Tests built successfully!"

echo "🏃 Running tests..."
xcodebuild test-without-building \\
  -project HomeInventoryModular.xcodeproj \\
  -scheme HomeInventoryModular \\
  -sdk iphonesimulator \\
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \\
  RECORD_SNAPSHOTS=YES \\
  -quiet || echo "⚠️  Some tests may have failed"

echo "📸 Looking for snapshots..."
find HomeInventoryModularTests -name "*.png" -path "*__Snapshots__*" | wc -l
SCRIPT

File.write('verify_build.sh', build_script)
FileUtils.chmod(0755, 'verify_build.sh')
puts "  ✓ Created verify_build.sh"

puts "\n🚀 Next step: Run ./verify_build.sh to test the configuration"