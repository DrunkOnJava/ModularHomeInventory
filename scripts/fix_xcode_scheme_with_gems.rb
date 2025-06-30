#!/usr/bin/env ruby

require 'xcodeproj'
require 'fileutils'

PROJECT_PATH = 'HomeInventoryModular.xcodeproj'
SCHEME_NAME = 'HomeInventoryModular'

puts "🔧 Fixing Xcode scheme and test configuration using Ruby gems..."

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

# Ensure scheme directory exists
scheme_dir = File.join(PROJECT_PATH, 'xcshareddata', 'xcschemes')
FileUtils.mkdir_p(scheme_dir)

# Create or update the scheme
scheme_path = File.join(scheme_dir, "#{SCHEME_NAME}.xcscheme")

# Create a new scheme
scheme = Xcodeproj::XCScheme.new

# Configure build action
build_action = scheme.build_action
build_action.add_entry(Xcodeproj::XCScheme::BuildAction::Entry.new(app_target))
build_action.add_entry(Xcodeproj::XCScheme::BuildAction::Entry.new(test_target))

# Configure test action
test_action = scheme.test_action
test_action.code_coverage_enabled = true
test_action.build_configuration = 'Debug'

# Create testable reference for our test target
testable_ref = Xcodeproj::XCScheme::TestAction::TestableReference.new(test_target)
testable_ref.skipped = false
testable_ref.parallelizable = false
testable_ref.randomize_execution_order = false

# Add all test classes
test_classes = []
Dir.glob('HomeInventoryModularTests/**/*.swift').each do |file|
  content = File.read(file)
  # Extract test class names
  content.scan(/class\s+(\w+)\s*:\s*XCTestCase/).each do |match|
    test_classes << match[0]
  end
end

puts "📝 Found #{test_classes.count} test classes"

# Add test classes to testable reference
test_classes.each do |class_name|
  testable_ref.add_test(Xcodeproj::XCScheme::TestAction::TestableReference::Test.new(
    "#{test_target.name}/#{class_name}",
    true # enabled
  ))
end

test_action.add_testable(testable_ref)

# Configure launch action
launch_action = scheme.launch_action
launch_action.build_configuration = 'Debug'
launch_action.buildable_product_runnable = Xcodeproj::XCScheme::BuildableProductRunnable.new(app_target, 0)

# Configure profile action
profile_action = scheme.profile_action
profile_action.build_configuration = 'Release'
profile_action.buildable_product_runnable = Xcodeproj::XCScheme::BuildableProductRunnable.new(app_target, 0)

# Configure analyze action
analyze_action = scheme.analyze_action
analyze_action.build_configuration = 'Debug'

# Configure archive action
archive_action = scheme.archive_action
archive_action.build_configuration = 'Release'
archive_action.reveal_archive_in_organizer = true

# Add environment variables for snapshot recording
test_action.environment_variables = Xcodeproj::XCScheme::EnvironmentVariables.new
test_action.environment_variables['RECORD_SNAPSHOTS'] = { value: 'YES', enabled: true }

# Save the scheme
scheme.save_as(PROJECT_PATH, SCHEME_NAME, true)
puts "✅ Saved scheme: #{scheme_path}"

# Update project to ensure test target has proper settings
test_target.build_configurations.each do |config|
  # Ensure proper bundle loader settings
  config.build_settings['TEST_HOST'] = '$(BUILT_PRODUCTS_DIR)/HomeInventoryModular.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/HomeInventoryModular'
  config.build_settings['BUNDLE_LOADER'] = '$(TEST_HOST)'
  
  # Ensure test target can find the app
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] ||= []
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] << '$(inherited)'
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] << '@executable_path/Frameworks'
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] << '@loader_path/Frameworks'
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'].uniq!
  
  # Enable testability
  config.build_settings['ENABLE_TESTABILITY'] = 'YES'
  
  # Product bundle identifier
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.homeinventory.app.tests'
  
  # Swift version
  config.build_settings['SWIFT_VERSION'] = '5.9'
  
  # iOS deployment target
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
end

# Ensure app target has testability enabled in Debug
app_target.build_configurations.each do |config|
  if config.name == 'Debug'
    config.build_settings['ENABLE_TESTABILITY'] = 'YES'
  end
end

# Save the project
project.save
puts "✅ Updated project settings"

# Create a simple scheme for just running tests
test_scheme_path = File.join(scheme_dir, "#{SCHEME_NAME}-Tests.xcscheme")
test_scheme = Xcodeproj::XCScheme.new

# Configure test-only scheme
test_build_action = test_scheme.build_action
test_build_action.add_entry(Xcodeproj::XCScheme::BuildAction::Entry.new(app_target))
test_build_action.add_entry(Xcodeproj::XCScheme::BuildAction::Entry.new(test_target))

test_test_action = test_scheme.test_action
test_test_action.code_coverage_enabled = false
test_test_action.build_configuration = 'Debug'
test_test_action.add_testable(testable_ref)

# Add environment variables
test_test_action.environment_variables = Xcodeproj::XCScheme::EnvironmentVariables.new
test_test_action.environment_variables['RECORD_SNAPSHOTS'] = { value: 'YES', enabled: true }

test_scheme.save_as(PROJECT_PATH, "#{SCHEME_NAME}-Tests", true)
puts "✅ Created test-only scheme"

puts ""
puts "📋 Summary:"
puts "   - Main scheme updated: #{SCHEME_NAME}"
puts "   - Test scheme created: #{SCHEME_NAME}-Tests"
puts "   - Test classes configured: #{test_classes.count}"
puts "   - Environment variables set: RECORD_SNAPSHOTS=YES"
puts ""
puts "🚀 Schemes are now properly configured!"
puts ""
puts "Try running:"
puts "  xcodebuild test -project #{PROJECT_PATH} -scheme #{SCHEME_NAME} -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max'"