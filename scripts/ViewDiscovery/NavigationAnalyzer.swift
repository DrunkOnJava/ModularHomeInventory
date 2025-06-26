import Foundation

// Analyze navigation patterns in the codebase
struct NavigationAnalyzer {
    static func analyzeNavigationPatterns() {
        print("\n🧭 Analyzing Navigation Patterns...\n")
        
        let navigationKeywords = [
            "NavigationLink",
            "NavigationStack",
            "NavigationView",
            ".sheet",
            ".fullScreenCover",
            ".popover",
            "coordinator.show",
            "coordinator.push"
        ]
        
        var navigationUsage: [String: Int] = [:]
        
        let fileManager = FileManager.default
        let paths = ["./Modules", "./Source"]
        
        for basePath in paths {
            processPath(
                basePath: basePath,
                keywords: navigationKeywords,
                usage: &navigationUsage
            )
        }
        
        print("📈 Navigation Pattern Usage:")
        for (pattern, count) in navigationUsage.sorted(by: { $0.value > $1.value }) {
            print("  • \(pattern): \(count) occurrences")
        }
    }
    
    private static func processPath(
        basePath: String,
        keywords: [String],
        usage: inout [String: Int]
    ) {
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(atPath: basePath) else {
            return
        }
        
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
