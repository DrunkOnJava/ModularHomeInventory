//
//  ScreenshotTests.swift
//  HomeInventoryModularUITests
//
//  UI Tests for automated screenshot generation of all app views
//

import XCTest

final class ScreenshotTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication(bundleIdentifier: "com.homeinventory.app")
        app.launchArguments.append("-FASTLANE_SNAPSHOT")
        app.launchArguments.append("-DisableAnimations")
        app.launchArguments.append("-MockDataEnabled")
        setupSnapshot(app)
        app.terminate()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    func testCaptureAllScreenshots() throws {
        // Wait for app to fully launch
        sleep(2)
        
        // 1. Items List (Main View)
        captureItemsList()
        
        // 2. Item Detail View
        captureItemDetail()
        
        // 3. Add Item View
        captureAddItem()
        
        // 4. Barcode Scanner
        captureBarcodeScanner()
        
        // 5. Analytics Views
        captureAnalytics()
        
        // 6. Collections
        captureCollections()
        
        // 7. Budget Dashboard
        captureBudgetDashboard()
        
        // 8. Insurance Dashboard
        captureInsuranceDashboard()
        
        // 9. Warranty Management
        captureWarrantyManagement()
        
        // 10. Search Views
        captureSearchViews()
        
        // 11. Settings
        captureSettings()
        
        // 12. Documents
        captureDocuments()
        
        // For iPad: Test split view
        if UIDevice.current.userInterfaceIdiom == .pad {
            captureIPadSpecificViews()
        }
    }
    
    // MARK: - Screenshot Capture Methods
    
    func captureItemsList() {
        snapshot("01_ItemsList")
        sleep(1)
    }
    
    func captureItemDetail() {
        // Tap on first item in list
        let firstItem = app.collectionViews.cells.firstMatch
        if firstItem.exists {
            firstItem.tap()
            sleep(1)
            snapshot("02_ItemDetail")
            
            // Navigate back
            app.navigationBars.buttons.element(boundBy: 0).tap()
            sleep(1)
        }
    }
    
    func captureAddItem() {
        // Tap add button
        let addButton = app.navigationBars.buttons["plus"]
        if addButton.exists {
            addButton.tap()
            sleep(1)
            snapshot("03_AddItem")
            
            // Cancel
            let cancelButton = app.navigationBars.buttons["Cancel"]
            if cancelButton.exists {
                cancelButton.tap()
                sleep(1)
            }
        }
    }
    
    func captureBarcodeScanner() {
        // Navigate to Scanner tab
        let scannerTab = app.tabBars.buttons["Scanner"]
        if scannerTab.exists {
            scannerTab.tap()
            sleep(1)
            snapshot("04_BarcodeScanner")
        }
    }
    
    func captureAnalytics() {
        // Navigate to Analytics tab
        let analyticsTab = app.tabBars.buttons["Analytics"]
        if analyticsTab.exists {
            analyticsTab.tap()
            sleep(1)
            snapshot("05_AnalyticsDashboard")
            
            // Capture sub-views
            let spendingButton = app.buttons["Spending Dashboard"]
            if spendingButton.exists {
                spendingButton.tap()
                sleep(1)
                snapshot("06_SpendingDashboard")
                app.navigationBars.buttons.element(boundBy: 0).tap()
            }
            
            let patternsButton = app.buttons["Purchase Patterns"]
            if patternsButton.exists {
                patternsButton.tap()
                sleep(1)
                snapshot("07_PurchasePatterns")
                app.navigationBars.buttons.element(boundBy: 0).tap()
            }
            
            let depreciationButton = app.buttons["Depreciation Report"]
            if depreciationButton.exists {
                depreciationButton.tap()
                sleep(1)
                snapshot("08_DepreciationReport")
                app.navigationBars.buttons.element(boundBy: 0).tap()
            }
        }
    }
    
    func captureCollections() {
        // Navigate to Collections
        let collectionsTab = app.tabBars.buttons["Collections"]
        if collectionsTab.exists {
            collectionsTab.tap()
            sleep(1)
            snapshot("09_Collections")
            
            // Tap on a collection if available
            let firstCollection = app.collectionViews.cells.firstMatch
            if firstCollection.exists {
                firstCollection.tap()
                sleep(1)
                snapshot("10_CollectionDetail")
                app.navigationBars.buttons.element(boundBy: 0).tap()
            }
        }
    }
    
    func captureBudgetDashboard() {
        // Navigate to Items tab first
        app.tabBars.buttons["Items"].tap()
        sleep(1)
        
        // Look for Budget button in toolbar or navigation
        let budgetButton = app.buttons["Budget"]
        if budgetButton.exists {
            budgetButton.tap()
            sleep(1)
            snapshot("11_BudgetDashboard")
            
            // Add Budget
            let addBudgetButton = app.navigationBars.buttons["plus"]
            if addBudgetButton.exists {
                addBudgetButton.tap()
                sleep(1)
                snapshot("12_AddBudget")
                app.navigationBars.buttons["Cancel"].tap()
            }
            
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
    }
    
    func captureInsuranceDashboard() {
        // Navigate to Insurance tab
        let insuranceTab = app.tabBars.buttons["Insurance"]
        if insuranceTab.exists {
            insuranceTab.tap()
            sleep(1)
            snapshot("13_InsuranceDashboard")
            
            // Claim Assistance
            let claimButton = app.buttons["File Claim"]
            if claimButton.exists {
                claimButton.tap()
                sleep(1)
                snapshot("14_ClaimAssistance")
                app.navigationBars.buttons.element(boundBy: 0).tap()
            }
        }
    }
    
    func captureWarrantyManagement() {
        // Navigate through Items to Warranty
        app.tabBars.buttons["Items"].tap()
        sleep(1)
        
        let warrantyButton = app.buttons["Warranties"]
        if warrantyButton.exists {
            warrantyButton.tap()
            sleep(1)
            snapshot("15_WarrantyList")
            
            // Warranty detail
            let firstWarranty = app.tables.cells.firstMatch
            if firstWarranty.exists {
                firstWarranty.tap()
                sleep(1)
                snapshot("16_WarrantyDetail")
                app.navigationBars.buttons.element(boundBy: 0).tap()
            }
            
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
    }
    
    func captureSearchViews() {
        // Go to Items tab
        app.tabBars.buttons["Items"].tap()
        sleep(1)
        
        // Tap search field
        let searchField = app.searchFields.firstMatch
        if searchField.exists {
            searchField.tap()
            sleep(1)
            snapshot("17_SearchView")
            
            // Type search query
            searchField.typeText("Electronics")
            sleep(1)
            snapshot("18_SearchResults")
            
            // Clear search
            app.buttons["Cancel"].tap()
            sleep(1)
        }
    }
    
    func captureSettings() {
        // Navigate to Settings tab
        let settingsTab = app.tabBars.buttons["Settings"]
        if settingsTab.exists {
            settingsTab.tap()
            sleep(1)
            snapshot("19_Settings")
            
            // Category Management
            let categoryCell = app.tables.cells["Category Management"]
            if categoryCell.exists {
                categoryCell.tap()
                sleep(1)
                snapshot("20_CategoryManagement")
                app.navigationBars.buttons.element(boundBy: 0).tap()
            }
            
            // Export Data
            let exportCell = app.tables.cells["Export Data"]
            if exportCell.exists {
                exportCell.tap()
                sleep(1)
                snapshot("21_ExportData")
                app.navigationBars.buttons.element(boundBy: 0).tap()
            }
        }
    }
    
    func captureDocuments() {
        // Navigate to Items tab
        app.tabBars.buttons["Items"].tap()
        sleep(1)
        
        // Look for Documents button
        let documentsButton = app.buttons["Documents"]
        if documentsButton.exists {
            documentsButton.tap()
            sleep(1)
            snapshot("22_DocumentsDashboard")
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
    }
    
    func captureIPadSpecificViews() {
        // iPad split view
        app.tabBars.buttons["Items"].tap()
        sleep(1)
        
        // Force landscape for split view
        XCUIDevice.shared.orientation = .landscapeLeft
        sleep(2)
        snapshot("23_iPad_SplitView")
        
        // Multi-column view
        let firstItem = app.collectionViews.cells.firstMatch
        if firstItem.exists {
            firstItem.tap()
            sleep(1)
            snapshot("24_iPad_DetailView")
        }
        
        // Context menu
        if let cell = app.collectionViews.cells.element(boundBy: 1).exists ? app.collectionViews.cells.element(boundBy: 1) : nil {
            cell?.press(forDuration: 1.0)
            sleep(1)
            snapshot("25_iPad_ContextMenu")
            
            // Dismiss context menu
            app.tap()
        }
        
        // Return to portrait
        XCUIDevice.shared.orientation = .portrait
        sleep(1)
    }
}

// MARK: - Helper Extensions

extension XCUIElement {
    func clearAndTypeText(_ text: String) {
        guard let stringValue = self.value as? String else {
            XCTFail("Tried to clear and type text into a non string value")
            return
        }
        
        self.tap()
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
        self.typeText(text)
    }
}