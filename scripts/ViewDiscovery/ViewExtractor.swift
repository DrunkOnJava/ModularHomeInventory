import Foundation

// Extract views from Swift source files
struct ViewExtractor {
    static func extractViews(from content: String, path: String, module: String) -> [ViewInfo] {
        var views: [ViewInfo] = []
        let viewPattern = #"(?:public\s+)?struct\s+(\w+):\s*View\s*\{"#
        
        guard let regex = try? NSRegularExpression(pattern: viewPattern, options: []) else {
            return views
        }
        
        let matches = regex.matches(
            in: content,
            options: [],
            range: NSRange(content.startIndex..., in: content)
        )
        
        for match in matches {
            if let range = Range(match.range(at: 1), in: content) {
                let viewName = String(content[range])
                views.append(ViewInfo(name: viewName, path: path, module: module))
            }
        }
        
        return views
    }
}
