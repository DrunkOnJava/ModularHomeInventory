#!/usr/bin/env ruby

require 'simctl'
require 'json'
require 'fileutils'

class HomeInventoryScreenshots
  SIMULATOR_ID = 'DD192264-DFAA-4582-B2FE-D6FC444C9DDF'
  APP_BUNDLE_ID = 'com.homeinventory.app'
  
  def initialize
    @project_dir = File.expand_path('..', __dir__)
    @output_dir = File.join(@project_dir, 'Screenshots', 'AutomatedApp')
    FileUtils.mkdir_p(@output_dir)
    
    puts "📸 Ruby-powered iOS App Screenshot Automation"
    puts "=" * 50
    puts ""
    
    @simulator = SimCtl.device(udid: SIMULATOR_ID)
  end
  
  def run
    ensure_simulator_ready
    launch_app
    capture_screenshots
    generate_summary
  end
  
  private
  
  def ensure_simulator_ready
    puts "📱 Preparing iOS Simulator..."
    
    unless @simulator.state == :booted
      puts "   🚀 Booting simulator..."
      @simulator.boot
      sleep 3
    end
    
    puts "   ✅ Simulator ready"
  end
  
  def launch_app
    puts "🚀 Launching Home Inventory app..."
    
    begin
      # Kill app if already running
      @simulator.terminate_app(APP_BUNDLE_ID) rescue nil
      sleep 1
      
      # Launch the app
      @simulator.launch_app(APP_BUNDLE_ID)
      puts "   ✅ App launched successfully"
      sleep 3
      
    rescue => e
      puts "   ❌ Could not launch app: #{e.message}"
      puts "   📦 Trying to install app first..."
      install_and_launch_app
    end
  end
  
  def install_and_launch_app
    app_path = find_app_bundle
    
    if app_path
      puts "   📦 Installing app from: #{app_path}"
      @simulator.install_app(app_path)
      sleep 2
      
      @simulator.launch_app(APP_BUNDLE_ID)
      puts "   ✅ App installed and launched"
      sleep 3
    else
      puts "   ❌ Could not find app bundle. Run 'make build' first."
      exit 1
    end
  end
  
  def find_app_bundle
    Dir.glob(File.join(@project_dir, 'build', 'Build', 'Products', '**', '*.app')).first
  end
  
  def capture_screenshots
    puts "📸 Capturing comprehensive app screenshots..."
    puts ""
    
    # Main navigation screenshots
    capture_main_navigation
    
    # Deep interaction screenshots
    capture_deep_interactions
    
    # Modal and overlay screenshots
    capture_modals_and_overlays
    
    # Error states and edge cases
    capture_edge_cases
    
    puts ""
    puts "✅ Comprehensive screenshot capture complete!"
  end
  
  def capture_main_navigation
    puts "🧭 Main Navigation Screenshots"
    puts "-" * 30
    
    main_nav = [
      { name: '01_app_launch', description: 'App Launch - Items Tab', delay: 3 },
      { name: '02_analytics_tab', description: 'Analytics Tab', tap: [329, 1350], delay: 4 },
      { name: '03_scanner_tab', description: 'Scanner Tab', tap: [461, 1350], delay: 4 },
      { name: '04_settings_tab', description: 'Settings Tab', tap: [593, 1350], delay: 4 },
      { name: '05_back_to_items', description: 'Items Tab Return', tap: [65, 1350], delay: 3 },
    ]
    
    main_nav.each_with_index do |screenshot, index|
      capture_screenshot_step(screenshot, index + 1, main_nav.length, "NAV")
    end
  end
  
  def capture_deep_interactions
    puts "\n🔍 Deep Interaction Screenshots"
    puts "-" * 30
    
    interactions = [
      { name: '06_receipts_view', description: 'Receipts Tab', tap: [482, 277], delay: 3 },
      { name: '07_search_activate', description: 'Search Interface', tap: [538, 119], delay: 3 },
      { name: '08_search_dismiss', description: 'Dismiss Search', tap: [30, 119], delay: 2 },
      { name: '09_add_button', description: 'Add Item Button', tap: [614, 119], delay: 3 },
      { name: '10_filter_menu', description: 'Filter Menu', tap: [113, 482], delay: 3 },
      { name: '11_sort_options', description: 'Sort Options', tap: [141, 538], delay: 3 },
      { name: '12_first_item', description: 'First Item Detail', tap: [329, 670], delay: 4 },
      { name: '13_item_actions', description: 'Item Action Menu', tap: [600, 100], delay: 3 },
      { name: '14_back_from_item', description: 'Back from Item', tap: [30, 100], delay: 2 },
    ]
    
    interactions.each_with_index do |screenshot, index|
      capture_screenshot_step(screenshot, index + 1, interactions.length, "INT")
    end
  end
  
  def capture_modals_and_overlays
    puts "\n📱 Modal and Overlay Screenshots"
    puts "-" * 30
    
    # Reset to main screen first
    system("xcrun simctl io #{SIMULATOR_ID} spawn tap 65 1350")
    sleep(2)
    
    modals = [
      { name: '15_context_menu', description: 'Context Menu', tap: [329, 670], hold: true, delay: 3 },
      { name: '16_long_press_item', description: 'Long Press Item', tap: [329, 770], hold: true, delay: 3 },
      { name: '17_settings_deep', description: 'Settings Menu', tap: [593, 1350], delay: 2, 
        follow_up: { tap: [329, 400], delay: 3 } },
      { name: '18_scanner_camera', description: 'Scanner Camera View', tap: [461, 1350], delay: 4 },
      { name: '19_analytics_charts', description: 'Analytics Charts', tap: [329, 1350], delay: 4 },
    ]
    
    modals.each_with_index do |screenshot, index|
      capture_modal_step(screenshot, index + 1, modals.length)
    end
  end
  
  def capture_edge_cases
    puts "\n⚠️ Edge Cases and States"
    puts "-" * 30
    
    # Reset to main screen
    system("xcrun simctl io #{SIMULATOR_ID} spawn tap 65 1350")
    sleep(2)
    
    edge_cases = [
      { name: '20_empty_search', description: 'Empty Search Results', 
        sequence: [
          { tap: [538, 119], delay: 2 },
          { type: "xyz123nonexistent", delay: 2 }
        ]
      },
      { name: '21_scroll_bottom', description: 'Bottom of List', 
        sequence: [
          { swipe: { start: [329, 800], end: [329, 300] }, delay: 1 },
          { swipe: { start: [329, 800], end: [329, 300] }, delay: 1 },
          { swipe: { start: [329, 800], end: [329, 300] }, delay: 2 }
        ]
      },
      { name: '22_scroll_top', description: 'Top of List', 
        sequence: [
          { swipe: { start: [329, 300], end: [329, 800] }, delay: 1 },
          { swipe: { start: [329, 300], end: [329, 800] }, delay: 2 }
        ]
      },
      { name: '23_pull_refresh', description: 'Pull to Refresh', 
        sequence: [
          { swipe: { start: [329, 300], end: [329, 600] }, delay: 3 }
        ]
      },
      { name: '24_landscape_mode', description: 'Landscape Orientation', 
        sequence: [
          { rotate: "left", delay: 4 }
        ]
      },
      { name: '25_portrait_restore', description: 'Back to Portrait', 
        sequence: [
          { rotate: "portrait", delay: 3 }
        ]
      }
    ]
    
    edge_cases.each_with_index do |screenshot, index|
      capture_sequence_step(screenshot, index + 1, edge_cases.length)
    end
  end
  
  def capture_screenshot_step(screenshot, current, total, category = "")
    category_prefix = category.empty? ? "" : "[#{category}] "
    puts "📱 #{category_prefix}[#{current}/#{total}] #{screenshot[:description]}"
    
    # Perform tap if specified
    if screenshot[:tap]
      x, y = screenshot[:tap]
      puts "   👆 Tapping at (#{x}, #{y})"
      system("xcrun simctl io #{SIMULATOR_ID} spawn tap #{x} #{y}")
      sleep 1
    end
    
    # Wait for UI to settle
    sleep(screenshot[:delay] || 1)
    
    # Capture screenshot
    output_path = File.join(@output_dir, "#{screenshot[:name]}.png")
    
    begin
      system("xcrun simctl io #{SIMULATOR_ID} screenshot '#{output_path}'")
      file_size = File.size(output_path)
      formatted_size = format_file_size(file_size)
      puts "   ✅ Captured: #{screenshot[:name]}.png (#{formatted_size})"
    rescue => e
      puts "   ❌ Failed: #{e.message}"
    end
    
    sleep 0.5
  end
  
  def capture_modal_step(screenshot, current, total)
    puts "📱 [MODAL] [#{current}/#{total}] #{screenshot[:description]}"
    
    # Perform main action
    if screenshot[:tap]
      x, y = screenshot[:tap]
      if screenshot[:hold]
        puts "   👆 Long press at (#{x}, #{y})"
        # Simulate long press with multiple taps
        3.times do
          system("xcrun simctl io #{SIMULATOR_ID} spawn tap #{x} #{y}")
          sleep 0.3
        end
      else
        puts "   👆 Tapping at (#{x}, #{y})"
        system("xcrun simctl io #{SIMULATOR_ID} spawn tap #{x} #{y}")
      end
      sleep 1
    end
    
    # Perform follow-up action if specified
    if screenshot[:follow_up]
      follow_up = screenshot[:follow_up]
      x, y = follow_up[:tap]
      puts "   👆 Follow-up tap at (#{x}, #{y})"
      system("xcrun simctl io #{SIMULATOR_ID} spawn tap #{x} #{y}")
      sleep(follow_up[:delay] || 1)
    end
    
    # Wait for UI to settle
    sleep(screenshot[:delay] || 2)
    
    # Capture screenshot
    output_path = File.join(@output_dir, "#{screenshot[:name]}.png")
    
    begin
      system("xcrun simctl io #{SIMULATOR_ID} screenshot '#{output_path}'")
      file_size = File.size(output_path)
      formatted_size = format_file_size(file_size)
      puts "   ✅ Captured: #{screenshot[:name]}.png (#{formatted_size})"
    rescue => e
      puts "   ❌ Failed: #{e.message}"
    end
    
    sleep 0.5
  end
  
  def capture_sequence_step(screenshot, current, total)
    puts "📱 [EDGE] [#{current}/#{total}] #{screenshot[:description]}"
    
    # Execute sequence of actions
    if screenshot[:sequence]
      screenshot[:sequence].each_with_index do |action, idx|
        puts "   🔄 Step #{idx + 1}: #{action.keys.first}"
        
        case action.keys.first
        when :tap
          x, y = action[:tap]
          system("xcrun simctl io #{SIMULATOR_ID} spawn tap #{x} #{y}")
        when :swipe
          start_x, start_y = action[:swipe][:start]
          end_x, end_y = action[:swipe][:end]
          system("xcrun simctl io #{SIMULATOR_ID} spawn swipe #{start_x} #{start_y} #{end_x} #{end_y}")
        when :type
          text = action[:type]
          system("xcrun simctl io #{SIMULATOR_ID} spawn type '#{text}'")
        when :rotate
          orientation = action[:rotate]
          if orientation == "left"
            system("xcrun simctl io #{SIMULATOR_ID} spawn orientation rotateLeft")
          elsif orientation == "portrait"
            system("xcrun simctl io #{SIMULATOR_ID} spawn orientation portrait")
          end
        end
        
        sleep(action[:delay] || 1)
      end
    end
    
    # Capture screenshot
    output_path = File.join(@output_dir, "#{screenshot[:name]}.png")
    
    begin
      system("xcrun simctl io #{SIMULATOR_ID} screenshot '#{output_path}'")
      file_size = File.size(output_path)
      formatted_size = format_file_size(file_size)
      puts "   ✅ Captured: #{screenshot[:name]}.png (#{formatted_size})"
    rescue => e
      puts "   ❌ Failed: #{e.message}"
    end
    
    sleep 0.5
  end
  
  def generate_summary
    puts ""
    puts "📊 Comprehensive Screenshot Analysis"
    puts "=" * 50
    
    screenshots = Dir.glob(File.join(@output_dir, '*.png'))
    
    if screenshots.any?
      total_size = screenshots.sum { |f| File.size(f) }
      
      puts "📁 Location: #{@output_dir}"
      puts "📸 Total Count: #{screenshots.length} screenshots"
      puts "💾 Total Size: #{format_file_size(total_size)}"
      puts ""
      
      # Categorize screenshots
      categorize_screenshots(screenshots)
      
      # Analyze for duplicates
      analyze_duplicates(screenshots)
      
      # Generate recommendations
      generate_recommendations(screenshots)
      
    else
      puts "❌ No screenshots were captured"
    end
    
    puts ""
    puts "🔄 Commands:"
    puts "   📱 Run again: ruby scripts/automated_screenshots.rb"
    puts "   🧹 Clean duplicates: ruby scripts/clean_screenshots.rb"
    puts "   📊 Analyze screenshots: ruby scripts/analyze_screenshots.rb"
  end
  
  def categorize_screenshots(screenshots)
    puts "📂 Screenshot Categories:"
    puts "-" * 25
    
    categories = {
      "Navigation" => screenshots.select { |f| f.match(/0[1-5]_/) },
      "Interactions" => screenshots.select { |f| f.match(/0[6-9]_|1[0-4]_/) },
      "Modals" => screenshots.select { |f| f.match(/1[5-9]_/) },
      "Edge Cases" => screenshots.select { |f| f.match(/2[0-9]_/) }
    }
    
    categories.each do |category, files|
      size = files.sum { |f| File.size(f) }
      puts "   #{category}: #{files.length} files (#{format_file_size(size)})"
    end
    puts ""
  end
  
  def analyze_duplicates(screenshots)
    puts "🔍 Duplicate Analysis:"
    puts "-" * 20
    
    size_groups = screenshots.group_by { |f| File.size(f) }
    duplicate_groups = size_groups.select { |size, files| files.length > 1 }
    
    if duplicate_groups.any?
      puts "   ⚠️  Found #{duplicate_groups.length} potential duplicate groups:"
      duplicate_groups.each do |size, files|
        puts "   📎 #{files.length} files at #{format_file_size(size)}:"
        files.each { |f| puts "      - #{File.basename(f)}" }
      end
    else
      puts "   ✅ No exact size duplicates found"
    end
    puts ""
  end
  
  def generate_recommendations(screenshots)
    puts "💡 Recommendations:"
    puts "-" * 17
    
    avg_size = screenshots.sum { |f| File.size(f) } / screenshots.length.to_f
    small_files = screenshots.select { |f| File.size(f) < avg_size * 0.8 }
    large_files = screenshots.select { |f| File.size(f) > avg_size * 1.2 }
    
    if small_files.any?
      puts "   📉 #{small_files.length} smaller files (may be loading states)"
    end
    
    if large_files.any?
      puts "   📈 #{large_files.length} larger files (may have rich content)"
    end
    
    puts "   🎯 Focus on files with unique content and good variety"
    puts "   🧪 Test different app states with sample data"
    puts "   📱 Consider adding accessibility IDs for better automation"
    puts "   🔄 Run in different simulator orientations and sizes"
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

# Run the screenshot automation
if __FILE__ == $0
  HomeInventoryScreenshots.new.run
end