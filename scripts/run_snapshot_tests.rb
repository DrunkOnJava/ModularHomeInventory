#!/usr/bin/env ruby

require 'open3'
require 'json'
require 'fileutils'

# Configuration
PROJECT = 'HomeInventoryModular.xcodeproj'
SCHEME = 'HomeInventoryModular'
SIMULATOR = 'iPhone 16'
RECORD_MODE = ENV['RECORD_SNAPSHOTS'] == 'true' || ARGV.include?('--record')

puts "🧪 Running Snapshot Tests"
puts "📸 Record Mode: #{RECORD_MODE ? 'ON' : 'OFF'}"
puts ""

# Build the test target first
puts "🔨 Building test target..."
build_cmd_parts = [
  'xcodebuild', 'build-for-testing',
  '-project', PROJECT,
  '-scheme', SCHEME,
  '-destination', "platform=iOS Simulator,name=#{SIMULATOR}",
  '-derivedDataPath', 'build'
]
puts "Debug: Running command: #{build_cmd_parts.inspect}"

stdout, stderr, status = Open3.capture3(*build_cmd_parts)
unless status.success?
  puts "❌ Build failed!"
  puts stderr
  exit 1
end

puts "✅ Build succeeded!"

# Find the test bundle
derived_data = `xcodebuild -project #{PROJECT} -showBuildSettings | grep -m 1 BUILT_PRODUCTS_DIR`.strip.split(' = ').last
test_bundle = "#{derived_data}/HomeInventoryModularTests.xctest"

puts "📦 Test bundle: #{test_bundle}"

# Run the tests
puts "🏃 Running tests..."

# Set environment variable for recording
ENV['RECORD_SNAPSHOTS'] = 'true' if RECORD_MODE

test_cmd_parts = [
  'xcodebuild', 'test-without-building',
  '-project', PROJECT,
  '-scheme', SCHEME,
  '-destination', "platform=iOS Simulator,name=#{SIMULATOR}",
  '-derivedDataPath', 'build',
  '-only-testing:HomeInventoryModularTests'
]
test_cmd_parts << '-DRECORD_SNAPSHOTS' if RECORD_MODE
# Parse test output
test_output = []
test_failures = []
snapshot_recordings = []

IO.popen(test_cmd_parts) do |io|
  io.each_line do |line|
    # Clean up xcodebuild noise
    next if line.include?('IDETestOperationsObserverDebug')
    next if line.include?('DTDeviceKit')
    
    # Track test results
    if line.include?('Test Case')
      if line.include?('passed')
        print "✅"
        test_output << line.strip
      elsif line.include?('failed')
        print "❌"
        test_failures << line.strip
        test_output << line.strip
      end
    elsif line.include?('Recording snapshot')
      print "📸"
      snapshot_recordings << line.strip
    elsif line.include?('error:') || line.include?('failed:')
      test_failures << line.strip
    end
  end
end

puts "\n\n📊 Test Summary:"
puts "=================="

if RECORD_MODE && snapshot_recordings.any?
  puts "📸 Recorded #{snapshot_recordings.count} snapshots"
  snapshot_recordings.each { |s| puts "  #{s}" }
end

if test_failures.any?
  puts "❌ #{test_failures.count} failures:"
  test_failures.each { |f| puts "  #{f}" }
  exit 1
else
  puts "✅ All tests passed!"
end

# Find and display snapshot locations
snapshot_dirs = Dir.glob('**/__Snapshots__')
if snapshot_dirs.any?
  puts "\n📁 Snapshot locations:"
  snapshot_dirs.each do |dir|
    count = Dir.glob("#{dir}/*.png").count
    puts "  #{dir} (#{count} images)"
  end
end