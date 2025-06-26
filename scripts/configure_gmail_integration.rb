#!/usr/bin/env ruby

require 'xcodeproj'
require 'json'

# Configuration
CLIENT_ID = "316432172622-6huvbn752v0ep68jkfdftrh8fgpesikg.apps.googleusercontent.com"
URL_SCHEME = "com.googleusercontent.apps.316432172622-6huvbn752v0ep68jkfdftrh8fgpesikg"
REDIRECT_URI = "#{URL_SCHEME}:/oauth"

puts "🔧 Configuring Gmail Integration for Home Inventory..."
puts "   Client ID: #{CLIENT_ID}"
puts "   URL Scheme: #{URL_SCHEME}"
puts "   Redirect URI: #{REDIRECT_URI}"
puts ""

# Open the project
project_path = 'HomeInventoryModular.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main app target
app_target = project.targets.find { |t| t.name == "HomeInventoryModular" }
unless app_target
  puts "❌ Could not find HomeInventoryModular target"
  exit 1
end

puts "✅ Found target: #{app_target.name}"

# Configure URL Types in Info.plist
app_target.build_configurations.each do |config|
  # Set up URL Types for Google Sign-In
  info_plist_key = 'INFOPLIST_KEY_CFBundleURLTypes'
  
  # Create the URL types array structure
  url_types = "$(inherited) <array><dict><key>CFBundleURLSchemes</key><array><string>#{URL_SCHEME}</string></array></dict></array>"
  
  # Add URL scheme to build settings
  config.build_settings['INFOPLIST_KEY_CFBundleURLTypes'] = url_types
  
  # Also add the reverse client ID as a URL scheme
  config.build_settings['GOOGLE_REVERSED_CLIENT_ID'] = URL_SCHEME
  config.build_settings['GOOGLE_CLIENT_ID'] = CLIENT_ID
  
  puts "✅ Added URL scheme to #{config.name} configuration"
end

# Add Gmail module to the project if not already added
gmail_ref = project.main_group.find_subpath('Modules/Gmail')
if gmail_ref.nil?
  gmail_ref = project.main_group.new_group('Gmail', 'Modules/Gmail')
  puts "✅ Added Gmail module reference to project"
else
  puts "✅ Gmail module already in project"
end

# Save the project
project.save
puts "✅ Project saved successfully"

puts "\n📝 Updating code files to enable Gmail integration..."

# Re-enable Gmail imports in AppDelegate.swift
app_delegate_path = 'AppDelegate.swift'
if File.exist?(app_delegate_path)
  content = File.read(app_delegate_path)
  
  # Uncomment the GoogleSignIn import
  content.gsub!('// import GoogleSignIn // TODO: Enable once Gmail module is integrated', 'import GoogleSignIn')
  
  # Uncomment the Google Sign-In handler
  content.gsub!('// return GIDSignIn.sharedInstance.handle(url) // TODO: Enable once Gmail module is integrated', 'return GIDSignIn.sharedInstance.handle(url)')
  
  File.write(app_delegate_path, content)
  puts "✅ Updated AppDelegate.swift"
end

# Re-enable Gmail in Receipts module Package.swift
receipts_package_path = 'Modules/Receipts/Package.swift'
if File.exist?(receipts_package_path)
  content = File.read(receipts_package_path)
  
  # Add Gmail to dependencies if not present
  unless content.include?('.package(path: "../Gmail")')
    content.gsub!(
      'dependencies: [
        .package(path: "../Core"),
        .package(path: "../SharedUI")',
      'dependencies: [
        .package(path: "../Core"),
        .package(path: "../SharedUI"),
        .package(path: "../Gmail")'
    )
    
    # Also add to target dependencies
    content.gsub!(
      'dependencies: ["Core", "SharedUI"]',
      'dependencies: ["Core", "SharedUI", "Gmail"]'
    )
    
    File.write(receipts_package_path, content)
    puts "✅ Updated Receipts Package.swift"
  end
end

# Re-enable Gmail import in ReceiptImportView.swift
receipt_import_path = 'Modules/Receipts/Sources/Views/ReceiptImportView.swift'
if File.exist?(receipt_import_path)
  # Read the original implementation we saved
  original_implementation = <<~SWIFT
