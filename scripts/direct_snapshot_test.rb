#!/usr/bin/env ruby

require 'fileutils'
require 'open3'

class DirectSnapshotTest
  def initialize(record_mode: false)
    @record_mode = record_mode
  end
  
  def run
    puts "🧪 Direct Snapshot Test Runner"
    puts "📸 Record Mode: #{@record_mode}"
    puts ""
    
    # Step 1: Clean and build
    puts "🔨 Building project..."
    build_success = build_project
    
    unless build_success
      puts "❌ Build failed!"
      return false
    end
    
    # Step 2: Run tests on the main scheme with test target included
    puts "\n🏃 Running tests..."
    run_tests
  end
  
  private
  
  def build_project
    cmd = %Q{
      xcodebuild clean build \
        -project HomeInventoryModular.xcodeproj \
        -scheme HomeInventoryModular \
        -configuration Debug \
        -destination 'generic/platform=iOS Simulator' \
        -derivedDataPath build \
        SWIFT_STRICT_CONCURRENCY=minimal \
        2>&1
    }.strip.gsub(/\s+/, ' ')
    
    output = []
    success = true
    
    IO.popen(cmd) do |io|
      io.each_line do |line|
        if line.include?('BUILD SUCCEEDED')
          print "✅"
        elsif line.include?('BUILD FAILED')
          print "❌"
          success = false
        elsif line.include?('error:')
          output << line
          print "❌"
        elsif line.include?('Compiling')
          print "."
        end
      end
    end
    
    puts ""
    
    unless success
      puts "\nBuild errors:"
      output.each { |line| puts line }
    end
    
    success
  end
  
  def run_tests
    # Get simulator ID
    simulator_id = get_simulator_id
    
    unless simulator_id
      puts "❌ Could not find simulator"
      return false
    end
    
    puts "📱 Using simulator: #{simulator_id}"
    
    # Boot simulator if needed
    system("xcrun simctl boot #{simulator_id} 2>/dev/null || true")
    
    # Build test command with proper environment
    env_vars = @record_mode ? "RECORD_SNAPSHOTS=true" : ""
    
    cmd = %Q{
      #{env_vars} xcodebuild test \
        -project HomeInventoryModular.xcodeproj \
        -scheme HomeInventoryModular \
        -destination "id=#{simulator_id}" \
        -only-testing:HomeInventoryModularTests/SimpleSnapshotTest \
        -derivedDataPath build \
        2>&1
    }.strip.gsub(/\s+/, ' ')
    
    puts "Running command: #{cmd}"
    
    test_output = []
    test_passed = false
    
    IO.popen(cmd) do |io|
      io.each_line do |line|
        # Filter output
        if line.include?('Test Case') && line.include?('started')
          puts "🏃 #{line.strip}"
        elsif line.include?('Test Case') && line.include?('passed')
          puts "✅ #{line.strip}"
          test_passed = true
        elsif line.include?('Test Case') && line.include?('failed')
          puts "❌ #{line.strip}"
        elsif line.include?('error:') || line.include?('failed:')
          test_output << line
        elsif @record_mode && line.include?('Recording snapshot')
          puts "📸 Recording snapshot..."
        end
      end
    end
    
    # Check for snapshots
    check_for_snapshots
    
    if test_output.any?
      puts "\n❌ Test errors:"
      test_output.each { |line| puts line }
    end
    
    test_passed
  end
  
  def get_simulator_id
    # Try to find iPhone 16 Pro Max first, then fall back to any iPhone
    output = `xcrun simctl list devices`
    
    # Look for iPhone 16 Pro Max
    if output =~ /iPhone 16 Pro Max \(([A-F0-9-]+)\)/
      return $1
    end
    
    # Fall back to any booted iPhone
    if output =~ /iPhone[^(]+\(([A-F0-9-]+)\) \(Booted\)/
      return $1
    end
    
    # Fall back to any iPhone
    if output =~ /iPhone[^(]+\(([A-F0-9-]+)\)/
      return $1
    end
    
    nil
  end
  
  def check_for_snapshots
    puts "\n📁 Checking for snapshots..."
    
    snapshot_dirs = Dir.glob('**/__Snapshots__', File::FNM_DOTMATCH)
    
    if snapshot_dirs.empty?
      puts "No snapshot directories found."
      
      # Check in test directory specifically
      test_snapshots = Dir.glob('HomeInventoryModularTests/**/__Snapshots__', File::FNM_DOTMATCH)
      if test_snapshots.any?
        snapshot_dirs = test_snapshots
      end
    end
    
    if snapshot_dirs.any?
      snapshot_dirs.each do |dir|
        png_files = Dir.glob("#{dir}/*.png")
        if png_files.any?
          puts "📸 #{dir}:"
          png_files.each do |file|
            size = File.size(file) / 1024
            puts "   - #{File.basename(file)} (#{size}KB)"
          end
        end
      end
    else
      puts "No snapshots found. If in record mode, tests may not have run correctly."
    end
  end
end

# Run the test
record_mode = ARGV.include?('--record') || ENV['RECORD_SNAPSHOTS'] == 'true'
runner = DirectSnapshotTest.new(record_mode: record_mode)
runner.run