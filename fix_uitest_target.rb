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

# Set the TEST_TARGET_NAME build setting to point to the app
ui_test_target.build_configurations.each do |config|
  config.build_settings['TEST_TARGET_NAME'] = app_target.name
  config.build_settings['BUNDLE_LOADER'] = "$(TEST_HOST)"
  config.build_settings['TEST_HOST'] = "$(BUILT_PRODUCTS_DIR)/#{app_target.name}.app/#{app_target.name}"
  
  # Ensure the product bundle identifier is set correctly
  if config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] != 'com.homeinventory.modular.uitests'
    config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.homeinventory.modular.uitests'
  end
  
  puts "📝 Updated #{config.name} configuration:"
  puts "   TEST_TARGET_NAME: #{config.build_settings['TEST_TARGET_NAME']}"
  puts "   PRODUCT_BUNDLE_IDENTIFIER: #{config.build_settings['PRODUCT_BUNDLE_IDENTIFIER']}"
end

# Save the project
project.save
puts "✅ Project saved successfully!"

# Verify the settings
puts "\n🔍 Verifying UI test target settings:"
ui_test_target.build_configurations.each do |config|
  puts "\nConfiguration: #{config.name}"
  puts "  TEST_TARGET_NAME: #{config.build_settings['TEST_TARGET_NAME']}"
  puts "  PRODUCT_BUNDLE_IDENTIFIER: #{config.build_settings['PRODUCT_BUNDLE_IDENTIFIER']}"
  puts "  TEST_HOST: #{config.build_settings['TEST_HOST']}"
  puts "  BUNDLE_LOADER: #{config.build_settings['BUNDLE_LOADER']}"
end

puts "\n✅ UI test target configuration fixed!"
puts "The UI tests should now launch the app (com.homeinventory.app) instead of trying to launch the test bundle."