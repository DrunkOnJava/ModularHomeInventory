#!/usr/bin/env ruby

require 'fileutils'
require 'open3'

# Configuration
PROJECT = 'HomeInventoryModular.xcodeproj'
SCHEME = 'HomeInventoryModular'
SIMULATOR = 'iPhone 16'
DESTINATION = "platform=iOS Simulator,name=#{SIMULATOR}"

puts "🧪 Simple Snapshot Test Runner"
puts "=============================="
puts ""

# Clean derived data
puts "🧹 Cleaning derived data..."
system("rm -rf ~/Library/Developer/Xcode/DerivedData/HomeInventoryModular-*")

# Set environment for recording
ENV['RECORD_SNAPSHOTS'] = 'true'

# Build command parts
build_cmd_parts = [
  'xcodebuild', 
  '-project', PROJECT,
  '-scheme', SCHEME,
  '-destination', DESTINATION,
  'test',
  '-only-testing:HomeInventoryModularTests/SharedUI',
  'SWIFT_TREAT_WARNINGS_AS_ERRORS=NO',
  'GCC_TREAT_WARNINGS_AS_ERRORS=NO'
]

puts "🔨 Building and testing..."
puts "Command: #{build_cmd_parts.join(' ')}"
puts ""

# Run the build/test command
stdout, stderr, status = Open3.capture3(*build_cmd_parts)
success = status.success?

unless success
  puts stderr
end

if success
  puts ""
  puts "✅ Tests completed!"
  
  # Find and list snapshots
  puts ""
  puts "📸 Generated snapshots:"
  Dir.glob("HomeInventoryModularTests/**/__Snapshots__/**/*.png").sort.each do |file|
    puts "  ✓ #{file}"
  end
else
  puts ""
  puts "❌ Tests failed!"
end