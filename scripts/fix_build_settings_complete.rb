#!/usr/bin/env ruby

require 'xcodeproj'
require 'fileutils'

PROJECT_PATH = 'HomeInventoryModular.xcodeproj'

puts "🔧 Comprehensive build settings fix..."

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
  
  puts "  ✓ Updated #{config.name} configuration"
end

# Fix test target settings
puts "\n🧪 Fixing test target build settings..."

# Ensure test target has proper product reference
if test_target.product_reference.nil?
  products_group = project.products_group
  test_product_ref = products_group.new_reference('HomeInventoryModularTests.xctest')
  test_product_ref.set_explicit_file_type('wrapper.cfbundle')
  test_product_ref.set_source_tree('BUILT_PRODUCTS_DIR')
  test_target.product_reference = test_product_ref
  puts "  ✓ Created product reference"
end

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
    '$(PLATFORM_DIR)/Developer/Library/Frameworks'
  ]
  
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = [
    '$(inherited)',
    '@executable_path/Frameworks',
    '@loader_path/Frameworks'
  ]
  
  # Swift settings
  config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
  config.build_settings['ENABLE_TESTABILITY'] = 'YES'
  config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'YES'
  config.build_settings['CLANG_ENABLE_MODULES'] = 'YES'
  
  # Test specific settings
  config.build_settings['WRAPPER_EXTENSION'] = 'xctest'
  
  # Module settings  
  config.build_settings['PRODUCT_MODULE_NAME'] = 'HomeInventoryModularTests'
  
  puts "  ✓ Updated #{config.name} configuration"
end

# Fix framework dependencies
puts "\n📦 Fixing framework dependencies..."

# Ensure test target has frameworks build phase
unless test_target.frameworks_build_phase
  test_target.new_frameworks_build_phase
  puts "  ✓ Created frameworks build phase"
end

# Look for SnapshotTesting in the project
frameworks_group = project.frameworks_group
main_group = project.main_group

# Try to find SnapshotTesting reference
snapshot_ref = nil
project.files.each do |file|
  if file.path && file.path.include?('SnapshotTesting')
    snapshot_ref = file
    break
  end
end

if snapshot_ref
  unless test_target.frameworks_build_phase.files_references.include?(snapshot_ref)
    test_target.frameworks_build_phase.add_file_reference(snapshot_ref)
    puts "  ✓ Added SnapshotTesting framework reference"
  end
end

# Add package dependencies to test target
puts "\n📚 Configuring package dependencies..."

# Ensure test target has package product dependencies
test_target.package_product_dependencies.clear
package_refs = project.root_object.package_references || []

# Find swift-snapshot-testing package
snapshot_package = package_refs.find { |ref| 
  ref.requirement && ref.requirement['repositoryURL'] && 
  ref.requirement['repositoryURL'].include?('swift-snapshot-testing')
}

if snapshot_package
  # Create package product dependency
  product_dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  product_dep.package = snapshot_package
  product_dep.product_name = 'SnapshotTesting'
  
  test_target.package_product_dependencies << product_dep
  puts "  ✓ Added SnapshotTesting package dependency"
end

# Clean up build phases
puts "\n🧹 Cleaning build phases..."

# Remove any nil or invalid file references
test_target.source_build_phase.files.select { |f| f.file_ref.nil? }.each do |f|
  test_target.source_build_phase.files.delete(f)
end

# Remove duplicates
seen_files = Set.new
test_target.source_build_phase.files.select do |f|
  if f.file_ref && f.file_ref.path
    if seen_files.include?(f.file_ref.path)
      test_target.source_build_phase.files.delete(f)
      false
    else
      seen_files.add(f.file_ref.path)
      true
    end
  else
    false
  end
end

puts "  ✓ Cleaned build phases"

# Ensure project settings
puts "\n⚙️  Updating project settings..."

project.build_configurations.each do |config|
  config.build_settings['SWIFT_VERSION'] = '5.9'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
  config.build_settings['ALWAYS_SEARCH_USER_PATHS'] = 'NO'
  config.build_settings['CLANG_ANALYZER_NONNULL'] = 'YES'
  config.build_settings['CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION'] = 'YES_AGGRESSIVE'
  config.build_settings['CLANG_ENABLE_MODULES'] = 'YES'
  config.build_settings['CLANG_ENABLE_OBJC_ARC'] = 'YES'
  config.build_settings['ENABLE_STRICT_OBJC_MSGSEND'] = 'YES'
  config.build_settings['GCC_NO_COMMON_BLOCKS'] = 'YES'
  
  if config.name == 'Debug'
    config.build_settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf'
    config.build_settings['ENABLE_TESTABILITY'] = 'YES'
    config.build_settings['GCC_DYNAMIC_NO_PIC'] = 'NO'
    config.build_settings['GCC_OPTIMIZATION_LEVEL'] = '0'
    config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
    config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
  else
    config.build_settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf-with-dsym'
    config.build_settings['ENABLE_NS_ASSERTIONS'] = 'NO'
    config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-O'
  end
end

puts "  ✓ Updated project settings"

# Save project
project.save

puts "\n✅ Build settings completely fixed!"
puts "\n📋 Final configuration:"
puts "   - App target: HomeInventoryModular"
puts "   - Test target: HomeInventoryModularTests"
puts "   - Swift version: 5.9"
puts "   - iOS deployment target: 17.0"
puts "   - Package dependencies: configured"
puts "   - Build phases: cleaned"
puts "\n🚀 Ready to build and test!"