import XCTest
import SnapshotTesting
import SwiftUI

final class FormValidationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set isRecording = true to generate new snapshots
        // isRecording = true
    }
    
    func testAddItemFormValidation() {
        let view = AddItemFormView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testAddItemFormWithErrors() {
        let view = AddItemFormView(showingErrors: true)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testLoginFormValidation() {
        let view = LoginFormView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testSettingsFormValidation() {
        let view = SettingsFormView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
}

// MARK: - Helper Views

struct AddItemFormView: View {
    let showingErrors: Bool
    
    init(showingErrors: Bool = false) {
        self.showingErrors = showingErrors
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Item Details") {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Item Name", text: .constant(""))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        if showingErrors {
                            Text("Item name is required")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Description", text: .constant(""), axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Value")
                            Spacer()
                            TextField("$0.00", text: .constant(""))
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                                .frame(width: 100)
                        }
                        if showingErrors {
                            Text("Please enter a valid amount")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section("Category") {
                    Picker("Category", selection: .constant(0)) {
                        Text("Electronics").tag(0)
                        Text("Furniture").tag(1)
                        Text("Clothing").tag(2)
                        Text("Books").tag(3)
                        Text("Other").tag(4)
                    }
                }
                
                Section("Photos") {
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Add Photos")
                        }
                    }
                }
                
                Section {
                    Button(action: {}) {
                        HStack {
                            Spacer()
                            Text("Save Item")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .foregroundColor(showingErrors ? .gray : .white)
                    .listRowBackground(showingErrors ? Color.gray.opacity(0.3) : Color.blue)
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {}
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {}
                        .fontWeight(.semibold)
                        .disabled(showingErrors)
                }
            }
        }
    }
}

struct LoginFormView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "house.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Welcome Back")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Email", text: .constant(""))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    Text("Please enter a valid email")
                        .font(.caption)
                        .foregroundColor(.red)
                        .opacity(0)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    SecureField("Password", text: .constant(""))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Text("Password must be at least 8 characters")
                        .font(.caption)
                        .foregroundColor(.red)
                        .opacity(0)
                }
            }
            .padding(.horizontal, 32)
            
            Button(action: {}) {
                Text("Sign In")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            
            HStack {
                Button("Forgot Password?") {}
                    .font(.footnote)
                Spacer()
                Button("Create Account") {}
                    .font(.footnote)
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .background(Color(.systemBackground))
    }
}

struct SettingsFormView: View {
    var body: some View {
        NavigationView {
            Form {
                Section("Account") {
                    HStack {
                        Text("Email")
                        Spacer()
                        Text("user@example.com")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Subscription")
                        Spacer()
                        Text("Premium")
                            .foregroundColor(.green)
                    }
                }
                
                Section("Preferences") {
                    Toggle("Enable Notifications", isOn: .constant(true))
                    Toggle("Auto-Backup", isOn: .constant(true))
                    
                    Picker("Currency", selection: .constant(0)) {
                        Text("USD ($)").tag(0)
                        Text("EUR (€)").tag(1)
                        Text("GBP (£)").tag(2)
                    }
                }
                
                Section("Data") {
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Export Data")
                        }
                    }
                    
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete All Data")
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}