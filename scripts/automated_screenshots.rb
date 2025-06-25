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
    puts "📸 Capturing app screenshots..."
    puts ""
    
    screenshots = [
      { name: '01_items_tab', description: 'Items Tab - Main Screen', delay: 2 },
      { name: '02_analytics_tab', description: 'Analytics Tab', tap: [329, 1350], delay: 3 },
      { name: '03_scanner_tab', description: 'Scanner Tab', tap: [461, 1350], delay: 3 },
      { name: '04_settings_tab', description: 'Settings Tab', tap: [593, 1350], delay: 3 },
      { name: '05_back_to_items', description: 'Back to Items Tab', tap: [65, 1350], delay: 3 },
      { name: '06_search_feature', description: 'Search Button', tap: [381, 64], delay: 2 },
      { name: '07_add_item', description: 'Add Item Button', tap: [415, 64], delay: 2 },
      { name: '08_filters', description: 'Filter Options', tap: [62, 159], delay: 2 },
      { name: '09_item_detail', description: 'First Item Detail', tap: [207, 251], delay: 3 },
      { name: '10_navigation_back', description: 'Back Navigation', tap: [30, 50], delay: 2 },
    ]
    
    screenshots.each_with_index do |screenshot, index|
      capture_screenshot_step(screenshot, index + 1, screenshots.length)
    end
    
    puts ""
    puts "✅ Screenshot capture complete!"
  end
  
  def capture_screenshot_step(screenshot, current, total)
    puts "📱 [#{current}/#{total}] #{screenshot[:description]}"
    
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
  
  def generate_summary
    puts ""
    puts "📊 Screenshot Summary"
    puts "-" * 30
    
    screenshots = Dir.glob(File.join(@output_dir, '*.png'))
    
    if screenshots.any?
      total_size = screenshots.sum { |f| File.size(f) }
      
      puts "📁 Location: #{@output_dir}"
      puts "📸 Count: #{screenshots.length} screenshots"
      puts "💾 Total size: #{format_file_size(total_size)}"
      puts ""
      
      puts "📋 Generated files:"
      screenshots.sort.each do |file|
        filename = File.basename(file)
        size = format_file_size(File.size(file))
        puts "   📱 #{filename} (#{size})"
      end
      
      puts ""
      puts "💡 Next steps:"
      puts "   1. Review screenshots to identify useful ones"
      puts "   2. Delete duplicates or unhelpful images"
      puts "   3. Rename screenshots to match actual content"
      puts "   4. Add sample data to app and re-run for better variety"
      
    else
      puts "❌ No screenshots were captured"
    end
    
    puts ""
    puts "🔄 To run again: ruby scripts/automated_screenshots.rb"
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