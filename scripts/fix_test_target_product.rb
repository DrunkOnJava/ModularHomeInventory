#!/usr/bin/env ruby

require 'xcodeproj'

PROJECT_PATH = 'HomeInventoryModular.xcodeproj'

puts "🔧 Fixing test target product reference..."

# Open the project
project = Xcodeproj::Project.open(PROJECT_PATH)

# Find test target
test_target = project.targets.find { |t| t.name == 'HomeInventoryModularTests' }

unless test_target
  puts "❌ Test target not found!"
  exit 1
end

puts "✅ Found test target: #{test_target.name}"

# Check if product reference exists
if test_target.product_reference.nil?
  puts "⚠️  Test target has no product reference, creating one..."
  
  # Create a product reference
  products_group = project.products_group
  test_product_ref = products_group.new_reference('HomeInventoryModularTests.xctest')
  test_product_ref.set_explicit_file_type('wrapper.cfbundle')
  test_product_ref.set_source_tree('BUILT_PRODUCTS_DIR')
  
  # Set the product reference
  test_target.product_reference = test_product_ref
  
  puts "✅ Created product reference: HomeInventoryModularTests.xctest"
else
  puts "✅ Test target already has product reference: #{test_target.product_reference.path}"
end

# Ensure test target has proper product type
test_target.product_type = 'com.apple.product-type.bundle.unit-test'

# Update build settings
test_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_NAME'] = 'HomeInventoryModularTests'
  config.build_settings['WRAPPER_EXTENSION'] = 'xctest'
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.homeinventory.app.tests'
  config.build_settings['INFOPLIST_FILE'] = 'HomeInventoryModularTests/Info.plist'
  config.build_settings['TEST_HOST'] = '$(BUILT_PRODUCTS_DIR)/HomeInventoryModular.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/HomeInventoryModular'
  config.build_settings['BUNDLE_LOADER'] = '$(TEST_HOST)'
end

# Save project
project.save

puts "✅ Test target product reference fixed!"
puts ""
puts "Now running scheme configuration..."

# Now run the scheme configuration
require_relative 'configure_xcode_schemes'