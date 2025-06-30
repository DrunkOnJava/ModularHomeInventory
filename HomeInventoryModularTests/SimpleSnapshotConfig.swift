import Foundation
import SnapshotTesting

// Simple snapshot configuration
class SimpleSnapshotConfig {
    static func setup() {
        // Set recording mode based on environment
        if ProcessInfo.processInfo.environment["RECORD_SNAPSHOTS"] == "true" {
            isRecording = false
        }
    }
}