import SwiftUI
import Core
import SharedUI
import Gmail

/// Receipt import view with Gmail integration
/// Swift 5.9 - No Swift 6 features
struct ReceiptImportView: View {
    @StateObject private var viewModel: ReceiptImportViewModel
    @StateObject private var gmailModule = GmailModule()
    @State private var selectedImportMethod: ImportMethod?
    @State private var showingGmailImport = false
    @State private var isImporting = false
    @State private var importError: Error?
    @State private var importedCount = 0
    
    enum ImportMethod: String, CaseIterable {
        case gmail = "Gmail"
        case camera = "Camera"
        case files = "Files"
        
        var icon: String {
            switch self {
            case .gmail: return "envelope.fill"
            case .camera: return "camera.fill"
            case .files: return "folder.fill"
            }
        }
        
        var description: String {
            switch self {
            case .gmail: return "Import receipts from Gmail"
            case .camera: return "Scan receipt with camera"
            case .files: return "Import from files"
            }
        }
    }
    
    init(viewModel: ReceiptImportViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(ImportMethod.allCases, id: \\.self) { method in
                        Button(action: {
                            handleImportMethod(method)
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: method.icon)
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                    .frame(width: 40)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(method.rawValue)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(method.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if method == .gmail && !gmailModule.isAuthenticated {
                                    Text("Not Connected")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.orange.opacity(0.2))
                                        .cornerRadius(4)
                                }
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Import Methods")
                }
                
                if importedCount > 0 {
                    Section {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("\\(importedCount) receipts imported successfully")
                                .font(.subheadline)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Import Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingGmailImport) {
                gmailModule.makeReceiptImportView()
                    .presentationDetents([.large])
            }
            .alert("Import Error", isPresented: .constant(importError != nil)) {
                Button("OK") {
                    importError = nil
                }
            } message: {
                if let error = importError {
                    Text(error.localizedDescription)
                }
            }
            .overlay {
                if isImporting {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                                
                                Text("Importing receipts...")
                                    .foregroundColor(.white)
                                    .font(.headline)
                            }
                            .padding(32)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(16)
                        }
                }
            }
        }
    }
    
    private func handleImportMethod(_ method: ImportMethod) {
        switch method {
        case .gmail:
            if gmailModule.isAuthenticated {
                importFromGmail()
            } else {
                showingGmailImport = true
            }
        case .camera:
            selectedImportMethod = method
        case .files:
            selectedImportMethod = method
        }
    }
    
    private func importFromGmail() {
        isImporting = true
        importError = nil
        
        Task {
            do {
                let receipts = try await gmailModule.fetchReceipts()
                
                await MainActor.run {
                    // Save receipts to repository
                    for receipt in receipts {
                        viewModel.saveReceipt(receipt)
                    }
                    
                    importedCount = receipts.count
                    isImporting = false
                    
                    // Show success message
                    if receipts.isEmpty {
                        importError = NSError(
                            domain: "ReceiptImport",
                            code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "No receipts found in Gmail"]
                        )
                    }
                }
            } catch {
                await MainActor.run {
                    importError = error
                    isImporting = false
                }
            }
        }
    }
}
SWIFT
  
  File.write(receipt_import_path, original_implementation)
  puts "✅ Restored ReceiptImportView.swift with Gmail integration"
end

# Create Info.plist configuration if needed
info_plist_content = <<~XML
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>#{URL_SCHEME}</string>
            </array>
        </dict>
    </array>
    <key>GIDClientID</key>
    <string>#{CLIENT_ID}</string>
</dict>
</plist>
XML

File.write('GoogleSignIn-Info.plist', info_plist_content)
puts "✅ Created GoogleSignIn-Info.plist configuration"

puts "\n🎉 Gmail integration configuration complete!"
puts "\n📋 Next steps:"
puts "1. Run 'make build' to rebuild the project"
puts "2. The Gmail import feature will be available in the Receipts tab"
puts "3. Users can sign in with Google to import receipts"
puts "\n🔐 OAuth Configuration:"
puts "   Client ID: #{CLIENT_ID}"
puts "   Redirect URI: #{REDIRECT_URI}"
puts "   URL Scheme: #{URL_SCHEME}"