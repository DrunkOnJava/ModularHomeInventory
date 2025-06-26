import Foundation

// Report and output view discovery results
struct ViewReporter {
    static func reportViews(_ views: [ViewInfo]) {
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
        
        // Generate JSON output
        let jsonOutput = generateJSON(from: views)
        
        // Print JSON summary
        print("\n📊 Module Summary:")
        for (module, moduleViews) in jsonOutput.sorted(by: { $0.key < $1.key }) {
            print("  • \(module): \(moduleViews.count) views")
        }
        
        // Save JSON to file
        saveJSON(jsonOutput)
    }
    
    private static func generateJSON(from views: [ViewInfo]) -> [String: [[String: String]]] {
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
        
        return jsonOutput
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
}
