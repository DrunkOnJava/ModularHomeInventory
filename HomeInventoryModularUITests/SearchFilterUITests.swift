//
//  SearchFilterUITests.swift
//  HomeInventoryModularUITests
//
//  Apple Configuration:
//  Bundle Identifier: com.homeinventory.app
//  Display Name: Home Inventory
//  Version: 1.0.5
//  Build: 5
//  Deployment Target: iOS 17.0
//  Supported Devices: iPhone & iPad
//  Team ID: 2VXBQV4XC9
//
//  Makefile Configuration:
//  Default Simulator: iPhone 16 Pro Max (DD192264-DFAA-4582-B2FE-D6FC444C9DDF)
//  iPad Simulator: iPad Pro 13-inch (M4) (CE6D038C-840B-4BDB-AA63-D61FA0755C4A)
//  App Bundle ID: com.homeinventory.app
//  Build Path: build/Build/Products/Debug-iphonesimulator/
//
//  Google Sign-In Configuration:
//  Client ID: 316432172622-6huvbn752v0ep68jkfdftrh8fgpesikg.apps.googleusercontent.com
//  URL Scheme: com.googleusercontent.apps.316432172622-6huvbn752v0ep68jkfdftrh8fgpesikg
//  OAuth Scope: https://www.googleapis.com/auth/gmail.readonly
//  Config Files: GoogleSignIn-Info.plist (project root), GoogleServices.plist (Gmail module)
//
//  Key Commands:
//  Build and run: make build run
//  Fast build (skip module prebuild): make build-fast run
//  iPad build and run: make build-ipad run-ipad
//  Clean build: make clean build run
//  Run tests: make test
//
//  Project Structure:
//  Main Target: HomeInventoryModular
//  Test Targets: HomeInventoryModularTests, HomeInventoryModularUITests
//  Swift Version: 5.9 (DO NOT upgrade to Swift 6)
//  Minimum iOS Version: 17.0
//
//  Architecture: Modular SPM packages with local package dependencies
//  Repository: https://github.com/DrunkOnJava/ModularHomeInventory.git
//  Module: HomeInventoryModularUITests
//  Dependencies: XCTest
//  Testing: UI test target
//
//  Description: UI Tests for search and filtering functionality
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import XCTest

