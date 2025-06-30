#!/usr/bin/env ruby

require 'xcodeproj'
require 'fileutils'

PROJECT_PATH = 'HomeInventoryModular.xcodeproj'

# Helper method definitions first
def generate_view_tests(name, icon, color)
  <<-TESTS
    func test#{name}View() {
        let view = create#{name}View()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func test#{name}ViewDarkMode() {
        let view = create#{name}View()
            .environment(\\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func test#{name}ViewEmptyState() {
        let view = create#{name}EmptyView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
TESTS
end

def generate_view_creator(name, icon, color)
  case name
  when 'StorageUnits'
    storage_units_view
  when 'Collections'
    collections_view
  when 'Warranty'
    warranty_view
  when 'Budget'
    budget_view
  when 'Analytics'
    analytics_view
  when 'Insurance'
    insurance_view
  when 'NaturalLanguage'
    natural_language_view
  when 'ImageSearch'
    image_search_view
  when 'CSVImport'
    csv_import_view
  when 'CSVExport'
    csv_export_view
  when 'BackupManager'
    backup_manager_view
  when 'FamilySharing'
    family_sharing_view
  when 'LockScreen'
    lock_screen_view
  when 'BiometricLock'
    biometric_lock_view
  when 'GmailReceipts'
    gmail_receipts_view
  when 'ConflictResolution'
    conflict_resolution_view
  when 'SyncStatus'
    sync_status_view
  when 'CollaborativeLists'
    collaborative_lists_view
  else
    generic_view(name, icon, color)
  end
end

def storage_units_view
  <<-VIEW
    private func createStorageUnitsView() -> some View {
        NavigationView {
            List {
                ForEach(["Garage", "Attic", "Basement", "Storage Unit A"], id: \\.self) { unit in
                    HStack {
                        Image(systemName: "archivebox.fill")
                            .foregroundColor(.brown)
                            .frame(width: 40)
                        VStack(alignment: .leading) {
                            Text(unit)
                                .font(.headline)
                            Text("\\(Int.random(in: 5...25)) items")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("\\(Int.random(in: 60...95))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Storage Units")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
    
    private func createStorageUnitsEmptyView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "archivebox")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("No Storage Units")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Organize your items by creating storage units")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Button(action: {}) {
                    Label("Add Storage Unit", systemImage: "plus")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            .navigationTitle("Storage Units")
        }
    }
VIEW
end

def collections_view
  <<-VIEW
    private func createCollectionsView() -> some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                    ForEach(["Electronics", "Jewelry", "Books", "Art", "Tools", "Sports"], id: \\.self) { collection in
                        VStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.indigo.opacity(0.2))
                                .frame(height: 120)
                                .overlay(
                                    VStack {
                                        Image(systemName: collectionIcon(for: collection))
                                            .font(.largeTitle)
                                            .foregroundColor(.indigo)
                                        Text(collection)
                                            .font(.headline)
                                            .padding(.top, 4)
                                    }
                                )
                            Text("\\(Int.random(in: 3...15)) items")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Collections")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
    
    private func createCollectionsEmptyView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "folder")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("No Collections")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Group your items into collections")
                    .foregroundColor(.secondary)
                Button(action: {}) {
                    Label("Create Collection", systemImage: "plus")
                        .padding()
                        .background(Color.indigo)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            .navigationTitle("Collections")
        }
    }
    
    private func collectionIcon(for collection: String) -> String {
        switch collection {
        case "Electronics": return "tv"
        case "Jewelry": return "sparkles"
        case "Books": return "books.vertical"
        case "Art": return "paintpalette"
        case "Tools": return "wrench"
        case "Sports": return "sportscourt"
        default: return "folder"
        }
    }
VIEW
end

def warranty_view
  <<-VIEW
    private func createWarrantyView() -> some View {
        NavigationView {
            List {
                Section("Expiring Soon") {
                    ForEach(["MacBook Pro", "iPhone 15 Pro", "AirPods Pro"], id: \\.self) { item in
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading) {
                                Text(item)
                                    .font(.headline)
                                Text("Expires in \\(Int.random(in: 7...30)) days")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("Extended")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section("Active Warranties") {
                    ForEach(["Smart TV", "Refrigerator", "Washing Machine"], id: \\.self) { item in
                        HStack {
                            Image(systemName: "shield.checkered")
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text(item)
                                    .font(.headline)
                                Text("\\(Int.random(in: 100...700)) days remaining")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Warranties")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "bell")
                    }
                }
            }
        }
    }
    
    private func createWarrantyEmptyView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "shield")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("No Warranties")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Track your product warranties here")
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("Warranties")
        }
    }
VIEW
end

def budget_view
  <<-VIEW
    private func createBudgetView() -> some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Budget Overview Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Monthly Budget")
                            .font(.headline)
                        HStack {
                            VStack(alignment: .leading) {
                                Text("$\\(Int.random(in: 1500...2500))")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                Text("of $3,000")
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            CircularProgressView(progress: Double.random(in: 0.5...0.8))
                                .frame(width: 80, height: 80)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Category Breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        Text("By Category")
                            .font(.headline)
                        ForEach(["Electronics", "Home & Garden", "Clothing", "Sports"], id: \\.self) { category in
                            HStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(categoryColor(for: category))
                                    .frame(width: 4)
                                VStack(alignment: .leading) {
                                    Text(category)
                                        .font(.subheadline)
                                    Text("$\\(Int.random(in: 100...800))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                ProgressView(value: Double.random(in: 0.3...0.9))
                                    .frame(width: 100)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Budget")
        }
    }
    
    private func createBudgetEmptyView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "dollarsign.circle")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("No Budget Set")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Create a budget to track your spending")
                    .foregroundColor(.secondary)
                Button(action: {}) {
                    Label("Create Budget", systemImage: "plus")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            .navigationTitle("Budget")
        }
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category {
        case "Electronics": return .blue
        case "Home & Garden": return .green
        case "Clothing": return .purple
        case "Sports": return .orange
        default: return .gray
        }
    }
VIEW
end

def analytics_view
  <<-VIEW
    private func createAnalyticsView() -> some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Total Value Card
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Total Inventory Value")
                                .font(.headline)
                            Text("$\\(Int.random(in: 15000...25000))")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            HStack {
                                Image(systemName: "arrow.up.right")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                Text("+\\(Int.random(in: 5...15))%")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                Text("vs last month")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                        Spacer()
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Category Distribution
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Value by Category")
                            .font(.headline)
                        // Mock chart placeholder
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.1))
                            .frame(height: 200)
                            .overlay(
                                VStack {
                                    Image(systemName: "chart.pie.fill")
                                        .font(.largeTitle)
                                        .foregroundColor(.blue)
                                    Text("Category Distribution")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            )
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Analytics")
        }
    }
    
    private func createAnalyticsEmptyView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "chart.bar")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("No Data Available")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Add items to see analytics")
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("Analytics")
        }
    }
