#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'HomeInventoryModular.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main app target
main_target = project.targets.find { |t| t.name == 'HomeInventoryModular' }

unless main_target
  puts "❌ Could not find HomeInventoryModular target"
  exit 1
end

# Check if SwiftLint build phase already exists
existing_phase = main_target.shell_script_build_phases.find { |phase| 
  phase.name == 'SwiftLint' || phase.shell_script.include?('swiftlint')
}

if existing_phase
  puts "⚠️  SwiftLint build phase already exists"
  exit 0
end

# Create SwiftLint build phase
swiftlint_phase = main_target.new_shell_script_build_phase('SwiftLint')

# Set the script
swiftlint_phase.shell_script = <<-SCRIPT
if which swiftlint >/dev/null; then
  swiftlint lint --config "${SRCROOT}/.swiftlint.yml" --quiet --reporter xcode
else
  echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
fi
SCRIPT

# Move it to be before "Compile Sources" phase
compile_phase = main_target.source_build_phase

if compile_phase
  # Get the index of compile phase
  compile_index = main_target.build_phases.index(compile_phase)
  current_index = main_target.build_phases.index(swiftlint_phase)
  
  # Move SwiftLint phase to before compile phase
  if compile_index && current_index && current_index > compile_index
    # Remove from current position
    main_target.build_phases.delete(swiftlint_phase)
    # Insert before compile phase
    main_target.build_phases.insert(compile_index, swiftlint_phase)
  end
end

# Save the project
project.save

puts "✅ SwiftLint build phase added successfully!"
puts "   SwiftLint will now run during every build"