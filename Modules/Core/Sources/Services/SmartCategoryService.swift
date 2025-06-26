//
//  SmartCategoryService.swift
//  HomeInventoryModular
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
//  Module: Core
//  Dependencies: Foundation, NaturalLanguage
//  Testing: Smart categorization with machine learning
//
//  Description: Smart category service for AI-powered automatic categorization using
//  Natural Language framework for semantic analysis and item classification.
//  Provides confidence scoring and category suggestions.
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation
import NaturalLanguage

/// Smart category service for AI-powered automatic categorization
/// Swift 5.9 - No Swift 6 features
public final class SmartCategoryService {
    
    // Singleton instance
    public static let shared = SmartCategoryService()
    
    // Category keywords mapping
    private let categoryKeywords: [ItemCategory: Set<String>] = [
        .electronics: Set([
            "phone", "laptop", "computer", "tablet", "ipad", "iphone", "macbook", "watch",
            "tv", "television", "monitor", "screen", "speaker", "headphone", "earphone",
            "camera", "console", "playstation", "xbox", "nintendo", "gaming", "keyboard",
            "mouse", "printer", "scanner", "router", "modem", "hard drive", "ssd",
            "battery", "charger", "cable", "adapter", "microphone", "webcam", "drone",
            "smart", "alexa", "google home", "echo", "kindle", "ereader"
        ]),
        
        .furniture: Set([
            "chair", "table", "desk", "sofa", "couch", "bed", "mattress", "dresser",
            "cabinet", "shelf", "bookcase", "wardrobe", "closet", "ottoman", "bench",
            "stool", "nightstand", "drawer", "armchair", "recliner", "loveseat",
            "dining", "office", "patio", "outdoor", "garden", "deck"
        ]),
        
        .appliances: Set([
            "refrigerator", "fridge", "freezer", "washer", "dryer", "dishwasher",
            "microwave", "oven", "stove", "range", "cooktop", "blender", "mixer",
            "toaster", "coffee", "espresso", "vacuum", "cleaner", "iron", "fan",
            "heater", "air conditioner", "ac", "dehumidifier", "humidifier",
            "water heater", "garbage disposal"
        ]),
        
        .clothing: Set([
            "shirt", "pants", "jeans", "dress", "skirt", "jacket", "coat", "sweater",
            "hoodie", "shoes", "boots", "sneakers", "sandals", "hat", "cap", "gloves",
            "scarf", "tie", "belt", "socks", "underwear", "pajamas", "suit", "blazer",
            "shorts", "swimsuit", "bikini", "trunks", "vest", "cardigan", "polo"
        ]),
        
        .tools: Set([
            "hammer", "screwdriver", "drill", "saw", "wrench", "pliers", "level",
            "tape measure", "ruler", "ladder", "toolbox", "socket", "ratchet",
            "sander", "grinder", "welder", "torch", "clamp", "vise", "chisel",
            "file", "rasp", "plane", "router", "jigsaw", "circular saw", "miter"
        ]),
        
        .kitchen: Set([
            "pot", "pan", "skillet", "knife", "fork", "spoon", "plate", "bowl",
            "cup", "mug", "glass", "cutting board", "spatula", "whisk", "ladle",
            "tongs", "peeler", "grater", "colander", "strainer", "measuring",
            "baking", "mixer", "food processor", "instant pot", "crock pot",
            "pressure cooker", "air fryer"
        ]),
        
        .sports: Set([
            "ball", "bat", "racket", "club", "golf", "tennis", "basketball",
            "football", "soccer", "baseball", "hockey", "ski", "snowboard",
            "bike", "bicycle", "helmet", "glove", "mitt", "net", "goal",
            "weights", "dumbbell", "barbell", "treadmill", "elliptical",
            "yoga", "mat", "resistance", "band"
        ]),
        
        .toys: Set([
            "lego", "doll", "action figure", "puzzle", "board game", "card game",
            "toy", "playset", "blocks", "stuffed", "plush", "teddy", "bear",
            "train", "car", "truck", "plane", "boat", "robot", "dinosaur",
            "barbie", "nerf", "hot wheels", "pokemon", "transformers"
        ]),
        
        .books: Set([
            "book", "novel", "textbook", "manual", "guide", "dictionary",
            "encyclopedia", "magazine", "comic", "manga", "newspaper",
            "journal", "diary", "notebook", "paperback", "hardcover",
            "ebook", "audiobook", "kindle", "nook"
        ]),
        
        .jewelry: Set([
            "ring", "necklace", "bracelet", "earring", "pendant", "chain",
            "watch", "brooch", "pin", "cufflink", "anklet", "charm",
            "gold", "silver", "diamond", "pearl", "gemstone", "crystal"
        ]),
        
        .collectibles: Set([
            "coin", "stamp", "card", "trading", "vintage", "antique",
            "memorabilia", "autograph", "signed", "limited edition",
            "collectible", "rare", "mint", "graded", "certified"
        ])
    ]
    
