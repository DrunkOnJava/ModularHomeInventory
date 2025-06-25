#!/usr/bin/env ruby

puts "🔧 Final Gmail Module Fix..."

# Fix duplicate public keywords
Dir.glob("Modules/Gmail/Sources/**/*.swift").each do |file|
  content = File.read(file)
  
  # Fix duplicate public public
  content.gsub!(/public\s+public/, 'public')
  
  # Fix missing initializers
  if file.include?("EmailMessage.swift")
    content.gsub!(/public struct EmailMessage: Identifiable \{/, <<~SWIFT.strip)
public struct EmailMessage: Identifiable {
    public init(id: String, subject: String, from: String, date: Date, snippet: String, body: String, receiptInfo: ReceiptInfo?) {
        self.id = id
        self.subject = subject
        self.from = from
        self.date = date
        self.snippet = snippet
        self.body = body
        self.receiptInfo = receiptInfo
    }
SWIFT
    
    content.gsub!(/public struct ReceiptInfo \{/, <<~SWIFT.strip)
public struct ReceiptInfo {
    public init(retailer: String, orderNumber: String?, totalAmount: Double?, items: [ReceiptItem], orderDate: Date?, confidence: Double) {
        self.retailer = retailer
        self.orderNumber = orderNumber
        self.totalAmount = totalAmount
        self.items = items
        self.orderDate = orderDate
        self.confidence = confidence
    }
SWIFT
    
    content.gsub!(/public struct ReceiptItem \{/, <<~SWIFT.strip)
public struct ReceiptItem {
    public init(name: String, price: Double?, quantity: Int) {
        self.name = name
        self.price = price
        self.quantity = quantity
    }
SWIFT
  end
  
  # Fix missing methods in GmailModule
  if file.include?("GmailModule.swift")
    unless content.include?("private func fetchReceiptEmails")
      content.gsub!(/let emails = try await fetchReceiptEmails\(\)/, 
                    'let emails = try await bridge.fetchReceiptEmails()')
    end
  end
  
  # Fix internal types in GmailAuthService
  if file.include?("GmailAuthService.swift")
    content.gsub!(/(\s+)init\(\)/, '\1public init()')
  end
  
  # Fix internal types in SimpleGmailAPI
  if file.include?("SimpleGmailAPI.swift")
    content.gsub!(/(\s+)init\(authService:/, '\1public init(authService:')
  end
  
  File.write(file, content)
  puts "✅ Fixed #{File.basename(file)}"
end

# Create a minimal Gmail module resources directory
resources_dir = "Modules/Gmail/Sources/Resources"
Dir.mkdir(resources_dir) unless Dir.exist?(resources_dir)

# Copy GoogleServices.plist if it exists
old_plist = "Modules/Gmail/Resources/GoogleServices.plist"
new_plist = "#{resources_dir}/GoogleServices.plist"
if File.exist?(old_plist) && !File.exist?(new_plist)
  File.write(new_plist, File.read(old_plist))
  puts "✅ Copied GoogleServices.plist to Sources/Resources"
end

puts "\n✅ Final fixes complete!"
puts "Run 'make build' to rebuild the project"