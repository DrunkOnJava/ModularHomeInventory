#!/usr/bin/env ruby

require 'xcodeproj'
require 'fileutils'

PROJECT_PATH = 'HomeInventoryModular.xcodeproj'

puts "🔧 Comprehensive build settings fix using Ruby gems..."

# Open the project
project = Xcodeproj::Project.open(PROJECT_PATH)

# Find targets
app_target = project.targets.find { |t| t.name == 'HomeInventoryModular' }
test_target = project.targets.find { |t| t.name == 'HomeInventoryModularTests' }

unless app_target && test_target
  puts "❌ Required targets not found!"
  exit 1
end

puts "✅ Found targets: #{app_target.name}, #{test_target.name}"

# Fix app target settings
puts "\n📱 Fixing app target build settings..."
app_target.build_configurations.each do |config|
  # Basic settings
  config.build_settings['PRODUCT_NAME'] = 'HomeInventoryModular'
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.homeinventory.app'
  config.build_settings['INFOPLIST_FILE'] = 'HomeInventoryModular/Info.plist'
  config.build_settings['SWIFT_VERSION'] = '5.9'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  
  # Module settings
  config.build_settings['DEFINES_MODULE'] = 'YES'
  config.build_settings['PRODUCT_MODULE_NAME'] = 'HomeInventoryModular'
  
  # Enable testability for Debug
  if config.name == 'Debug'
    config.build_settings['ENABLE_TESTABILITY'] = 'YES'
    config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
    config.build_settings['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = 'DEBUG'
  end
  
  # Framework search paths
  config.build_settings['FRAMEWORK_SEARCH_PATHS'] = [
    '$(inherited)',
    '$(PROJECT_DIR)/build/Build/Products/$(CONFIGURATION)-$(PLATFORM_NAME)'
  ]
  
  # Swift settings
  config.build_settings['SWIFT_EMIT_LOC_STRINGS'] = 'YES'
  config.build_settings['CLANG_ENABLE_MODULES'] = 'YES'
  config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone' if config.name == 'Debug'
  
  puts "  ✓ Updated #{config.name} configuration"
end

# Fix test target settings
puts "\n🧪 Fixing test target build settings..."

# Ensure test target product type
test_target.product_type = 'com.apple.product-type.bundle.unit-test'

test_target.build_configurations.each do |config|
  # Basic settings
  config.build_settings['PRODUCT_NAME'] = 'HomeInventoryModularTests'
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.homeinventory.app.tests'
  config.build_settings['INFOPLIST_FILE'] = 'HomeInventoryModularTests/Info.plist'
  config.build_settings['SWIFT_VERSION'] = '5.9'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
  
  # Test host settings
  config.build_settings['TEST_HOST'] = '$(BUILT_PRODUCTS_DIR)/HomeInventoryModular.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/HomeInventoryModular'
  config.build_settings['BUNDLE_LOADER'] = '$(TEST_HOST)'
  
  # Framework and library search paths
  config.build_settings['FRAMEWORK_SEARCH_PATHS'] = [
    '$(inherited)',
    '$(PLATFORM_DIR)/Developer/Library/Frameworks',
    '$(PROJECT_DIR)/build/Build/Products/$(CONFIGURATION)-$(PLATFORM_NAME)'
  ]
  
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = [
    '$(inherited)',
    '@executable_path/Frameworks',
    '@loader_path/Frameworks',
    '$(FRAMEWORK_SEARCH_PATHS)'
  ]
  
  # Swift settings
  config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
  config.build_settings['ENABLE_TESTABILITY'] = 'YES'
  config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'YES'
  config.build_settings['CLANG_ENABLE_MODULES'] = 'YES'
  config.build_settings['DEFINES_MODULE'] = 'NO'
  
  # Test specific settings
  config.build_settings['WRAPPER_EXTENSION'] = 'xctest'
  config.build_settings['USES_XCTRUNNER'] = 'YES'
  
  # Debug settings
  if config.name == 'Debug'
    config.build_settings['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = 'DEBUG'
    config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] = ['DEBUG=1', '$(inherited)']
    config.build_settings['OTHER_SWIFT_FLAGS'] = '$(inherited) -D DEBUG'
  end
  
  # Code signing
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
  config.build_settings['DEVELOPMENT_TEAM'] = ''
  
  puts "  ✓ Updated #{config.name} configuration"
end

# Ensure proper dependencies
puts "\n🔗 Verifying dependencies..."
unless test_target.dependencies.any? { |d| d.target == app_target }
  test_target.add_dependency(app_target)
  puts "  ✓ Added app target dependency"
else
  puts "  ✓ App target dependency exists"
end

# Add SnapshotTesting framework
puts "\n📦 Configuring frameworks..."

# Check if SnapshotTesting is in frameworks build phase
frameworks_phase = test_target.frameworks_build_phase
snapshot_framework_found = false

# Look for SnapshotTesting in package products
package_products = project.root_object.package_references.flat_map { |ref| 
  ref.package_products 
}.compact

snapshot_product = package_products.find { |p| p.product_name == 'SnapshotTesting' }

if snapshot_product
  # Check if already added
  unless frameworks_phase.files_references.any? { |ref| ref.display_name == 'SnapshotTesting' }
    frameworks_phase.add_file_reference(snapshot_product)
    puts "  ✓ Added SnapshotTesting framework"
  else
    puts "  ✓ SnapshotTesting framework already linked"
  end
else
  puts "  ⚠️  SnapshotTesting package product not found - will be resolved at build time"
end

# Ensure all test files are properly added
puts "\n📄 Verifying test files..."
test_files_count = 0
missing_files = []

Dir.glob('HomeInventoryModularTests/**/*.swift').each do |file_path|
  next if file_path.include?('__Snapshots__')
  
  file_name = File.basename(file_path)
  found = test_target.source_build_phase.files_references.any? { |ref| 
    ref.file_ref && ref.file_ref.path && ref.file_ref.path.include?(file_name)
  }
  
  if found
    test_files_count += 1
  else
    missing_files << file_path
  end
end

puts "  ✓ #{test_files_count} test files verified"
if missing_files.any?
  puts "  ⚠️  #{missing_files.count} files may be missing from build phase"
end

# Create proper Info.plist if missing
info_plist_path = 'HomeInventoryModularTests/Info.plist'
unless File.exist?(info_plist_path)
  puts "\n📝 Creating Info.plist..."
  FileUtils.mkdir_p('HomeInventoryModularTests')
  
  info_plist_content = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
</dict>
</plist>
XML
  
  File.write(info_plist_path, info_plist_content)
  puts "  ✓ Created Info.plist"
end

# Save project
project.save

puts "\n✅ Build settings fixed!"
puts "\n📋 Summary:"
puts "   - App target: configured for testing"
puts "   - Test target: configured with proper settings"
puts "   - Dependencies: verified"
puts "   - Frameworks: configured"
puts "   - Test files: #{test_files_count} verified"
puts "\n🚀 Project should now build successfully!"