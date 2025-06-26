#!/usr/bin/env ruby

require 'xcodeproj'
require 'open3'
require 'json'

class SnapshotTestRunner
  attr_reader :project_path, :record_mode
  
  def initialize(record: false)
    @project_path = 'HomeInventoryModular.xcodeproj'
    @record_mode = record
  end
  
  def run
    puts "🧪 Snapshot Test Runner"
    puts "📸 Record Mode: #{record_mode ? 'ON' : 'OFF'}"
    puts ""
    
    # First, let's just try to build and run our simple test
    run_simple_test
  end
  
  private
  
  def run_simple_test
    puts "🔨 Building and running SimpleSnapshotTest..."
    
    # Simplified xcodebuild command focusing on just one test
    cmd = [
      'xcodebuild', 'test',
      '-project', project_path,
      '-scheme', 'HomeInventoryModular',  # Use main scheme
      '-destination', '"platform=iOS Simulator,name=iPhone 16 Pro Max"',
      '-only-testing:HomeInventoryModularTests/SimpleSnapshotTest',
      record_mode ? 'OTHER_SWIFT_FLAGS="-D RECORD_SNAPSHOTS"' : '',
      '-quiet'
    ].compact.join(' ')
    
    puts "Running: #{cmd}"
    puts ""
    
    success = system(cmd)
    
    if success
      puts "✅ Tests completed!"
      check_snapshots
    else
      puts "❌ Tests failed!"
      
      # Try to run with more verbose output to see the issue
      puts "\n🔍 Running with verbose output..."
      verbose_cmd = cmd.gsub('-quiet', '')
      system("#{verbose_cmd} 2>&1 | tail -100")
    end
  end
  
  def check_snapshots
    puts "\n📁 Checking for snapshots..."
    
    snapshot_files = Dir.glob('**/__Snapshots__/**/*.png')
    
    if snapshot_files.empty?
      puts "No snapshots found yet."
    else
      puts "Found #{snapshot_files.count} snapshot(s):"
      snapshot_files.each do |file|
        size = File.size(file)
        puts "  📸 #{file} (#{size} bytes)"
      end
    end
  end
end

# Run the tests
runner = SnapshotTestRunner.new(record: ARGV.include?('--record'))
runner.run