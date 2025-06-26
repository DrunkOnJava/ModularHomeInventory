#!/usr/bin/env swift
//
//  discover_views.swift
//  Development Scripts - View Discovery
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
//  Execute: swift scripts/discover_views.swift
//
//  Project Structure:
//  Main Target: HomeInventoryModular
//  Test Targets: HomeInventoryModularTests, HomeInventoryModularUITests
//  Swift Version: 5.9 (DO NOT upgrade to Swift 6)
//  Minimum iOS Version: 17.0
//
//  Architecture: Modular SPM packages with local package dependencies
//  Repository: https://github.com/DrunkOnJava/ModularHomeInventory.git
//  Module: Development Scripts
//  Dependencies: Foundation
//  Testing: Manual execution and validation
//
//  Description: Main view discovery script for the modular Home Inventory project.
//               Scans all modules and app source to identify SwiftUI views, analyze
//               navigation patterns, and generate comprehensive documentation.
//
//  Created by Griffin Long on June 26, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation

// Include the modular components
#if swift(>=5.5)
#sourceLocation(file: "ViewDiscovery/ViewInfo.swift", line: 1)
#endif

// Script to discover all views in the modular project
// This script has been modularized to reduce complexity

// Note: In a real Swift script, we would need to compile these files together
// For now, we'll include the core logic inline

struct ViewInfo {
    let name: String
    let path: String
    let module: String
}

struct ViewDiscoverer {
    static func run() {
        print("🚀 Starting view discovery...\n")
        
        // Collect all views
        var views: [ViewInfo] = []
        views.append(contentsOf: processModuleViews())
        views.append(contentsOf: processAppViews())
        
        // Sort views by module and name
        views.sort { 
            if $0.module == $1.module {
                return $0.name < $1.name
            }
            return $0.module < $1.module
        }
        
        // Report results
        reportViews(views)
        
        // Analyze navigation patterns
        analyzeNavigationPatterns()
    }
    
    private static func extractViews(from content: String, path: String, module: String) -> [ViewInfo] {
        var views: [ViewInfo] = []
        let viewPattern = #"(?:public\s+)?struct\s+(\w+):\s*View\s*\{"#
        
        guard let regex = try? NSRegularExpression(pattern: viewPattern, options: []) else {
            return views
        }
        
        let range = NSRange(content.startIndex..., in: content)
        let matches = regex.matches(in: content, options: [], range: range)
        
        for match in matches {
            if let range = Range(match.range(at: 1), in: content) {
                let viewName = String(content[range])
                views.append(ViewInfo(name: viewName, path: path, module: module))
            }
        }
        
        return views
    }
    
    private static func processModuleViews() -> [ViewInfo] {
        var views: [ViewInfo] = []
        let fileManager = FileManager.default
        let modulesPath = "./Modules"
        
        guard let enumerator = fileManager.enumerator(atPath: modulesPath) else {
            return views
        }
        
        while let path = enumerator.nextObject() as? String {
            guard shouldProcessFile(path: path) else { continue }
            
            let pathComponents = path.split(separator: "/")
            guard !pathComponents.isEmpty else { continue }
            let moduleName = String(pathComponents[0])
            
            let fullPath = modulesPath + "/" + path
            guard let content = try? String(contentsOfFile: fullPath) else { continue }
            
            views.append(contentsOf: extractViews(from: content, path: path, module: moduleName))
        }
        
        return views
    }
    
    private static func processAppViews() -> [ViewInfo] {
        var views: [ViewInfo] = []
        let fileManager = FileManager.default
        let sourcePath = "./Source"
        
        guard let enumerator = fileManager.enumerator(atPath: sourcePath) else {
            return views
        }
        
        while let path = enumerator.nextObject() as? String {
            guard shouldProcessAppFile(path: path) else { continue }
            
            let fullPath = sourcePath + "/" + path
            guard let content = try? String(contentsOfFile: fullPath) else { continue }
            
            views.append(contentsOf: extractViews(from: content, path: path, module: "App"))
        }
        
        return views
    }
    
    private static func shouldProcessFile(path: String) -> Bool {
        guard path.hasSuffix(".swift") else { return false }
        guard path.contains("/Views/") || path.contains("View.swift") else { return false }
        guard !path.contains("ViewModel") else { return false }
        guard !path.contains("/Tests/") else { return false }
        return true
    }
    
    private static func shouldProcessAppFile(path: String) -> Bool {
        guard path.hasSuffix(".swift") else { return false }
        guard path.contains("View") || path.contains("/Views/") else { return false }
        guard !path.contains("ViewModel") else { return false }
        return true
    }
    
    private static func reportViews(_ views: [ViewInfo]) {
        print("🔍 Discovered \(views.count) views:\n")
        
        var currentModule = ""
        for view in views {
            if view.module != currentModule {
                currentModule = view.module
                print("\n📦 \(currentModule)")
                print(String(repeating: "-", count: currentModule.count + 3))
            }
            print("  • \(view.name)")
            print("    📍 \(view.path)")
        }
        
        generateAndSaveJSON(views)
    }
    
    private static func generateAndSaveJSON(_ views: [ViewInfo]) {
        var jsonOutput: [String: [[String: String]]] = [:]
        
        for view in views {
            if jsonOutput[view.module] == nil {
                jsonOutput[view.module] = []
            }
            jsonOutput[view.module]?.append([
                "name": view.name,
                "path": view.path
            ])
        }
        
        print("\n📊 Module Summary:")
        for (module, moduleViews) in jsonOutput.sorted(by: { $0.key < $1.key }) {
            print("  • \(module): \(moduleViews.count) views")
        }
        
        saveJSON(jsonOutput)
    }
    
    private static func saveJSON(_ jsonOutput: [String: [[String: String]]]) {
        guard let jsonData = try? JSONSerialization.data(
            withJSONObject: jsonOutput,
            options: .prettyPrinted
        ) else { return }
        
        guard let jsonString = String(data: jsonData, encoding: .utf8) else { return }
        
        let jsonPath = "scripts/discovered_views.json"
        try? jsonString.write(toFile: jsonPath, atomically: true, encoding: .utf8)
        print("\n💾 View discovery results saved to: \(jsonPath)")
    }
    
    private static func analyzeNavigationPatterns() {
        print("\n🧭 Analyzing Navigation Patterns...\n")
        
        let navigationKeywords = [
            "NavigationLink", "NavigationStack", "NavigationView",
            ".sheet", ".fullScreenCover", ".popover",
            "coordinator.show", "coordinator.push"
        ]
        
        var navigationUsage: [String: Int] = [:]
        
        processNavigationInPath("./Modules", keywords: navigationKeywords, usage: &navigationUsage)
        processNavigationInPath("./Source", keywords: navigationKeywords, usage: &navigationUsage)
        
        print("📈 Navigation Pattern Usage:")
        for (pattern, count) in navigationUsage.sorted(by: { $0.value > $1.value }) {
            print("  • \(pattern): \(count) occurrences")
        }
    }
    
    private static func processNavigationInPath(
        _ basePath: String,
        keywords: [String],
        usage: inout [String: Int]
    ) {
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(atPath: basePath) else { return }
        
        while let path = enumerator.nextObject() as? String {
            guard path.hasSuffix(".swift") else { continue }
            
            let fullPath = basePath + "/" + path
            guard let content = try? String(contentsOfFile: fullPath) else { continue }
            
            for keyword in keywords {
                let count = content.components(separatedBy: keyword).count - 1
                if count > 0 {
                    usage[keyword, default: 0] += count
                }
            }
        }
    }
}

// Run the discovery
ViewDiscoverer.run()
