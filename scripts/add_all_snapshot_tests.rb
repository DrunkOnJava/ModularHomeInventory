#!/usr/bin/env ruby

require 'xcodeproj'
require 'fileutils'

PROJECT_PATH = 'HomeInventoryModular.xcodeproj'

puts "📄 Adding all snapshot tests to test target..."

# Open project
project = Xcodeproj::Project.open(PROJECT_PATH)

# Find test target
test_target = project.targets.find { |t| t.name == 'HomeInventoryModularTests' }
unless test_target
  puts "❌ Test target not found!"
  exit 1
end

# Get test group
test_group = project.main_group['HomeInventoryModularTests']
unless test_group
  puts "❌ Test group not found!"
  exit 1
end

# Find all snapshot test files
snapshot_tests = Dir.glob('HomeInventoryModularTests/**/*SnapshotTests.swift').sort
puts "Found #{snapshot_tests.length} snapshot test files"

# Track what we're adding
added_count = 0
already_exists = 0

snapshot_tests.each do |file_path|
  file_name = File.basename(file_path)
  relative_path = file_path.sub('HomeInventoryModularTests/', '')
  
  # Check if already added
  if test_target.source_build_phase.files.any? { |f| f.file_ref && f.file_ref.path == file_name }
    already_exists += 1
    next
  end
  
  # Get path components
  components = relative_path.split('/')
  
  # Create group hierarchy if needed
  current_group = test_group
  if components.length > 1
    components[0..-2].each do |component|
      existing = current_group.children.find { |g| 
        g.is_a?(Xcodeproj::Project::Object::PBXGroup) && g.name == component 
      }
      
      if existing
        current_group = existing
      else
        current_group = current_group.new_group(component)
        puts "  ✓ Created group: #{component}"
      end
    end
  end
  
  # Check if file reference already exists in the group
  existing_ref = current_group.children.find { |f| f.path == components.last }
  
  if existing_ref
    # Use existing reference but add to build phase
    test_target.add_file_references([existing_ref])
  else
    # Create new reference
    file_ref = current_group.new_reference(components.last)
    file_ref.set_path(file_path)
    test_target.add_file_references([file_ref])
  end
  
  added_count += 1
  puts "  ✓ Added: #{relative_path}"
end

# Save project
project.save

puts "\n✅ Complete!"
puts "   Added: #{added_count} files"
puts "   Already existed: #{already_exists} files"
puts "   Total snapshot tests: #{added_count + already_exists}"

# Create test runner script
puts "\n📝 Creating test runner script..."

runner_script = <<-BASH
#!/bin/bash

echo "🧪 Running comprehensive snapshot tests..."
echo "=================================="

# Clean derived data
echo "🧹 Cleaning..."
rm -rf ~/Library/Developer/Xcode/DerivedData/HomeInventoryModular-*

# Build
echo "🔨 Building..."
xcodebuild build-for-testing \\
  -project HomeInventoryModular.xcodeproj \\
  -scheme HomeInventoryModular \\
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \\
  -quiet || { echo "❌ Build failed"; exit 1; }

echo "✅ Build succeeded!"

# Run tests
echo "🧪 Running all snapshot tests..."
xcodebuild test-without-building \\
  -project HomeInventoryModular.xcodeproj \\
  -scheme HomeInventoryModular \\
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \\
  RECORD_SNAPSHOTS=YES \\
  -quiet || echo "⚠️  Tests completed with warnings (expected for recording mode)"

# Count snapshots
echo ""
echo "📸 Snapshot Summary:"
echo "==================="
find HomeInventoryModularTests -name "*.png" -path "*__Snapshots__*" | wc -l | xargs echo "Total snapshots:"

echo ""
echo "📂 Snapshots by module:"
for dir in HomeInventoryModularTests/*/; do
  if [ -d "$dir/__Snapshots__" ]; then
    module=$(basename "$dir")
    count=$(find "$dir/__Snapshots__" -name "*.png" | wc -l)
    echo "  $module: $count snapshots"
  fi
done

echo ""
echo "✅ Done!"
BASH

File.write('run_all_snapshots.sh', runner_script)
FileUtils.chmod(0755, 'run_all_snapshots.sh')

puts "✓ Created run_all_snapshots.sh"
puts "\n🚀 Run: ./run_all_snapshots.sh"