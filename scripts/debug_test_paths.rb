#!/usr/bin/env ruby

require 'xcodeproj'

PROJECT_PATH = 'HomeInventoryModular.xcodeproj'

puts "🔍 Debugging test file paths..."

# Open project
project = Xcodeproj::Project.open(PROJECT_PATH)

# Find test target
test_target = project.targets.find { |t| t.name == 'HomeInventoryModularTests' }
unless test_target
  puts "❌ Test target not found!"
  exit 1
end

# Find test group
test_group = project.main_group['HomeInventoryModularTests']

puts "\n📁 Test group structure:"
def print_group(group, indent = 0)
  prefix = "  " * indent
  puts "#{prefix}[GROUP] #{group.path || group.name}"
  group.children.each do |child|
    if child.is_a?(Xcodeproj::Project::Object::PBXGroup)
      print_group(child, indent + 1)
    elsif child.is_a?(Xcodeproj::Project::Object::PBXFileReference)
      puts "#{prefix}  [FILE] #{child.path} (real_path: #{child.real_path})"
    end
  end
end
print_group(test_group)

puts "\n🔧 Build phase files:"
test_target.source_build_phase.files.each do |file|
  if file.file_ref
    puts "  - #{file.file_ref.path} (real_path: #{file.file_ref.real_path})"
  end
end

puts "\n📍 Actual file locations:"
Dir.glob("HomeInventoryModularTests/**/*.swift").each do |path|
  puts "  - #{path}"
end