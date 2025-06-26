import Foundation

// Process views from app source directories
struct AppViewProcessor {
    static func processAppViews() -> [ViewInfo] {
        var views: [ViewInfo] = []
        let fileManager = FileManager.default
        let sourcePath = "./Source"
        
        guard let enumerator = fileManager.enumerator(atPath: sourcePath) else {
            return views
        }
        
        while let path = enumerator.nextObject() as? String {
            // Check if it's a Swift file with View in the name
            guard path.hasSuffix(".swift"),
                  path.contains("View") || path.contains("/Views/") else {
                continue
            }
            
            // Skip if it's a ViewModel
            if path.contains("ViewModel") { continue }
            
            let fullPath = sourcePath + "/" + path
            
            // Read the file to find view structs
            guard let content = try? String(contentsOfFile: fullPath) else { continue }
            
            let extractedViews = ViewExtractor.extractViews(
                from: content,
                path: path,
                module: "App"
            )
            views.append(contentsOf: extractedViews)
        }
        
        return views
    }
}