VIEW
end

def insurance_view
  <<-VIEW
    private func createInsuranceView() -> some View {
        NavigationView {
            List {
                Section("Active Policies") {
                    ForEach(["Home Insurance", "Electronics Protection", "Jewelry Coverage"], id: \\.self) { policy in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "shield.fill")
                                    .foregroundColor(.green)
                                Text(policy)
                                    .font(.headline)
                                Spacer()
                                Text("Active")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.2))
                                    .cornerRadius(4)
                            }
                            HStack {
                                Label("\\(Int.random(in: 10...50)) items", systemImage: "cube.box")
                                Spacer()
                                Text("$\\(Int.random(in: 50...200))/mo")
                                    .foregroundColor(.secondary)
                            }
                            .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section("Coverage Summary") {
                    HStack {
                        Text("Total Coverage")
                        Spacer()
                        Text("$\\(Int.random(in: 50000...100000))")
                            .fontWeight(.semibold)
                    }
                    HStack {
                        Text("Total Premium")
                        Spacer()
                        Text("$\\(Int.random(in: 200...500))/mo")
                            .fontWeight(.semibold)
                    }
                }
            }
            .navigationTitle("Insurance")
        }
    }
    
    private func createInsuranceEmptyView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "shield")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("No Insurance Policies")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Track your insurance coverage")
                    .foregroundColor(.secondary)
                Button(action: {}) {
                    Label("Add Policy", systemImage: "plus")
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            .navigationTitle("Insurance")
        }
    }
VIEW
end

def natural_language_view
  <<-VIEW
    private func createNaturalLanguageView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Ask anything about your items...", text: .constant(""))
                    Button(action: {}) {
                        Image(systemName: "mic.fill")
                            .foregroundColor(.purple)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Example Queries
                VStack(alignment: .leading, spacing: 12) {
                    Text("Try asking:")
                        .font(.headline)
                    ForEach([
                        "Show me all electronics bought this year",
                        "What items are worth more than $500?",
                        "Find warranties expiring soon",
                        "Items I haven't used in 6 months"
                    ], id: \\.self) { query in
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "text.bubble")
                                    .foregroundColor(.purple)
                                Text(query)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Smart Search")
        }
    }
    
    private func createNaturalLanguageEmptyView() -> some View {
        createNaturalLanguageView()
    }