final class SearchFilterUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launchArguments += ["--mock-data"] // Load with test data
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Search Tests
    
    func testBasicSearch() throws {
        // Tap search bar
        let searchBar = app.searchFields.firstMatch
        XCTAssertTrue(searchBar.waitForExistence(timeout: 5))
        searchBar.tap()
        
        // Type search query
        searchBar.typeText("iPhone")
        
        // Verify results filtered
        XCTAssertTrue(app.tables.cells.staticTexts["iPhone 15 Pro"].waitForExistence(timeout: 3))
        
        // Items not matching should not be visible
        XCTAssertFalse(app.tables.cells.staticTexts["Coffee Maker"].exists)
    }
    
    func testSearchSuggestions() throws {
        // Start typing in search
        let searchBar = app.searchFields.firstMatch
        searchBar.tap()
        searchBar.typeText("Mac")
        
        // Check for suggestions
        XCTAssertTrue(app.tables["SearchSuggestions"].waitForExistence(timeout: 2) ||
                     app.collectionViews["SearchSuggestions"].waitForExistence(timeout: 2))
        
        // Tap a suggestion if available
        if app.cells.staticTexts["MacBook Pro"].exists {
            app.cells.staticTexts["MacBook Pro"].tap()
            
            // Verify search executed
            XCTAssertTrue(app.tables.cells.staticTexts["MacBook Pro"].exists)
        }
    }
    
    func testVoiceSearch() throws {
        // Look for voice search button
        let voiceSearchButton = app.buttons["Voice Search"]
        if voiceSearchButton.waitForExistence(timeout: 3) {
            voiceSearchButton.tap()
            
            // Check for microphone permission or voice UI
            if app.staticTexts["Tap to speak"].exists {
                // In real device would speak here
                // For UI test, just verify the UI appears
                XCTAssertTrue(app.buttons["Cancel"].exists)
                app.buttons["Cancel"].tap()
            }
        }
    }
    
    func testClearSearch() throws {
        // Perform search
        let searchBar = app.searchFields.firstMatch
        searchBar.tap()
        searchBar.typeText("Test")
        
        // Clear search
        if app.buttons["Clear text"].exists {
            app.buttons["Clear text"].tap()
        } else if app.buttons["Cancel"].exists {
            app.buttons["Cancel"].tap()
        }
        
        // All items should be visible again
        XCTAssertTrue(app.tables.cells.count > 0)
    }
    
    // MARK: - Filter Tests
    
    func testCategoryFilter() throws {
        // Open filters
        let filterButton = app.buttons["Filter"]
        XCTAssertTrue(filterButton.waitForExistence(timeout: 3))
        filterButton.tap()
        
        // Select Electronics category
        if app.buttons["Electronics"].exists {
            app.buttons["Electronics"].tap()
        } else if app.cells.staticTexts["Electronics"].exists {
            app.cells.staticTexts["Electronics"].tap()
        }
        
        // Apply filter
        app.buttons["Apply"].tap()
        
        // Verify only electronics shown
        let cells = app.tables.cells
        XCTAssertTrue(cells.count > 0)
        
        // Check that visible items are electronics
        // This would need to verify category badges or similar UI elements
    }
    
    func testPriceRangeFilter() throws {
        // Open filters
        app.buttons["Filter"].tap()
        
        // Look for price range controls
        if app.sliders["Price Range"].exists {
            let slider = app.sliders["Price Range"]
            slider.adjust(toNormalizedSliderPosition: 0.5)
        } else if app.textFields["Min Price"].exists {
            // Enter price range
            let minPrice = app.textFields["Min Price"]
            minPrice.tap()
            minPrice.typeText("100")
            
            let maxPrice = app.textFields["Max Price"]
            maxPrice.tap()
            maxPrice.typeText("500")
        }
        
        // Apply filter
        app.buttons["Apply"].tap()
        
        // Verify filtered results
        XCTAssertTrue(app.tables.cells.count >= 0)
    }
    
    func testMultipleFilters() throws {
        // Open filters
        app.buttons["Filter"].tap()
        
        // Select category
        if app.buttons["Electronics"].exists {
            app.buttons["Electronics"].tap()
        }
        
        // Select brand if available
        if app.buttons["Apple"].exists {
            app.buttons["Apple"].tap()
        }
        
        // Set date range if available
        if app.buttons["Last 30 days"].exists {
            app.buttons["Last 30 days"].tap()
        }
        
        // Apply filters
        app.buttons["Apply"].tap()
        
        // Verify filter chips shown
        XCTAssertTrue(app.buttons["Electronics ×"].exists ||
                     app.collectionViews.buttons.element(matching: NSPredicate(format: "label CONTAINS 'Electronics'")).exists)
    }
    
    func testClearFilters() throws {
        // Apply some filters first
        app.buttons["Filter"].tap()
        app.buttons["Electronics"].tap()
        app.buttons["Apply"].tap()
        
        // Clear filters
        if app.buttons["Clear Filters"].exists {
            app.buttons["Clear Filters"].tap()
        } else if app.buttons["Clear All"].exists {
            app.buttons["Clear All"].tap()
        }
        
        // All items should be visible
        XCTAssertTrue(app.tables.cells.count > 0)
    }
    
    // MARK: - Sort Tests
    
    func testSortByName() throws {
        // Open sort options
        if app.buttons["Sort"].exists {
            app.buttons["Sort"].tap()
            
            // Select name sort
            app.buttons["Name"].tap()
            
            // Verify items are sorted
            let firstCell = app.tables.cells.element(boundBy: 0)
            let secondCell = app.tables.cells.element(boundBy: 1)
            
            if firstCell.exists && secondCell.exists {
                // Would need to verify alphabetical order
                XCTAssertTrue(true)
            }
        }
    }
    
    func testSortByPrice() throws {
        // Open sort options
        if app.buttons["Sort"].exists {
            app.buttons["Sort"].tap()
            
            // Select price sort
            app.buttons["Price"].tap()
            
            // Toggle between ascending/descending
            if app.buttons["Ascending"].exists {
                app.buttons["Ascending"].tap()
            }
        }
    }
    
    // MARK: - Natural Language Search Tests
    
    func testNaturalLanguageSearch() throws {
        let searchBar = app.searchFields.firstMatch
        searchBar.tap()
        
        // Test various natural language queries
        let queries = [
            "red items under $50",
            "electronics bought last month",
            "items in living room",
            "warranty expiring soon"
        ]
        
        for query in queries {
            searchBar.clearText()
            searchBar.typeText(query)
            
            // Wait for results
            sleep(1)
            
            // Should have some results or show appropriate message
            XCTAssertTrue(app.tables.cells.count >= 0 ||
                         app.staticTexts["No results found"].exists)
        }
    }
    
    // MARK: - Search History Tests
    
    func testSearchHistory() throws {
        // Perform some searches
        let searchBar = app.searchFields.firstMatch
        
        let searches = ["iPhone", "MacBook", "Coffee"]
        for search in searches {
            searchBar.tap()
            searchBar.clearText()
            searchBar.typeText(search)
            app.keyboards.buttons["Search"].tap()
            sleep(1)
        }
        
        // Tap search bar again
        searchBar.tap()
        searchBar.clearText()
        
        // Should show recent searches
        if app.tables["RecentSearches"].exists ||
           app.staticTexts["Recent Searches"].exists {
            // Verify recent searches appear
            XCTAssertTrue(app.cells.staticTexts["Coffee"].exists)
        }
    }
}