    // Brand to category mapping
    private let brandCategories: [String: ItemCategory] = [
        // Electronics brands
        "apple": .electronics,
        "samsung": .electronics,
        "sony": .electronics,
        "lg": .electronics,
        "microsoft": .electronics,
        "dell": .electronics,
        "hp": .electronics,
        "lenovo": .electronics,
        "asus": .electronics,
        "acer": .electronics,
        "google": .electronics,
        "amazon": .electronics,
        "bose": .electronics,
        "jbl": .electronics,
        "beats": .electronics,
        "canon": .electronics,
        "nikon": .electronics,
        "gopro": .electronics,
        
        // Furniture brands
        "ikea": .furniture,
        "ashley": .furniture,
        "wayfair": .furniture,
        "west elm": .furniture,
        "pottery barn": .furniture,
        "restoration hardware": .furniture,
        "herman miller": .furniture,
        
        // Appliance brands
        "whirlpool": .appliances,
        "ge": .appliances,
        "kitchenaid": .appliances,
        "maytag": .appliances,
        "bosch": .appliances,
        "frigidaire": .appliances,
        "dyson": .appliances,
        "cuisinart": .appliances,
        "ninja": .appliances,
        "vitamix": .appliances,
        
        // Sports brands
        "nike": .sports,
        "adidas": .sports,
        "under armour": .sports,
        "reebok": .sports,
        "puma": .sports,
        "wilson": .sports,
        "spalding": .sports,
        "titleist": .sports,
        "callaway": .sports,
        
        // Tool brands
        "dewalt": .tools,
        "milwaukee": .tools,
        "makita": .tools,
        "bosch tools": .tools,  // Changed to avoid duplicate with appliances
        "craftsman": .tools,
        "stanley": .tools,
        "black & decker": .tools,
        "ryobi": .tools,
        
        // Toy brands
        "lego": .toys,
        "mattel": .toys,
        "hasbro": .toys,
        "fisher-price": .toys,
        "nerf": .toys,
        "hot wheels": .toys
    ]
    
    private init() {}
    
