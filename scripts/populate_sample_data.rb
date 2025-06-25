#!/usr/bin/env ruby

require 'json'

class SampleDataPopulator
  SIMULATOR_ID = 'DD192264-DFAA-4582-B2FE-D6FC444C9DDF'
  APP_BUNDLE_ID = 'com.homeinventory.app'
  
  def initialize
    @project_dir = File.expand_path('..', __dir__)
    
    puts "📦 Sample Data Population for Screenshots"
    puts "=" * 50
    puts ""
  end
  
  def run
    ensure_app_launched
    populate_items
    populate_receipts
    test_search_functionality
    test_different_views
    
    puts ""
    puts "✅ Sample data population complete!"
    puts "🔄 Ready for comprehensive screenshot capture"
  end
  
  private
  
  def ensure_app_launched
    puts "🚀 Ensuring app is launched and ready..."
    
    # Kill and relaunch app to start fresh
    system("xcrun simctl io #{SIMULATOR_ID} spawn terminate #{APP_BUNDLE_ID}") rescue nil
    sleep(1)
    
    system("xcrun simctl io #{SIMULATOR_ID} spawn launch #{APP_BUNDLE_ID}")
    sleep(4)
    
    puts "   ✅ App launched and ready"
  end
  
  def populate_items
    puts "\n📱 Adding sample items through UI..."
    
    sample_items = [
      { name: "MacBook Pro 16\"", brand: "Apple", value: "2500", category: "Electronics" },
      { name: "Vintage Watch", brand: "Rolex", value: "15000", category: "Jewelry" },
      { name: "Leather Sofa", brand: "West Elm", value: "1200", category: "Furniture" },
      { name: "Gaming Console", brand: "Sony", value: "500", category: "Electronics" },
      { name: "Dining Table", brand: "IKEA", value: "300", category: "Furniture" }
    ]
    
    sample_items.each_with_index do |item, index|
      puts "   📝 Adding item #{index + 1}: #{item[:name]}"
      add_item_through_ui(item)
      sleep(2)
    end
    
    puts "   ✅ Sample items added"
  end
  
  def add_item_through_ui(item)
    # Tap add button (+ icon in top right)
    system("xcrun simctl io #{SIMULATOR_ID} spawn tap 614 119")
    sleep(2)
    
    # Fill in item name
    system("xcrun simctl io #{SIMULATOR_ID} spawn tap 329 200")
    sleep(1)
    system("xcrun simctl io #{SIMULATOR_ID} spawn type '#{item[:name]}'")
    sleep(1)
    
    # Fill in brand
    system("xcrun simctl io #{SIMULATOR_ID} spawn tap 329 300")
    sleep(1)
    system("xcrun simctl io #{SIMULATOR_ID} spawn type '#{item[:brand]}'")
    sleep(1)
    
    # Fill in value
    system("xcrun simctl io #{SIMULATOR_ID} spawn tap 329 400")
    sleep(1)
    system("xcrun simctl io #{SIMULATOR_ID} spawn type '#{item[:value]}'")
    sleep(1)
    
    # Save item (tap save/done button)
    system("xcrun simctl io #{SIMULATOR_ID} spawn tap 329 500")
    sleep(2)
    
    # Return to main list
    system("xcrun simctl io #{SIMULATOR_ID} spawn tap 30 100")
    sleep(1)
  end
  
  def populate_receipts
    puts "\n🧾 Testing receipts functionality..."
    
    # Switch to receipts view
    system("xcrun simctl io #{SIMULATOR_ID} spawn tap 482 277")
    sleep(3)
    
    # Try to add a receipt (camera/scan function)
    system("xcrun simctl io #{SIMULATOR_ID} spawn tap 461 1350")
    sleep(3)
    
    # Return to items
    system("xcrun simctl io #{SIMULATOR_ID} spawn tap 65 1350")
    sleep(2)
    
    puts "   ✅ Receipts view tested"
  end
  
  def test_search_functionality
    puts "\n🔍 Testing search with sample data..."
    
    # Activate search
    system("xcrun simctl io #{SIMULATOR_ID} spawn tap 538 119")
    sleep(2)
    
    # Search for "Apple"
    system("xcrun simctl io #{SIMULATOR_ID} spawn type 'Apple'")
    sleep(3)
    
    # Clear search
    system("xcrun simctl io #{SIMULATOR_ID} spawn tap 600 119")
    sleep(2)
    
    # Search for non-existent item
    system("xcrun simctl io #{SIMULATOR_ID} spawn tap 538 119")
    sleep(1)
    system("xcrun simctl io #{SIMULATOR_ID} spawn type 'NonExistentItem'")
    sleep(3)
    
    # Clear and dismiss search
    system("xcrun simctl io #{SIMULATOR_ID} spawn tap 600 119")
    sleep(1)
    system("xcrun simctl io #{SIMULATOR_ID} spawn tap 30 119")
    sleep(2)
    
    puts "   ✅ Search functionality tested"
  end
  
  def test_different_views
    puts "\n📊 Testing different views and states..."
    
    # Test analytics view
    system("xcrun simctl io #{SIMULATOR_ID} spawn tap 329 1350")
    sleep(3)
    
    # Test settings
    system("xcrun simctl io #{SIMULATOR_ID} spawn tap 593 1350")
    sleep(3)
    
    # Test scanner
    system("xcrun simctl io #{SIMULATOR_ID} spawn tap 461 1350")
    sleep(3)
    
    # Back to items with populated data
    system("xcrun simctl io #{SIMULATOR_ID} spawn tap 65 1350")
    sleep(2)
    
    # Test filters with data
    system("xcrun simctl io #{SIMULATOR_ID} spawn tap 113 482")
    sleep(2)
    
    # Test sort options
    system("xcrun simctl io #{SIMULATOR_ID} spawn tap 141 538")
    sleep(2)
    
    # Test item details
    system("xcrun simctl io #{SIMULATOR_ID} spawn tap 329 670")
    sleep(3)
    
    # Back to main
    system("xcrun simctl io #{SIMULATOR_ID} spawn tap 30 100")
    sleep(2)
    
    puts "   ✅ Different views and states tested"
  end
end

# Run the sample data population
if __FILE__ == $0
  SampleDataPopulator.new.run
end