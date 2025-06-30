import Danger
import Foundation

let danger = Danger()

// MARK: - Configuration
let bigPRThreshold = 600
let testableFilesExtensions = ["swift", "m", "mm"]

// MARK: - PR Size Check
let additions = danger.github.pullRequest.additions ?? 0
let deletions = danger.github.pullRequest.deletions ?? 0
let totalChanges = additions + deletions

if totalChanges > bigPRThreshold {
    warn("This PR is quite large (\(totalChanges) lines changed). Consider breaking it up into smaller PRs for easier review.")
}

// MARK: - Modified Files Analysis
let modifiedFiles = danger.git.modifiedFiles + danger.git.createdFiles
let deletedFiles = danger.git.deletedFiles

// Check for test coverage
let hasSourceChanges = modifiedFiles.contains { file in
    testableFilesExtensions.contains { file.hasSuffix(".\($0)") } &&
    !file.contains("Tests/") &&
    !file.contains("UITests/")
}

let hasTestChanges = modifiedFiles.contains { file in
    file.contains("Tests/") && file.hasSuffix(".swift")
}

if hasSourceChanges && !hasTestChanges {
    warn("You've made changes to source files but haven't updated any tests. Please consider adding or updating tests.")
}

// MARK: - SwiftLint
SwiftLint.lint(.modifiedAndCreatedFiles(directory: nil),
               inline: true,
               configFile: ".swiftlint.yml",
               strict: false)

// MARK: - PR Description
let prBody = danger.github.pullRequest.body ?? ""
if prBody.count < 10 {
    fail("Please provide a meaningful PR description.")
}

// Check for PR template sections
let requiredSections = ["## Description", "## Type of Change", "## Testing"]
let missingSections = requiredSections.filter { !prBody.contains($0) }
if !missingSections.isEmpty {
    warn("PR description is missing the following sections: \(missingSections.joined(separator: ", "))")
}

// MARK: - File Specific Checks

// Check for large files
for file in modifiedFiles {
    if let fileURL = URL(string: file),
       let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
       let fileSize = attributes[.size] as? Int,
       fileSize > 1_000_000 { // 1MB
        warn("File \(file) is quite large (\(fileSize / 1024)KB). Consider if it should be added to the repository.")
    }
}

// Check for TODO/FIXME comments
for file in modifiedFiles where file.hasSuffix(".swift") {
    let fileURL = URL(fileURLWithPath: file)
    if let content = try? String(contentsOf: fileURL) {
        let lines = content.components(separatedBy: .newlines)
        for (index, line) in lines.enumerated() {
            if line.contains("TODO:") || line.contains("FIXME:") {
                warn("Found TODO/FIXME in \(file):\(index + 1) - \(line.trimmingCharacters(in: .whitespaces))")
            }
        }
    }
}

// MARK: - Dependencies Check
if modifiedFiles.contains("Package.swift") || 
   modifiedFiles.contains("Podfile") || 
   modifiedFiles.contains("Cartfile") {
    message("Dependencies have been modified. Please ensure you've tested the changes thoroughly.")
}

// MARK: - Project File Changes
if modifiedFiles.contains { $0.hasSuffix(".xcodeproj/project.pbxproj") } {
    warn("Xcode project file has been modified. Please ensure it was intentional and consider using XcodeGen instead.")
}

// MARK: - Security Checks
let sensitivePatterns = [
    "password",
    "api_key",
    "apiKey",
    "secret",
    "token",
    "private_key"
]

for file in modifiedFiles where file.hasSuffix(".swift") {
    let fileURL = URL(fileURLWithPath: file)
    if let content = try? String(contentsOf: fileURL) {
        for pattern in sensitivePatterns {
            if content.lowercased().contains(pattern) && !file.contains("Tests/") {
                warn("Potential sensitive information found in \(file). Please ensure no secrets are hardcoded.")
                break
            }
        }
    }
}

// MARK: - Encouragement
if danger.github.pullRequest.additions ?? 0 < 10 {
    message("Small PR - love it! 🎉")
} else if hasTestChanges {
    message("Thanks for updating tests! 🧪")
}

// MARK: - Final Messages
let errorCount = danger.fails.count
let warningCount = danger.warnings.count

if errorCount == 0 && warningCount == 0 {
    message("Great job! This PR is looking good! 👍")
}