    /// Suggests a category for an item based on its properties
    public func suggestCategory(
        name: String,
        brand: String? = nil,
        model: String? = nil,
        description: String? = nil
    ) -> (category: ItemCategory, confidence: Double) {
        
        var scores: [ItemCategory: Double] = [:]
        
        // Combine all text for analysis
        let fullText = [name, brand, model, description]
            .compactMap { $0 }
            .joined(separator: " ")
            .lowercased()
        
        // Check brand first (highest confidence)
        if let brand = brand?.lowercased(),
           let brandCategory = brandCategories[brand] {
            scores[brandCategory, default: 0] += 0.8
        }
        
        // Analyze keywords
        let words = fullText.components(separatedBy: .whitespacesAndNewlines)
            .flatMap { $0.components(separatedBy: .punctuationCharacters) }
            .filter { !$0.isEmpty }
        
        for (category, keywords) in categoryKeywords {
            var categoryScore = 0.0
            var matchCount = 0
            
            for word in words {
                if keywords.contains(word) {
                    matchCount += 1
                    categoryScore += 0.3
                }
                
                // Check for partial matches
                for keyword in keywords {
                    if word.contains(keyword) || keyword.contains(word) {
                        categoryScore += 0.1
                        break
                    }
                }
            }
            
            // Bonus for multiple matches
            if matchCount > 1 {
                categoryScore *= Double(matchCount) * 0.5
            }
            
            scores[category, default: 0] += categoryScore
        }
        
        // Use NaturalLanguage framework for additional analysis
        if #available(iOS 12.0, *) {
            let tagger = NLTagger(tagSchemes: [.lexicalClass])
            tagger.string = fullText
            
            let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]
            tagger.enumerateTags(in: fullText.startIndex..<fullText.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, range in
                if let tag = tag {
                    // Boost scores based on word types
                    let word = String(fullText[range]).lowercased()
                    
                    switch tag {
                    case .noun:
                        // Nouns are most important for categorization
                        for (category, keywords) in categoryKeywords {
                            if keywords.contains(word) {
                                scores[category, default: 0] += 0.2
                            }
                        }
                    case .adjective:
                        // Adjectives can provide hints
                        if word.contains("electronic") || word.contains("digital") {
                            scores[.electronics, default: 0] += 0.1
                        } else if word.contains("wooden") || word.contains("metal") {
                            scores[.furniture, default: 0] += 0.1
                        }
                    default:
                        break
                    }
                }
                return true
            }
        }
        
        // Find the category with the highest score
        if let (topCategory, topScore) = scores.max(by: { $0.value < $1.value }),
           topScore > 0 {
            // Calculate confidence (0-1 scale)
            let confidence = min(topScore / 2.0, 1.0)
            return (topCategory, confidence)
        }
        
        // Default to "other" with low confidence
        return (.other, 0.1)
    }
    
    /// Suggests multiple categories ranked by confidence
    public func suggestCategories(
        name: String,
        brand: String? = nil,
        model: String? = nil,
        description: String? = nil,
        limit: Int = 3
    ) -> [(category: ItemCategory, confidence: Double)] {
        
        var scores: [ItemCategory: Double] = [:]
        
        // Use the same scoring logic as suggestCategory
        let fullText = [name, brand, model, description]
            .compactMap { $0 }
            .joined(separator: " ")
            .lowercased()
        
        // Brand matching
        if let brand = brand?.lowercased(),
           let brandCategory = brandCategories[brand] {
            scores[brandCategory, default: 0] += 0.8
        }
        
        // Keyword matching
        let words = fullText.components(separatedBy: .whitespacesAndNewlines)
            .flatMap { $0.components(separatedBy: .punctuationCharacters) }
            .filter { !$0.isEmpty }
        
        for (category, keywords) in categoryKeywords {
            var categoryScore = 0.0
            var matchCount = 0
            
            for word in words {
                if keywords.contains(word) {
                    matchCount += 1
                    categoryScore += 0.3
                }
                
                for keyword in keywords {
                    if word.contains(keyword) || keyword.contains(word) {
                        categoryScore += 0.1
                        break
                    }
                }
            }
            
            if matchCount > 1 {
                categoryScore *= Double(matchCount) * 0.5
            }
            
            if categoryScore > 0 {
                scores[category, default: 0] += categoryScore
            }
        }
        
        // Sort by score and return top results
        return scores
            .map { (category: $0.key, confidence: min($0.value / 2.0, 1.0)) }
            .sorted { $0.confidence > $1.confidence }
            .prefix(limit)
            .map { $0 }
    }
    
    /// Learns from user corrections to improve future predictions
    public func learnFromCorrection(
        name: String,
        brand: String?,
        correctCategory: ItemCategory
    ) {
        // In a real implementation, this would update a machine learning model
        // or store corrections in a database for future reference
        // For now, we'll just log it
        print("Learning: '\(name)' from '\(brand ?? "unknown")' should be categorized as '\(correctCategory.displayName)'")
    }
}