#!/usr/bin/env ruby

require 'xcodeproj'

# Update the scheme to include the unit test target
project_path = 'HomeInventoryModular.xcodeproj'
scheme_name = 'HomeInventoryModular'

puts "📋 Updating scheme to include test targets..."

# Find scheme file
scheme_dir = "#{project_path}/xcshareddata/xcschemes"
scheme_file = "#{scheme_dir}/#{scheme_name}.xcscheme"

unless File.exist?(scheme_file)
  # Create the directory if it doesn't exist
  require 'fileutils'
  FileUtils.mkdir_p(scheme_dir)
  
  # Create a new scheme
  project = Xcodeproj::Project.open(project_path)
  app_target = project.targets.find { |t| t.name == 'HomeInventoryModular' }
  test_target = project.targets.find { |t| t.name == 'HomeInventoryModularTests' }
  ui_test_target = project.targets.find { |t| t.name == 'HomeInventoryModularUITests' }
  
  scheme = Xcodeproj::XCScheme.new
  scheme.configure_with_targets(app_target, test_target)
  
  # Add UI test target
  if ui_test_target
    test_action = scheme.test_action
    ui_testable = Xcodeproj::XCScheme::TestAction::TestableReference.new(ui_test_target)
    test_action.add_testable(ui_testable)
  end
  
  scheme.save_as(project_path, scheme_name)
  puts "✅ Created new scheme with test targets"
else
  # Update existing scheme
  scheme = Xcodeproj::XCScheme.new(scheme_file)
  test_action = scheme.test_action
  
  # Check if HomeInventoryModularTests is already in the scheme
  has_unit_tests = test_action.testables.any? do |testable|
    testable.buildable_references.any? { |ref| ref.target_name == 'HomeInventoryModularTests' }
  end
  
  unless has_unit_tests
    project = Xcodeproj::Project.open(project_path)
    test_target = project.targets.find { |t| t.name == 'HomeInventoryModularTests' }
    
    if test_target
      testable = Xcodeproj::XCScheme::TestAction::TestableReference.new(test_target)
      test_action.add_testable(testable)
      scheme.save!
      puts "✅ Added HomeInventoryModularTests to scheme"
    else
      puts "❌ Could not find HomeInventoryModularTests target"
    end
  else
    puts "✅ HomeInventoryModularTests already in scheme"
  end
end

puts "🎯 Scheme update complete!"