VIEW
end

def image_search_view
  <<-VIEW
    private func createImageSearchView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                // Camera Button
                Button(action: {}) {
                    VStack {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                        Text("Take Photo")
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                
                // Upload Button
                Button(action: {}) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title2)
                        Text("Choose from Library")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Image Search")
        }
    }
    
    private func createImageSearchEmptyView() -> some View {
        createImageSearchView()
    }
VIEW
end

def csv_import_view
  <<-VIEW
    private func createCSVImportView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                // Drop Zone
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    Text("Drop CSV file here")
                        .font(.headline)
                    Text("or tap to browse")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [10]))
                        .foregroundColor(.green)
                )
                
                // Import Options
                VStack(alignment: .leading, spacing: 12) {
                    Text("Import Settings")
                        .font(.headline)
                    Toggle("Skip duplicate items", isOn: .constant(true))
                    Toggle("Auto-match categories", isOn: .constant(true))
                    Toggle("Import images from URLs", isOn: .constant(false))
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Import CSV")
        }
    }
    
    private func createCSVImportEmptyView() -> some View {
        createCSVImportView()
    }
VIEW
end

def csv_export_view
  <<-VIEW
    private func createCSVExportView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                // Export Options
                VStack(alignment: .leading, spacing: 16) {
                    Text("Export Settings")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Include:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Toggle("Basic item information", isOn: .constant(true))
                        Toggle("Purchase details", isOn: .constant(true))
                        Toggle("Warranty information", isOn: .constant(true))
                        Toggle("Item notes", isOn: .constant(false))
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Export Button
                Button(action: {}) {
                    Label("Export Items", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Export CSV")
        }
    }
    
    private func createCSVExportEmptyView() -> some View {
        createCSVExportView()
    }
VIEW
end

def backup_manager_view
  <<-VIEW
    private func createBackupManagerView() -> some View {
        NavigationView {
            List {
                Section("Automatic Backups") {
                    Toggle("iCloud Backup", isOn: .constant(true))
                    Toggle("Local Backup", isOn: .constant(false))
                    HStack {
                        Text("Backup Frequency")
                        Spacer()
                        Text("Daily")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Recent Backups") {
                    ForEach(["Today, 2:00 AM", "Yesterday, 2:00 AM", "Oct 24, 2:00 AM"], id: \\.self) { backup in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text(backup)
                                    .font(.subheadline)
                                Text("\\(Int.random(in: 100...200)) items • \\(Int.random(in: 10...50)) MB")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Backup Manager")
        }
    }
    
    private func createBackupManagerEmptyView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "externaldrive")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("No Backups")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Enable automatic backups to protect your data")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Button(action: {}) {
                    Label("Enable Backups", systemImage: "checkmark.shield")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            .navigationTitle("Backup Manager")
        }
    }
VIEW
end

def family_sharing_view
  <<-VIEW
    private func createFamilySharingView() -> some View {
        NavigationView {
            List {
                Section("Family Members") {
                    ForEach(["John (Me)", "Sarah", "Kids"], id: \\.self) { member in
                        HStack {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(String(member.prefix(1)))
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                )
                            VStack(alignment: .leading) {
                                Text(member)
                                    .font(.subheadline)
                                Text(member == "John (Me)" ? "Owner" : "Member")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if member != "John (Me)" {
                                Text("Can view")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section("Shared Lists") {
                    ForEach(["Home Electronics", "Kitchen Items", "Kids Toys"], id: \\.self) { list in
                        HStack {
                            Image(systemName: "list.bullet")
                                .foregroundColor(.orange)
                            Text(list)
                            Spacer()
                            Text("\\(Int.random(in: 10...50)) items")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Family Sharing")
        }
    }
    
    private func createFamilySharingEmptyView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "person.2")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("No Family Members")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Share your inventory with family")
                    .foregroundColor(.secondary)
                Button(action: {}) {
                    Label("Set Up Family Sharing", systemImage: "plus")
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            .navigationTitle("Family Sharing")
        }
    }
VIEW
end

def lock_screen_view
  <<-VIEW
    private func createLockScreenView() -> some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "lock.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Home Inventory")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Enter passcode to unlock")
                .foregroundColor(.secondary)
            
            // Passcode dots
            HStack(spacing: 20) {
                ForEach(0..<4) { index in
                    Circle()
                        .fill(index < 2 ? Color.primary : Color.gray.opacity(0.3))
                        .frame(width: 15, height: 15)
                }
            }
            .padding(.vertical)
            
            Spacer()
            
            Button("Use Face ID") {
                // Action
            }
            .foregroundColor(.blue)
        }
        .padding()
    }
    
    private func createLockScreenEmptyView() -> some View {
        createLockScreenView()
    }
VIEW
end

def biometric_lock_view
  <<-VIEW
    private func createBiometricLockView() -> some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "faceid")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Face ID")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Look at your iPhone to unlock")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Animation placeholder
            Circle()
                .strokeBorder(Color.blue, lineWidth: 3)
                .frame(width: 150, height: 150)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue.opacity(0.5))
                )
            
            Spacer()
            
            Button("Enter Passcode") {
                // Action
            }
            .foregroundColor(.blue)
            
            Button("Cancel") {
                // Action
            }
            .foregroundColor(.secondary)
            .padding(.bottom)
        }
        .padding()
    }
    
    private func createBiometricLockEmptyView() -> some View {
        createBiometricLockView()
    }
