import XCTest

public extension XCTestCase {
    
    /// Execute an async test with proper setup and teardown
    func asyncTest(
        timeout: TimeInterval = 10,
        function: String = #function,
        _ block: @escaping () async throws -> Void
    ) {
        let expectation = expectation(description: function)
        
        Task {
            do {
                try await block()
                expectation.fulfill()
            } catch {
                XCTFail("Async test failed: \(error)", file: #file, line: #line)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: timeout)
    }
    
    /// Wait for an async condition to be true
    func waitForAsync(
        timeout: TimeInterval = 10,
        pollingInterval: TimeInterval = 0.1,
        file: StaticString = #file,
        line: UInt = #line,
        condition: @escaping () async -> Bool
    ) async {
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < timeout {
            if await condition() {
                return
            }
            
            do {
                try await Task.sleep(nanoseconds: UInt64(pollingInterval * 1_000_000_000))
            } catch {
                XCTFail("Sleep interrupted: \(error)", file: file, line: line)
                return
            }
        }
        
        XCTFail("Condition not met within \(timeout) seconds", file: file, line: line)
    }
    
    /// Assert async throwing expression throws specific error
    func assertAsyncThrows<T, E: Error & Equatable>(
        _ expression: @autoclosure () async throws -> T,
        throws error: E,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        do {
            _ = try await expression()
            XCTFail("Expected error \(error) but no error was thrown", file: file, line: line)
        } catch let thrownError as E {
            XCTAssertEqual(thrownError, error, file: file, line: line)
        } catch {
            XCTFail("Expected error \(E.self) but got \(type(of: error)): \(error)", file: file, line: line)
        }
    }
    
    /// Assert async expression doesn't throw
    func assertAsyncNoThrow<T>(
        _ expression: @autoclosure () async throws -> T,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        do {
            _ = try await expression()
        } catch {
            XCTFail("Unexpected error: \(error)", file: file, line: line)
        }
    }
    
    /// Retry an async operation until it succeeds or times out
    func retryAsync<T>(
        maxAttempts: Int = 3,
        delay: TimeInterval = 1.0,
        file: StaticString = #file,
        line: UInt = #line,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                if attempt < maxAttempts {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        XCTFail("Operation failed after \(maxAttempts) attempts", file: file, line: line)
        throw lastError ?? NSError(domain: "TestError", code: -1)
    }
}

// MARK: - Async Test Observer

/// Observer for tracking async test execution
public class AsyncTestObserver: NSObject, XCTestObservation {
    
    private var runningTests: Set<String> = []
    private let queue = DispatchQueue(label: "async.test.observer")
    
    public func testCaseWillStart(_ testCase: XCTestCase) {
        queue.sync {
            runningTests.insert(testCase.name)
        }
    }
    
    public func testCaseDidFinish(_ testCase: XCTestCase) {
        queue.sync {
            runningTests.remove(testCase.name)
        }
    }
    
    public var hasRunningTests: Bool {
        queue.sync { !runningTests.isEmpty }
    }
    
    public func waitForCompletion(timeout: TimeInterval = 30) {
        let startTime = Date()
        
        while hasRunningTests && Date().timeIntervalSince(startTime) < timeout {
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        if hasRunningTests {
            print("Warning: Some async tests are still running after \(timeout) seconds")
        }
    }
}

// MARK: - Task Extensions

public extension Task where Success == Never, Failure == Never {
    /// Sleep for a specific duration
    static func sleep(seconds: TimeInterval) async throws {
        try await sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}

// MARK: - Combine Extensions for Async Testing

import Combine

public extension XCTestCase {
    
    /// Wait for a publisher to emit a value
    func waitForPublisher<P: Publisher>(
        _ publisher: P,
        timeout: TimeInterval = 10,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws -> P.Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            
            cancellable = publisher
                .timeout(.seconds(timeout), scheduler: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            continuation.resume(throwing: TestError.publisherCompleted)
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { value in
                        continuation.resume(returning: value)
                        cancellable?.cancel()
                    }
                )
        }
    }
}

private enum TestError: Error {
    case publisherCompleted
}