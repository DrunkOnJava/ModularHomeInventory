import Foundation

/// Error boundary utilities for safer error handling
/// Swift 5.9 - No Swift 6 features

/// Wraps a throwing operation and reports any errors to crash reporting
@discardableResult
public func withErrorReporting<T>(
    operation: String,
    file: String = #file,
    function: String = #function,
    line: Int = #line,
    _ closure: () throws -> T
) -> T? {
    do {
        return try closure()
    } catch {
        CrashReportingService.shared.reportError(
            error,
            userInfo: ["operation": operation],
            file: file,
            function: function,
            line: line
        )
        return nil
    }
}

/// Async version of withErrorReporting
@discardableResult
public func withErrorReporting<T>(
    operation: String,
    file: String = #file,
    function: String = #function,
    line: Int = #line,
    _ closure: () async throws -> T
) async -> T? {
    do {
        return try await closure()
    } catch {
        CrashReportingService.shared.reportError(
            error,
            userInfo: ["operation": operation],
            file: file,
            function: function,
            line: line
        )
        return nil
    }
}

/// Wraps a throwing operation with a default value on error
public func withDefault<T>(
    _ defaultValue: T,
    operation: String? = nil,
    file: String = #file,
    function: String = #function,
    line: Int = #line,
    _ closure: () throws -> T
) -> T {
    do {
        return try closure()
    } catch {
        if let operation = operation {
            CrashReportingService.shared.reportError(
                error,
                userInfo: ["operation": operation],
                file: file,
                function: function,
                line: line
            )
        }
        return defaultValue
    }
}

/// Async version of withDefault
public func withDefault<T>(
    _ defaultValue: T,
    operation: String? = nil,
    file: String = #file,
    function: String = #function,
    line: Int = #line,
    _ closure: () async throws -> T
) async -> T {
    do {
        return try await closure()
    } catch {
        if let operation = operation {
            CrashReportingService.shared.reportError(
                error,
                userInfo: ["operation": operation],
                file: file,
                function: function,
                line: line
            )
        }
        return defaultValue
    }
}

/// Assertion that reports failures in production
public func productionAssert(
    _ condition: @autoclosure () -> Bool,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
) {
    #if DEBUG
    assert(condition(), message(), file: file, line: line)
    #else
    if !condition() {
        CrashReportingService.shared.reportNonFatal(
            "Assertion failed: \(message())",
            userInfo: nil,
            file: "\(file)",
            function: "productionAssert",
            line: Int(line)
        )
    }
    #endif
}

/// Fatal error that reports before crashing
public func reportedFatalError(
    _ message: @autoclosure () -> String,
    userInfo: [String: Any]? = nil,
    file: StaticString = #file,
    function: StaticString = #function,
    line: UInt = #line
) -> Never {
    CrashReportingService.shared.reportNonFatal(
        "Fatal error: \(message())",
        userInfo: userInfo,
        file: "\(file)",
        function: "\(function)",
        line: Int(line)
    )
    
    fatalError(message(), file: file, line: line)
}

// MARK: - Result Extensions

public extension Result {
    /// Report error if failure
    func reportError(
        operation: String? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        if case .failure(let error) = self {
            var userInfo: [String: Any] = [:]
            if let operation = operation {
                userInfo["operation"] = operation
            }
            
            CrashReportingService.shared.reportError(
                error,
                userInfo: userInfo.isEmpty ? nil : userInfo,
                file: file,
                function: function,
                line: line
            )
        }
    }
}

// MARK: - Task Extensions

public extension Task where Failure == Error {
    /// Create a task that reports errors
    init(
        priority: TaskPriority? = nil,
        operation: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        _ block: @escaping () async throws -> Success
    ) {
        self.init(priority: priority) {
            do {
                return try await block()
            } catch {
                CrashReportingService.shared.reportError(
                    error,
                    userInfo: ["operation": operation],
                    file: file,
                    function: function,
                    line: line
                )
                throw error
            }
        }
    }
}

// MARK: - View Error Boundary

import SwiftUI

/// A view that catches and reports errors in its content
public struct ErrorBoundaryView<Content: View>: View {
    let content: () -> Content
    let errorView: (Error) -> AnyView
    @State private var currentError: Error?
    
    public init(
        @ViewBuilder content: @escaping () -> Content,
        errorView: @escaping (Error) -> AnyView = { _ in AnyView(ErrorFallbackView()) }
    ) {
        self.content = content
        self.errorView = errorView
    }
    
    public var body: some View {
        Group {
            if let error = currentError {
                errorView(error)
                    .onAppear {
                        CrashReportingService.shared.reportError(
                            error,
                            userInfo: ["context": "view_error_boundary"]
                        )
                    }
            } else {
                content()
                    .onAppear {
                        // Reset error state when view appears
                        currentError = nil
                    }
            }
        }
    }
}

/// Default error fallback view
public struct ErrorFallbackView: View {
    public init() {}
    
    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Something went wrong")
                .font(.headline)
            
            Text("An error occurred. Please try again.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                // Parent view should handle retry
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}