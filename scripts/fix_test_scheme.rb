#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'HomeInventoryModular.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find targets
app_target = project.targets.find { |t| t.name == 'HomeInventoryModular' }
test_target = project.targets.find { |t| t.name == 'HomeInventoryModularTests' }

unless app_target && test_target
  puts "❌ Could not find required targets"
  exit 1
end

# Update the main scheme to include tests
scheme_path = Xcodeproj::XCScheme.shared_data_dir(project_path) + "HomeInventoryModular.xcscheme"

if File.exist?(scheme_path)
  scheme = Xcodeproj::XCScheme.new(scheme_path)
  
  # Add test target to test action
  test_action = scheme.test_action
  
  # Check if test target is already added
  has_test_target = test_action.testables.any? { |t| 
    t.buildable_references.any? { |ref| ref.target_name == 'HomeInventoryModularTests' }
  }
  
  unless has_test_target
    testable = Xcodeproj::XCScheme::TestAction::TestableReference.new(test_target)
    testable.skipped = false
    test_action.add_testable(testable)
    puts "✅ Added HomeInventoryModularTests to scheme"
  end
  
  # Ensure build configuration is Debug
  test_action.build_configuration = 'Debug'
  
  # Save the scheme
  scheme.save!
  puts "✅ Updated HomeInventoryModular scheme"
else
  puts "❌ Scheme file not found"
end

puts "\n📋 Next step: Run 'make test-snapshots' or 'make record-snapshots'"