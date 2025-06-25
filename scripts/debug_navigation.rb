#!/usr/bin/env ruby

require 'simctl'

class NavigationDebugger
  SIMULATOR_ID = 'DD192264-DFAA-4582-B2FE-D6FC444C9DDF'
  APP_BUNDLE_ID = 'com.homeinventory.app'
  
  def initialize
    @project_dir = File.expand_path('..', __dir__)
    @debug_dir = File.join(@project_dir, 'Screenshots', 'Debug')
    FileUtils.mkdir_p(@debug_dir)
    
    puts "🔍 Navigation Debug Tool"
    puts "=" * 40
  end
  
  def run
    ensure_app_launched
    debug_tab_coordinates
    test_alternative_interactions
    test_actual_content_differences
  end
  
  private
  
  def ensure_app_launched
    puts "\n🚀 Launching app for debugging..."
    system("xcrun simctl io #{SIMULATOR_ID} spawn terminate #{APP_BUNDLE_ID}") rescue nil
    sleep(1)
    system("xcrun simctl io #{SIMULATOR_ID} spawn launch #{APP_BUNDLE_ID}")
    sleep(4)
    puts "   ✅ App ready for debugging"
  end
  
  def debug_tab_coordinates
    puts "\n📍 Testing Tab Coordinates and Responses"
    puts "-" * 40
    
    # Take baseline screenshot
    baseline_path = File.join(@debug_dir, 'baseline.png')
    system("xcrun simctl io #{SIMULATOR_ID} screenshot '#{baseline_path}'")
    puts "   📸 Baseline screenshot captured"
    
    tab_tests = [
      { name: 'insurance', coords: [197, 1350], expected: 'Insurance Dashboard' },
      { name: 'analytics', coords: [329, 1350], expected: 'Spending Analytics' },
      { name: 'scanner', coords: [461, 1350], expected: 'Scanner Interface' },
      { name: 'settings', coords: [593, 1350], expected: 'Settings Menu' },
      { name: 'items_return', coords: [65, 1350], expected: 'Items List' }
    ]
    
    tab_tests.each_with_index do |test, index|
      puts "   🎯 Testing #{test[:name]} tab (#{test[:coords]})"
      
      # Tap the tab
      x, y = test[:coords]
      system("xcrun simctl io #{SIMULATOR_ID} spawn tap #{x} #{y}")
      sleep(3)
      
      # Take screenshot
      screenshot_path = File.join(@debug_dir, "tab_#{index + 1}_#{test[:name]}.png")
      system("xcrun simctl io #{SIMULATOR_ID} screenshot '#{screenshot_path}'")
      
      # Compare file sizes to detect changes
      baseline_size = File.size(baseline_path)
      current_size = File.size(screenshot_path)
      
      if (baseline_size - current_size).abs < 1000
        puts "      ⚠️  Possible duplicate - size difference: #{current_size - baseline_size} bytes"
      else
        puts "      ✅ Content change detected - size difference: #{current_size - baseline_size} bytes"
      end
      
      sleep(1)
    end
  end
  
  def test_alternative_interactions
    puts "\n🔄 Testing Alternative Interactions"
    puts "-" * 40
    
    # Test receipts segmented control within Items tab
    puts "   📝 Testing Receipts segmented control"
    system("xcrun simctl io #{SIMULATOR_ID} spawn tap 65 1350")  # Ensure on Items tab
    sleep(2)
    system("xcrun simctl io #{SIMULATOR_ID} spawn tap 482 277")  # Tap Receipts segment
    sleep(3)
    screenshot_path = File.join(@debug_dir, 'receipts_segment.png')
    system("xcrun simctl io #{SIMULATOR_ID} screenshot '#{screenshot_path}'")
    puts "      📸 Receipts view captured"
    
    # Test search activation
    puts "   🔍 Testing search activation"
    system("xcrun simctl io #{SIMULATOR_ID} spawn tap 175 277")  # Back to Items segment
    sleep(2)
    system("xcrun simctl io #{SIMULATOR_ID} spawn tap 538 119")  # Search button
    sleep(3)
    screenshot_path = File.join(@debug_dir, 'search_active.png')
    system("xcrun simctl io #{SIMULATOR_ID} screenshot '#{screenshot_path}'")
    puts "      📸 Search interface captured"
    
    # Dismiss search
    system("xcrun simctl io #{SIMULATOR_ID} spawn tap 30 119")
    sleep(2)
    
    # Test filter activation
    puts "   🎛️  Testing filter menu"
    system("xcrun simctl io #{SIMULATOR_ID} spawn tap 113 482")  # Filters button
    sleep(3)
    screenshot_path = File.join(@debug_dir, 'filters_active.png')
    system("xcrun simctl io #{SIMULATOR_ID} screenshot '#{screenshot_path}'")
    puts "      📸 Filter menu captured"
  end
  
  def test_actual_content_differences
    puts "\n🎨 Capturing Actual Content Differences"
    puts "-" * 40
    
    content_tests = [
      { 
        name: 'items_detailed',
        description: 'Items List with All Data',
        sequence: [
          { tap: [65, 1350], delay: 2 },    # Items tab
          { tap: [175, 277], delay: 2 }     # Items segment
        ]
      },
      {
        name: 'receipts_view',
        description: 'Receipts View',
        sequence: [
          { tap: [65, 1350], delay: 2 },    # Items tab
          { tap: [482, 277], delay: 3 }     # Receipts segment
        ]
      },
      {
        name: 'insurance_dashboard',
        description: 'Insurance Dashboard',
        sequence: [
          { tap: [197, 1350], delay: 4 }    # Insurance tab - longer delay
        ]
      },
      {
        name: 'analytics_dashboard',
        description: 'Analytics Dashboard',
        sequence: [
          { tap: [329, 1350], delay: 4 }    # Analytics tab - longer delay
        ]
      },
      {
        name: 'scanner_interface',
        description: 'Scanner Interface',
        sequence: [
          { tap: [461, 1350], delay: 4 }    # Scanner tab - longer delay
        ]
      },
      {
        name: 'settings_menu',
        description: 'Settings Menu',
        sequence: [
          { tap: [593, 1350], delay: 4 }    # Settings tab - longer delay
        ]
      }
    ]
    
    content_tests.each_with_index do |test, index|
      puts "   🎯 Capturing: #{test[:description]}"
      
      # Execute sequence
      test[:sequence].each do |action|
        if action[:tap]
          x, y = action[:tap]
          system("xcrun simctl io #{SIMULATOR_ID} spawn tap #{x} #{y}")
        end
        sleep(action[:delay] || 2)
      end
      
      # Capture screenshot
      screenshot_path = File.join(@debug_dir, "content_#{index + 1}_#{test[:name]}.png")
      system("xcrun simctl io #{SIMULATOR_ID} screenshot '#{screenshot_path}'")
      
      file_size = File.size(screenshot_path)
      puts "      📸 #{test[:name]}.png (#{format_file_size(file_size)})"
      
      sleep(1)
    end
  end
  
  def format_file_size(bytes)
    if bytes < 1024
      "#{bytes}B"
    elsif bytes < 1024 * 1024
      "#{(bytes / 1024.0).round(1)}KB"
    else
      "#{(bytes / (1024.0 * 1024.0)).round(1)}MB"
    end
  end
end

# Run the debug tool
if __FILE__ == $0
  NavigationDebugger.new.run
  
  puts "\n📊 Debug Complete!"
  puts "Check Screenshots/Debug/ for detailed analysis"
  puts "Compare screenshots to identify actual content differences"
end