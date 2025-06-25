#!/usr/bin/env ruby

require 'simctl'
require 'json'
require 'fileutils'
require 'open3'

class SmartScreenshots
  SIMULATOR_ID = 'DD192264-DFAA-4582-B2FE-D6FC444C9DDF'
  APP_BUNDLE_ID = 'com.homeinventory.app'
  
  def initialize
    @project_dir = File.expand_path('..', __dir__)
    @output_dir = File.join(@project_dir, 'Screenshots', 'SmartCapture')
    FileUtils.mkdir_p(@output_dir)
    
    puts "🤖 Smart iOS Screenshot Automation with Ruby"
    puts "=" * 50
    puts ""
  end
  
  def run
    ensure_gems_available
    setup_simulator
    capture_app_screenshots
    analyze_screenshots
    cleanup_duplicates
    generate_report
  end
  
  private
  
  def ensure_gems_available
    required_gems = ['simctl', 'chunky_png', 'mini_magick']
    
    required_gems.each do |gem_name|
      begin
        require gem_name
      rescue LoadError
        puts "📦 Installing #{gem_name} gem..."
        system("gem install #{gem_name} --user-install")
        require gem_name
      end
    end
  end
  
  def setup_simulator
    puts "📱 Setting up simulator and app..."
    
    # Boot simulator if needed
    output, status = Open3.capture2e("xcrun simctl boot #{SIMULATOR_ID}")
    unless status.success?
      puts "   ⚠️  Simulator already booted or error: #{output.strip}"
    end
    
    # Open Simulator app
    system("open -a Simulator")
    sleep 2
    
    # Build and install app
    puts "   🔨 Building app..."
    build_output, build_status = Open3.capture2e("make build", chdir: @project_dir)
    
    unless build_status.success?
      puts "   ❌ Build failed: #{build_output}"
      exit 1
    end
    
    # Find and install app
    app_path = Dir.glob(File.join(@project_dir, 'build', 'Build', 'Products', '**', '*.app')).first
    
    if app_path
      puts "   📦 Installing app..."
      install_output, install_status = Open3.capture2e("xcrun simctl install #{SIMULATOR_ID} '#{app_path}'")
      
      unless install_status.success?
        puts "   ❌ Install failed: #{install_output}"
        exit 1
      end
    else
      puts "   ❌ Could not find built app"
      exit 1
    end
    
    puts "   ✅ Setup complete"
  end
  
  def capture_app_screenshots
    puts ""
    puts "📸 Capturing app screenshots with intelligent navigation..."
    
    # Launch app
    launch_output, launch_status = Open3.capture2e("xcrun simctl launch #{SIMULATOR_ID} #{APP_BUNDLE_ID}")
    puts "   🚀 App launched: #{launch_output.strip}"
    sleep 3
    
    # Capture initial state
    capture_screenshot('00_app_launch', 'Initial app state')
    
    # Systematic exploration
    explore_tab_bar
    explore_navigation
    explore_settings
    explore_add_functionality
    
    puts ""
    puts "✅ Screenshot capture complete!"
  end
  
  def explore_tab_bar
    puts "   🔍 Exploring tab bar..."
    
    tab_positions = [
      { x: 78, y: 800, name: 'tab_1_items' },
      { x: 157, y: 800, name: 'tab_2_scanner' },
      { x: 236, y: 800, name: 'tab_3_receipts' },
      { x: 314, y: 800, name: 'tab_4_analytics' },
      { x: 393, y: 800, name: 'tab_5_settings' }
    ]
    
    tab_positions.each do |tab|
      tap_and_capture(tab[:x], tab[:y], tab[:name], "Tab: #{tab[:name]}")
      sleep 1
    end
  end
  
  def explore_navigation
    puts "   🧭 Exploring navigation elements..."
    
    # Try common navigation button positions
    nav_elements = [
      { x: 50, y: 100, name: 'nav_back_button', desc: 'Back button' },
      { x: 350, y: 100, name: 'nav_add_button', desc: 'Add/Plus button' },
      { x: 300, y: 100, name: 'nav_menu_button', desc: 'Menu button' },
      { x: 393, y: 100, name: 'nav_profile_button', desc: 'Profile button' }
    ]
    
    nav_elements.each do |element|
      tap_and_capture(element[:x], element[:y], element[:name], element[:desc])
      sleep 1
      
      # Return to main screen
      tap_and_capture(50, 100, "#{element[:name]}_return", "Return from #{element[:desc]}")
      sleep 1
    end
  end
  
  def explore_settings
    puts "   ⚙️ Exploring settings and menu areas..."
    
    # Try accessing settings through different methods
    settings_attempts = [
      { x: 393, y: 800, name: 'settings_tab', desc: 'Settings tab' },
      { x: 350, y: 150, name: 'settings_nav', desc: 'Settings navigation' },
      { x: 30, y: 200, name: 'settings_hamburger', desc: 'Hamburger menu' }
    ]
    
    settings_attempts.each do |attempt|
      tap_and_capture(attempt[:x], attempt[:y], attempt[:name], attempt[:desc])
      sleep 2
      
      # Try to navigate within settings
      if attempt[:name] == 'settings_tab'
        explore_settings_options
      end
    end
  end
  
  def explore_settings_options
    # Common settings menu item positions
    settings_items = [
      { x: 200, y: 250, name: 'settings_categories', desc: 'Categories' },
      { x: 200, y: 300, name: 'settings_locations', desc: 'Locations' },
      { x: 200, y: 350, name: 'settings_export', desc: 'Export' },
      { x: 200, y: 400, name: 'settings_premium', desc: 'Premium' }
    ]
    
    settings_items.each do |item|
      tap_and_capture(item[:x], item[:y], item[:name], item[:desc])
      sleep 1
      
      # Go back
      tap_and_capture(50, 100, "#{item[:name]}_back", "Back from #{item[:desc]}")
      sleep 1
    end
  end
  
  def explore_add_functionality
    puts "   ➕ Exploring add item functionality..."
    
    # Try to access add item screen
    add_attempts = [
      { x: 350, y: 100, name: 'add_nav_button', desc: 'Navigation add button' },
      { x: 350, y: 750, name: 'add_floating_button', desc: 'Floating add button' },
      { x: 200, y: 400, name: 'add_main_area', desc: 'Main area add' }
    ]
    
    add_attempts.each do |attempt|
      tap_and_capture(attempt[:x], attempt[:y], attempt[:name], attempt[:desc])
      sleep 2
      
      # If we're in add item screen, explore it
      explore_add_item_form if attempt[:name] == 'add_nav_button'
      
      # Return to main
      tap_and_capture(50, 100, "#{attempt[:name]}_cancel", "Cancel add item")
      sleep 1
    end
  end
  
  def explore_add_item_form
    form_fields = [
      { x: 200, y: 200, name: 'add_name_field', desc: 'Item name field' },
      { x: 200, y: 250, name: 'add_price_field', desc: 'Price field' },
      { x: 200, y: 300, name: 'add_category_field', desc: 'Category field' },
      { x: 200, y: 400, name: 'add_photo_button', desc: 'Add photo button' }
    ]
    
    form_fields.each do |field|
      tap_and_capture(field[:x], field[:y], field[:name], field[:desc])
      sleep 1
    end
  end
  
  def tap_and_capture(x, y, filename, description)
    # Perform tap
    tap_output, tap_status = Open3.capture2e("xcrun simctl io #{SIMULATOR_ID} spawn tap #{x} #{y}")
    
    # Wait for UI to respond
    sleep 1.5
    
    # Capture screenshot
    capture_screenshot(filename, description)
  end
  
  def capture_screenshot(filename, description)
    output_path = File.join(@output_dir, "#{filename}.png")
    
    screenshot_output, screenshot_status = Open3.capture2e("xcrun simctl io #{SIMULATOR_ID} screenshot '#{output_path}'")
    
    if screenshot_status.success? && File.exist?(output_path)
      file_size = File.size(output_path)
      puts "     📸 #{filename}.png (#{format_file_size(file_size)}) - #{description}"
    else
      puts "     ❌ Failed to capture #{filename}: #{screenshot_output}"
    end
  end
  
  def analyze_screenshots
    puts ""
    puts "🔍 Analyzing screenshots for uniqueness..."
    
    screenshots = Dir.glob(File.join(@output_dir, '*.png')).sort
    unique_screenshots = []
    duplicates = []
    
    screenshots.each_with_index do |screenshot, index|
      is_unique = true
      
      # Compare with previous screenshots
      unique_screenshots.each do |unique|
        if images_similar?(screenshot, unique)
          is_unique = false
          duplicates << screenshot
          break
        end
      end
      
      unique_screenshots << screenshot if is_unique
    end
    
    puts "   📊 Analysis complete:"
    puts "     📸 Total screenshots: #{screenshots.length}"
    puts "     ✨ Unique screenshots: #{unique_screenshots.length}"
    puts "     🔄 Duplicates found: #{duplicates.length}"
    
    @unique_screenshots = unique_screenshots
    @duplicates = duplicates
  end
  
  def images_similar?(image1, image2)
    # Simple file size comparison for now
    # In a more sophisticated version, we could use image hashing
    size1 = File.size(image1)
    size2 = File.size(image2)
    
    # Consider images similar if file sizes are within 5%
    size_diff = (size1 - size2).abs.to_f / [size1, size2].max
    size_diff < 0.05
  end
  
  def cleanup_duplicates
    return if @duplicates.empty?
    
    puts ""
    puts "🧹 Cleaning up duplicate screenshots..."
    
    @duplicates.each do |duplicate|
      File.delete(duplicate)
      puts "   🗑️  Removed: #{File.basename(duplicate)}"
    end
    
    puts "   ✅ Cleanup complete"
  end
  
  def generate_report
    puts ""
    puts "📋 Final Report"
    puts "=" * 30
    
    remaining_screenshots = Dir.glob(File.join(@output_dir, '*.png')).sort
    total_size = remaining_screenshots.sum { |f| File.size(f) }
    
    puts "📁 Location: #{@output_dir}"
    puts "📸 Unique screenshots: #{remaining_screenshots.length}"
    puts "💾 Total size: #{format_file_size(total_size)}"
    puts ""
    
    puts "📱 Screenshots captured:"
    remaining_screenshots.each do |screenshot|
      filename = File.basename(screenshot)
      size = format_file_size(File.size(screenshot))
      puts "   📸 #{filename} (#{size})"
    end
    
    puts ""
    puts "💡 Tips for better screenshots:"
    puts "   • Add sample data to your app first"
    puts "   • Navigate manually to specific screens"
    puts "   • Use accessibility identifiers for better automation"
    puts "   • Consider implementing a demo mode with test data"
    
    puts ""
    puts "🔄 To run again: ruby scripts/smart_screenshots.rb"
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

# Run the smart screenshot automation
if __FILE__ == $0
  SmartScreenshots.new.run
end