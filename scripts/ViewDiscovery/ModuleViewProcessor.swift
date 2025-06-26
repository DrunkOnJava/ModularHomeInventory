import Foundation

// Process views from module directories
struct ModuleViewProcessor {
    static func processModuleViews() -> [ViewInfo] {
        var views: [ViewInfo] = []
        let fileManager = FileManager.default
        let modulesPath = "./Modules"
        
        guard let enumerator = fileManager.enumerator(atPath: modulesPath) else {
            return views
        }
        
        while let path = enumerator.nextObject() as? String {
            // Check if it's a Swift file in a Views directory
            guard path.hasSuffix(".swift"),
                  path.contains("/Views/") || path.contains("View.swift") else {
                continue
            }
            
            // Skip if it's a ViewModel
            if path.contains("ViewModel") { continue }
            
            // Skip test files
            if path.contains("/Tests/") { continue }
            
            // Extract module name from path
            let pathComponents = path.split(separator: "/")
            guard !pathComponents.isEmpty else { continue }
            let moduleName = String(pathComponents[0])
            
            // Read the file to find view structs
            let fullPath = modulesPath + "/" + path
            guard let content = try? String(contentsOfFile: fullPath) else { continue }
            
            let extractedViews = ViewExtractor.extractViews(
                from: content,
                path: path,
                module: moduleName
            )
            views.append(contentsOf: extractedViews)
        }
        
        return views
    }
}
