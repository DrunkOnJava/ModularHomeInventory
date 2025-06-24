#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'HomeInventoryModular.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the UI test target
ui_test_target = project.targets.find { |t| t.name == 'HomeInventoryModularUITests' }
if ui_test_target.nil?
  puts "❌ Could not find HomeInventoryModularUITests target"
  exit 1
end

# Find the main app target
app_target = project.targets.find { |t| t.name == 'HomeInventoryModular' }
if app_target.nil?
  puts "❌ Could not find HomeInventoryModular target"
  exit 1
end

puts "✅ Found UI test target: #{ui_test_target.name}"
puts "✅ Found app target: #{app_target.name}"

# Fix the test target's dependency and host application
ui_test_target.add_dependency(app_target) unless ui_test_target.dependencies.any? { |d| d.target == app_target }

# Set the correct build settings for UI tests
ui_test_target.build_configurations.each do |config|
  # For UI tests, we should NOT set TEST_HOST or BUNDLE_LOADER
  config.build_settings.delete('TEST_HOST')
  config.build_settings.delete('BUNDLE_LOADER')
  config.build_settings.delete('RUNTIME_TEST_HOST')
  
  # Set the target application
  config.build_settings['TEST_TARGET_NAME'] = app_target.name
  
  # Ensure USES_XCTRUNNER is set for UI tests
  config.build_settings['USES_XCTRUNNER'] = 'YES'
  
  # Ensure the product bundle identifier is set correctly
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.homeinventory.modular.uitests'
  
  # Set the test application bundle identifier
  config.build_settings['TEST_APPLICATION_IDENTIFIER'] = 'com.homeinventory.app'
  
  puts "📝 Updated #{config.name} configuration:"
  puts "   TEST_TARGET_NAME: #{config.build_settings['TEST_TARGET_NAME']}"
  puts "   USES_XCTRUNNER: #{config.build_settings['USES_XCTRUNNER']}"
  puts "   PRODUCT_BUNDLE_IDENTIFIER: #{config.build_settings['PRODUCT_BUNDLE_IDENTIFIER']}"
  puts "   TEST_APPLICATION_IDENTIFIER: #{config.build_settings['TEST_APPLICATION_IDENTIFIER']}"
  puts "   TEST_HOST: #{config.build_settings['TEST_HOST'] || 'nil (removed)'}"
  puts "   BUNDLE_LOADER: #{config.build_settings['BUNDLE_LOADER'] || 'nil (removed)'}"
end

# Save the project
project.save
puts "✅ Project saved successfully!"

# Additional verification
puts "\n🔍 Verifying UI test target type:"
puts "Product type: #{ui_test_target.product_type}"
puts "Expected: com.apple.product-type.bundle.ui-testing"

puts "\n✅ UI test target configuration fixed!"
puts "The UI tests should now run correctly with XCTRunner."