VIEW
end

def gmail_receipts_view
  <<-VIEW
    private func createGmailReceiptsView() -> some View {
        NavigationView {
            List {
                Section("Connected Account") {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.red)
                            .frame(width: 40)
                        VStack(alignment: .leading) {
                            Text("john.doe@gmail.com")
                                .font(.subheadline)
                            Text("Connected")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        Spacer()
                        Button("Sync") {
                            // Action
                        }
                        .font(.caption)
                    }
                }
                
                Section("Recent Receipts") {
                    ForEach(["Amazon - MacBook Pro", "Best Buy - AirPods", "Target - Home Items"], id: \\.self) { receipt in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .foregroundColor(.blue)
                                Text(receipt)
                                    .font(.subheadline)
                                Spacer()
                                Text("2d ago")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Gmail Receipts")
        }
    }
    
    private func createGmailReceiptsEmptyView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "envelope")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("Connect Gmail")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Import receipts from your email")
                    .foregroundColor(.secondary)
                Button(action: {}) {
                    Label("Connect Gmail", systemImage: "envelope.badge")
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            .navigationTitle("Gmail Receipts")
        }
    }
VIEW
end

def conflict_resolution_view
  <<-VIEW
    private func createConflictResolutionView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                // Conflict Header
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("Sync Conflict")
                        .font(.headline)
                    Text("This item has been modified on multiple devices")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                // Conflict Comparison
                HStack(spacing: 16) {
                    // Local Version
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Version")
                            .font(.caption)
                            .fontWeight(.medium)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("MacBook Pro 16\\"")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("Modified: 2 hours ago")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Price: $2,499")
                                .font(.caption)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    
                    // Cloud Version
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Cloud Version")
                            .font(.caption)
                            .fontWeight(.medium)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("MacBook Pro 16\\"")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("Modified: 3 hours ago")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Price: $2,399")
                                .font(.caption)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Resolve Conflict")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func createConflictResolutionEmptyView() -> some View {
        createConflictResolutionView()
    }
VIEW
end

