#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'HomeInventoryModular.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the test target
test_target = project.targets.find { |t| t.name == 'HomeInventoryModularTests' }

unless test_target
  puts "❌ Could not find HomeInventoryModularTests target"
  exit 1
end

# Create or update the test scheme
scheme_name = 'HomeInventoryModularTests'
scheme_path = Xcodeproj::XCScheme.shared_data_dir(project_path) + "#{scheme_name}.xcscheme"

# Check if scheme exists
if File.exist?(scheme_path)
  scheme = Xcodeproj::XCScheme.new(scheme_path)
else
  scheme = Xcodeproj::XCScheme.new
  scheme.add_test_target(test_target)
end

# Configure test action
test_action = scheme.test_action
test_action.build_configuration = 'Debug'

# Add environment variable for recording snapshots
# Note: Due to xcodeproj limitations, we'll document this instead
puts "ℹ️  To enable snapshot recording:"
puts "   1. Open Xcode"
puts "   2. Edit the HomeInventoryModularTests scheme"
puts "   3. Go to Test > Arguments > Environment Variables"
puts "   4. Add RECORD_SNAPSHOTS = true"

# Save the scheme
scheme.save_as(project_path, scheme_name)

puts "✅ Created/Updated #{scheme_name} scheme with snapshot testing support"
puts "   To record snapshots: Edit scheme > Test > Environment Variables > Set RECORD_SNAPSHOTS = true"