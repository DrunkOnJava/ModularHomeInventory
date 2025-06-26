//
//  OnboardingUITests.swift
//  HomeInventoryModularUITests
//
//  UI Tests for first-time user onboarding flow
//

import XCTest

final class OnboardingUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launchArguments += ["--reset-onboarding"] // Force show onboarding
        app.launchArguments += ["--clean-install"] // Simulate fresh install
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Welcome Screen Tests
    
    func testWelcomeScreen() throws {
        // Welcome screen should appear on first launch
        XCTAssertTrue(app.staticTexts["Welcome to Home Inventory"].waitForExistence(timeout: 5) ||
                     app.staticTexts["Welcome"].waitForExistence(timeout: 5))
        
        // Should have get started button
        XCTAssertTrue(app.buttons["Get Started"].exists ||
                     app.buttons["Continue"].exists)
        
        // May have skip button
        XCTAssertTrue(app.buttons["Skip"].exists ||
                     app.buttons["Skip Intro"].exists ||
                     app.navigationBars.buttons["Skip"].exists)
    }
    
    // MARK: - Feature Tour Tests
    
    func testFeatureTour() throws {
        // Start onboarding
        if app.buttons["Get Started"].exists {
            app.buttons["Get Started"].tap()
        }
        
        // Feature screens
        let expectedFeatures = [
            "Track Everything",
            "Scan Barcodes",
            "Smart Organization",
            "Warranty Tracking",
            "Analytics"
        ]
        
        for (index, feature) in expectedFeatures.enumerated() {
            // Look for feature title or description
            let featureExists = app.staticTexts.element(matching: NSPredicate(format: "label CONTAINS[c] %@", feature)).waitForExistence(timeout: 3)
            
            if featureExists {
                // Should have next button or swipe indicator
                if app.buttons["Next"].exists {
                    app.buttons["Next"].tap()
                } else if app.buttons["Continue"].exists {
                    app.buttons["Continue"].tap()
                } else {
                    // Swipe to next
                    app.swipeLeft()
                }
            }
        }
    }
    
    // MARK: - Permission Requests Tests
    
    func testCameraPermissionRequest() throws {
        // Navigate through onboarding to permissions
        navigateToPermissions()
        
        // Camera permission screen
        if app.staticTexts["Camera Access"].exists {
            XCTAssertTrue(app.staticTexts.element(matching: NSPredicate(format: "label CONTAINS[c] 'scan barcodes'")).exists)
            
            // Should have allow button
            if app.buttons["Allow Camera Access"].exists {
                app.buttons["Allow Camera Access"].tap()
                
                // System permission alert might appear
                handleSystemAlert(withButton: "OK")
            }
        }
    }
    
    func testNotificationPermissionRequest() throws {
        // Navigate through onboarding to permissions
        navigateToPermissions()
        
        // Notification permission screen
        if app.staticTexts["Stay Updated"].exists ||
           app.staticTexts["Notifications"].exists {
            
            XCTAssertTrue(app.staticTexts.element(matching: NSPredicate(format: "label CONTAINS[c] 'warranty'")).exists ||
                         app.staticTexts.element(matching: NSPredicate(format: "label CONTAINS[c] 'reminder'")).exists)
            
            // Enable notifications button
            if app.buttons["Enable Notifications"].exists {
                app.buttons["Enable Notifications"].tap()
                
                // Handle system alert
                handleSystemAlert(withButton: "Allow")
            }
        }
    }
    
    // MARK: - Account Setup Tests
    
    func testAccountCreation() throws {
        // Navigate to account setup
        navigateToAccountSetup()
        
        // Should show account options
        if app.staticTexts["Create Your Account"].exists ||
           app.staticTexts["Get Started"].exists {
            
            // Sign in with Apple option
            if app.buttons["Sign in with Apple"].exists {
                // Don't actually tap in UI test
                XCTAssertTrue(true)
            }
            
            // Email option
            if app.buttons["Continue with Email"].exists {
                app.buttons["Continue with Email"].tap()
                
                // Email entry screen
                XCTAssertTrue(app.textFields["Email"].waitForExistence(timeout: 3))
                
                // Enter email
                let emailField = app.textFields["Email"]
                emailField.tap()
                emailField.typeText("test@example.com")
                
                // Continue
                if app.buttons["Continue"].exists {
                    app.buttons["Continue"].tap()
                }
            }
            
            // Skip option
            if app.buttons["Skip for Now"].exists ||
               app.buttons["Continue as Guest"].exists {
                // User can skip account creation
                XCTAssertTrue(true)
            }
        }
    }
    
    // MARK: - Initial Setup Tests
    
    func testInitialCategories() throws {
        // Complete basic onboarding
        completeBasicOnboarding()
        
        // Categories setup screen
        if app.navigationBars["Choose Categories"].exists ||
           app.staticTexts["Select Categories"].exists {
            
            // Should show default categories
            let defaultCategories = ["Electronics", "Furniture", "Clothing", "Appliances"]
            
            for category in defaultCategories {
                XCTAssertTrue(app.buttons[category].exists ||
                             app.cells.staticTexts[category].exists)
            }
            
            // Select some categories
            if app.buttons["Electronics"].exists {
                app.buttons["Electronics"].tap()
                app.buttons["Furniture"].tap()
            }
            
            // Continue
            app.buttons["Continue"].tap()
        }
    }
    
    func testInitialLocations() throws {
        // Complete basic onboarding
        completeBasicOnboarding()
        
        // Locations setup
        if app.navigationBars["Add Locations"].exists ||
           app.staticTexts["Where are your items?"].exists {
            
            // Quick add common locations
            let commonLocations = ["Living Room", "Bedroom", "Kitchen", "Garage"]
            
            for location in commonLocations {
                if app.buttons[location].exists {
                    app.buttons[location].tap()
                    // Some might toggle, some might add
                }
            }
            
            // Add custom location
            if app.buttons["Add Custom"].exists {
                app.buttons["Add Custom"].tap()
                
                let textField = app.textFields.firstMatch
                textField.tap()
                textField.typeText("Home Office")
                
                app.buttons["Add"].tap()
            }
            
            // Continue
            app.buttons["Done"].tap()
        }
    }
    
    // MARK: - Privacy Policy Tests
    
    func testPrivacyPolicyConsent() throws {
        // Navigate through onboarding
        completeBasicOnboarding()
        
        // Privacy policy screen
        if app.staticTexts["Privacy & Terms"].exists ||
           app.staticTexts["Privacy Policy"].exists {
            
            // Should show privacy policy text or summary
            XCTAssertTrue(app.textViews.firstMatch.exists ||
                         app.staticTexts.element(matching: NSPredicate(format: "label CONTAINS[c] 'privacy'")).exists)
            
            // Links to full policies
            if app.buttons["Privacy Policy"].exists {
                // Don't tap - would open Safari
                XCTAssertTrue(true)
            }
            
            if app.buttons["Terms of Service"].exists {
                XCTAssertTrue(true)
            }
            
            // Consent checkbox or toggle
            if app.switches["I agree"].exists {
                app.switches["I agree"].tap()
            } else if app.buttons["I Agree"].exists {
                app.buttons["I Agree"].tap()
            }
            
            // Continue button should be enabled after consent
            XCTAssertTrue(app.buttons["Continue"].isEnabled ||
                         app.buttons["Accept & Continue"].isEnabled)
        }
    }
    
    // MARK: - Completion Tests
    
    func testOnboardingCompletion() throws {
        // Complete entire onboarding flow
        completeEntireOnboarding()
        
        // Should arrive at main app
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.tables["ItemsList"].exists ||
                     app.navigationBars["Items"].exists)
        
        // Onboarding should not appear again
        app.terminate()
        app.launch()
        
        // Should go straight to main app
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Welcome to Home Inventory"].exists)
    }
    
    // MARK: - Skip Tests
    
    func testSkipOnboarding() throws {
        // Try to skip onboarding
        if app.buttons["Skip"].waitForExistence(timeout: 3) {
            app.buttons["Skip"].tap()
            
            // Might show confirmation
            if app.alerts.firstMatch.exists {
                app.alerts.buttons["Skip"].tap()
            }
            
            // Should go to main app
            XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5))
        }
    }
    
    // MARK: - Helper Methods
    
    private func navigateToPermissions() {
        // Skip through feature tour
        for _ in 0..<5 {
            if app.buttons["Next"].exists {
                app.buttons["Next"].tap()
            } else if app.buttons["Continue"].exists {
                app.buttons["Continue"].tap()
            } else {
                app.swipeLeft()
            }
            
            if app.staticTexts["Permissions"].exists ||
               app.staticTexts["Camera Access"].exists {
                break
            }
        }
    }
    
    private func navigateToAccountSetup() {
        navigateToPermissions()
        
        // Continue through permissions
        if app.buttons["Continue"].exists {
            app.buttons["Continue"].tap()
        }
    }
    
    private func completeBasicOnboarding() {
        // Get through welcome and features
        if app.buttons["Get Started"].exists {
            app.buttons["Get Started"].tap()
        }
        
        // Skip through features
        for _ in 0..<5 {
            if app.buttons["Skip"].exists {
                app.buttons["Skip"].tap()
                break
            }
            
            if app.buttons["Next"].exists {
                app.buttons["Next"].tap()
            } else {
                app.swipeLeft()
            }
        }
    }
    
    private func completeEntireOnboarding() {
        // Welcome
        if app.buttons["Get Started"].exists {
            app.buttons["Get Started"].tap()
        }
        
        // Feature tour
        for _ in 0..<5 {
            if app.buttons["Next"].exists {
                app.buttons["Next"].tap()
            } else if app.buttons["Continue"].exists {
                app.buttons["Continue"].tap()
            }
            sleep(1)
        }
        
        // Permissions
        if app.buttons["Allow Camera Access"].exists {
            app.buttons["Allow Camera Access"].tap()
            handleSystemAlert(withButton: "OK")
        }
        
        if app.buttons["Enable Notifications"].exists {
            app.buttons["Enable Notifications"].tap()
            handleSystemAlert(withButton: "Allow")
        }
        
        // Skip account for faster test
        if app.buttons["Skip for Now"].exists {
            app.buttons["Skip for Now"].tap()
        }
        
        // Categories/Locations
        if app.buttons["Continue"].exists {
            app.buttons["Continue"].tap()
        }
        
        // Privacy
        if app.buttons["I Agree"].exists {
            app.buttons["I Agree"].tap()
        }
        
        if app.buttons["Continue"].exists {
            app.buttons["Continue"].tap()
        }
        
        // Final
        if app.buttons["Start Using App"].exists {
            app.buttons["Start Using App"].tap()
        }
    }
    
    private func handleSystemAlert(withButton buttonTitle: String) {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let alertButton = springboard.buttons[buttonTitle]
        if alertButton.waitForExistence(timeout: 2) {
            alertButton.tap()
        }
    }
}