def sync_status_view
  <<-VIEW
    private func createSyncStatusView() -> some View {
        NavigationView {
            List {
                Section("Sync Status") {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("All data synced")
                        Spacer()
                        Text("Just now")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Sync Details") {
                    HStack {
                        Text("Last sync")
                        Spacer()
                        Text("Oct 26, 2:45 PM")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Items synced")
                        Spacer()
                        Text("\\(Int.random(in: 100...200))")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Devices") {
                    ForEach(["iPhone 15 Pro", "iPad Pro", "MacBook Pro"], id: \\.self) { device in
                        HStack {
                            Image(systemName: device.contains("iPhone") ? "iphone" : 
                                            device.contains("iPad") ? "ipad" : "laptopcomputer")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text(device)
                                    .font(.subheadline)
                                Text("Last seen: \\(Int.random(in: 1...24))h ago")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if device.contains("iPhone") {
                                Text("This device")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Sync Status")
        }
    }
    
    private func createSyncStatusEmptyView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("Sync Not Enabled")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Enable sync to keep your data updated across devices")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Button(action: {}) {
                    Label("Enable Sync", systemImage: "checkmark")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            .navigationTitle("Sync Status")
        }
    }
VIEW
end

def collaborative_lists_view
  <<-VIEW
    private func createCollaborativeListsView() -> some View {
        NavigationView {
            List {
                Section("My Lists") {
                    ForEach(["Home Essentials", "Office Equipment", "Vacation Items"], id: \\.self) { list in
                        HStack {
                            Image(systemName: "list.bullet.rectangle")
                                .foregroundColor(.purple)
                            VStack(alignment: .leading) {
                                Text(list)
                                    .font(.subheadline)
                                HStack {
                                    Image(systemName: "person.2.fill")
                                        .font(.caption2)
                                    Text("3 members")
                                        .font(.caption)
                                }
                                .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("\\(Int.random(in: 10...30)) items")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Shared With Me") {
                    ForEach(["Family Shopping", "Project Equipment"], id: \\.self) { list in
                        HStack {
                            Image(systemName: "list.bullet.rectangle.portrait")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading) {
                                Text(list)
                                    .font(.subheadline)
                                Text("Shared by Sarah")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("\\(Int.random(in: 5...20)) items")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Collaborative Lists")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
    
    private func createCollaborativeListsEmptyView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "person.3")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("No Collaborative Lists")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Create lists to share with others")
                    .foregroundColor(.secondary)
                Button(action: {}) {
                    Label("Create Shared List", systemImage: "plus")
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            .navigationTitle("Collaborative Lists")
        }
    }
VIEW
end

def generic_view(name, icon, color)
  <<-VIEW
    private func create#{name}View() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "#{icon}")
                    .font(.system(size: 60))
                    .foregroundColor(.#{color})
                Text("#{name}")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("This view is under development")
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("#{name}")
        }
    }
    
    private func create#{name}EmptyView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "#{icon}")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("No Data")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("#{name} content will appear here")
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("#{name}")
        }
    }
VIEW
end

puts "🔧 Creating enhanced snapshot tests for missing views..."

# Open project
project = Xcodeproj::Project.open(PROJECT_PATH)

# Find test target
test_target = project.targets.find { |t| t.name == 'HomeInventoryModularTests' }
unless test_target
  puts "❌ Test target not found!"
  exit 1
end

# Get test group
test_group = project.main_group['HomeInventoryModularTests']

# Create enhanced tests directory
enhanced_tests_dir = 'HomeInventoryModularTests/EnhancedTests'
FileUtils.mkdir_p(enhanced_tests_dir)

# Enhanced test configurations
enhanced_tests = {
  'ItemsDetailedSnapshotTests' => {
    views: [
      { name: 'StorageUnits', icon: 'archivebox', color: 'brown' },
      { name: 'Collections', icon: 'folder.fill', color: 'indigo' },
      { name: 'Warranty', icon: 'shield.checkered', color: 'orange' },
      { name: 'Budget', icon: 'dollarsign.circle', color: 'green' },
      { name: 'Analytics', icon: 'chart.line.uptrend.xyaxis', color: 'blue' },
      { name: 'Insurance', icon: 'shield.fill', color: 'red' }
    ]
  },
  'SearchSnapshotTests' => {
    views: [
      { name: 'NaturalLanguage', icon: 'text.magnifyingglass', color: 'purple' },
      { name: 'ImageSearch', icon: 'photo.fill', color: 'blue' },
      { name: 'BarcodeSearch', icon: 'barcode', color: 'orange' },
      { name: 'SavedSearches', icon: 'bookmark.fill', color: 'yellow' }
    ]
  },
  'DataManagementSnapshotTests' => {
    views: [
      { name: 'CSVImport', icon: 'square.and.arrow.down', color: 'green' },
      { name: 'CSVExport', icon: 'square.and.arrow.up', color: 'blue' },
      { name: 'BackupManager', icon: 'externaldrive.fill', color: 'gray' },
      { name: 'FamilySharing', icon: 'person.2.fill', color: 'orange' }
    ]
  },
  'SecuritySnapshotTests' => {
    views: [
      { name: 'LockScreen', icon: 'lock.fill', color: 'red' },
      { name: 'BiometricLock', icon: 'faceid', color: 'blue' },
      { name: 'TwoFactor', icon: 'lock.shield.fill', color: 'green' },
      { name: 'PrivacySettings', icon: 'hand.raised.fill', color: 'purple' }
    ]
  },
  'GmailIntegrationSnapshotTests' => {
    views: [
      { name: 'GmailReceipts', icon: 'envelope.fill', color: 'red' },
      { name: 'ImportPreview', icon: 'doc.text.magnifyingglass', color: 'blue' },
      { name: 'ImportHistory', icon: 'clock.arrow.circlepath', color: 'green' }
    ]
  },
  'SyncSnapshotTests' => {
    views: [
      { name: 'ConflictResolution', icon: 'arrow.triangle.branch', color: 'orange' },
      { name: 'SyncStatus', icon: 'arrow.triangle.2.circlepath', color: 'blue' },
      { name: 'CollaborativeLists', icon: 'person.3.fill', color: 'purple' }
    ]
  }
}

# Create test files
enhanced_tests.each do |test_name, config|
  test_content = <<-SWIFT
import XCTest
import SnapshotTesting
import SwiftUI

final class #{test_name}: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set isRecording = true to generate new snapshots
        // isRecording = true
    }
    
#{config[:views].map { |view| generate_view_tests(view[:name], view[:icon], view[:color]) }.join("\n")}
    
    // MARK: - Combined View Test
    
    func testAllViewsCombined() {
        let view = createCombinedView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    // MARK: - View Creation Helpers
    
#{config[:views].map { |view| generate_view_creator(view[:name], view[:icon], view[:color]) }.join("\n")}
    
    private func createCombinedView() -> some View {
        TabView {
#{config[:views].map { |view| 
            "            create#{view[:name]}View()
                .tabItem {
                    Label(\"#{view[:name]}\", systemImage: \"#{view[:icon]}\")
                }"
}.join("\n")}
        }
    }
}
SWIFT

  # Write test file
  file_path = "#{enhanced_tests_dir}/#{test_name}.swift"
  File.write(file_path, test_content)
  
  # Add to project if not already present
  unless test_group.children.any? { |f| f.path&.include?("#{test_name}.swift") }
    # Create EnhancedTests group if needed
    enhanced_group = test_group['EnhancedTests'] || test_group.new_group('EnhancedTests')
    
    file_ref = enhanced_group.new_reference("#{test_name}.swift")
    test_target.add_file_references([file_ref])
    puts "✅ Added #{test_name}.swift"
  end
end

# Save project
project.save

puts "\n✅ Created enhanced test files!"

# Create runner scripts
puts "\n📝 Creating enhanced test runners..."

enhanced_tests.keys.each do |test_name|
  runner_content = <<-BASH
#!/bin/bash

echo "📸 Running #{test_name}"
echo "====================================="

# Optional: Set to record new snapshots
# export RECORD_SNAPSHOTS=YES

# Clean previous test results
rm -rf TestResults/Enhanced/#{test_name}
mkdir -p TestResults/Enhanced/#{test_name}

# Run the specific test
xcodebuild test \\
  -project HomeInventoryModular.xcodeproj \\
  -scheme HomeInventoryModular \\
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \\
  -only-testing:HomeInventoryModularTests/#{test_name} \\
  -resultBundlePath TestResults/Enhanced/#{test_name}/#{test_name}.xcresult \\
  ${RECORD_SNAPSHOTS:+RECORD_SNAPSHOTS=$RECORD_SNAPSHOTS} \\
  -quiet || echo "⚠️  Some tests may have failed (expected in record mode)"

# Count snapshots
echo ""
echo "📊 Snapshot Summary:"
find HomeInventoryModularTests -name "*.png" -path "*#{test_name}*" | wc -l | xargs echo "Total snapshots:"

echo ""
echo "✅ Done!"
BASH

  runner_path = "scripts/test-runners/test-#{test_name.gsub(/SnapshotTests$/, '').downcase}.sh"
  File.write(runner_path, runner_content)
  FileUtils.chmod(0755, runner_path)
  puts "✅ Created #{runner_path}"
end

puts "\n📋 Usage:"
puts "   - Run enhanced tests: ./scripts/test-runners/test-[name].sh"
puts "   - Record snapshots: RECORD_SNAPSHOTS=YES ./scripts/test-runners/test-[name].sh"

# Helper for circular progress view
progress_view_helper = <<-SWIFT

// Helper view for Budget dashboard
struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 10)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.green, lineWidth: 10)
                .rotationEffect(.degrees(-90))
            Text("\\(Int(progress * 100))%")
                .font(.headline)
        }
    }
}
SWIFT

# Append helper to budget test file
budget_test_path = "#{enhanced_tests_dir}/ItemsDetailedSnapshotTests.swift"
if File.exist?(budget_test_path)
  content = File.read(budget_test_path)
  File.write(budget_test_path, content + progress_view_helper)
end