import XCTest

/// Base class for performance testing with enhanced metrics and async support
open class PerformanceTestCase: XCTestCase {
    
    /// Default metrics to measure in performance tests
    open var defaultMetrics: [XCTMetric] {
        return [
            XCTClockMetric(),
            XCTMemoryMetric(),
            XCTStorageMetric(),
            XCTCPUMetric()
        ]
    }
    
    /// Performance baselines for comparison
    open var performanceBaselines: [String: Double] {
        return [:]
    }
    
    /// Measure async operations with automatic metric collection
    public func measureAsync<T>(
        timeout: TimeInterval = 60,
        metrics: [XCTMetric]? = nil,
        options: XCTMeasureOptions = XCTMeasureOptions(),
        block: @escaping () async throws -> T
    ) async throws {
        let metricsToUse = metrics ?? defaultMetrics
        
        measure(metrics: metricsToUse, options: options) {
            let expectation = self.expectation(description: "Async measurement")
            
            Task {
                do {
                    _ = try await block()
                    expectation.fulfill()
                } catch {
                    XCTFail("Async operation failed: \(error)")
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: timeout)
        }
    }
    
    /// Measure with automatic baseline comparison
    public func measureWithBaseline(
        name: String,
        tolerance: Double = 0.1, // 10% tolerance
        metrics: [XCTMetric]? = nil,
        block: () throws -> Void
    ) rethrows {
        let metricsToUse = metrics ?? defaultMetrics
        
        let options = XCTMeasureOptions()
        options.invocationOptions = [.manuallyStart, .manuallyStop]
        
        var measurements: [Double] = []
        
        measure(metrics: metricsToUse, options: options) {
            startMeasuring()
            let startTime = CFAbsoluteTimeGetCurrent()
            
            do {
                try block()
            } catch {
                XCTFail("Operation failed: \(error)")
            }
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let duration = endTime - startTime
            measurements.append(duration)
            
            stopMeasuring()
        }
        
        // Compare with baseline if available
        if let baseline = performanceBaselines[name],
           let avgMeasurement = measurements.average() {
            let percentChange = (avgMeasurement - baseline) / baseline
            
            XCTAssertLessThan(
                percentChange,
                tolerance,
                "\(name) performance regressed by \(percentChange * 100)% (baseline: \(baseline)s, measured: \(avgMeasurement)s)"
            )
        }
    }
    
    /// Helper to get memory usage
    public func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
    
    /// Helper to format memory size
    public func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Array Extension for Statistics

extension Array where Element == Double {
    func average() -> Double? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Double(count)
    }
    
    func standardDeviation() -> Double? {
        guard let avg = average() else { return nil }
        let variance = reduce(0) { $0 + pow($1 - avg, 2) } / Double(count)
        return sqrt(variance)
    }
}