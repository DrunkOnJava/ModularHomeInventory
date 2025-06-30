#!/usr/bin/env ruby

require 'open3'
require 'fileutils'

# Clean up
puts "🧹 Cleaning..."
system("rm -rf ~/Library/Developer/Xcode/DerivedData/HomeInventoryModular-*")
system("rm -rf build/")

# Set up environment
ENV['RECORD_SNAPSHOTS'] = 'true'

# Simple test command
cmd = %w[
  xcodebuild test
  -project HomeInventoryModular.xcodeproj
  -scheme HomeInventoryModular
  -sdk iphonesimulator
  -destination platform=iOS\ Simulator,name=iPhone\ 16
  RECORD_SNAPSHOTS=YES
  -quiet
]

puts "🔨 Running tests..."
puts "Command: #{cmd.join(' ')}"

# Run the command
success = system(*cmd)

if success
  puts "\n✅ Tests completed!"
  
  # Find and display snapshots
  snapshots = Dir.glob("HomeInventoryModularTests/**/__Snapshots__/**/*.png")
  
  puts "\n📸 Generated #{snapshots.count} snapshots:"
  snapshots.sort.each do |snap|
    puts "  ✓ #{snap}"
  end
else
  puts "\n❌ Tests failed!"
  puts "Try running in Xcode instead"
end