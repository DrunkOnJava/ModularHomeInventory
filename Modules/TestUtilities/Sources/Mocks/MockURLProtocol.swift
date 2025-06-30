import Foundation

/// Mock URL protocol for network testing
public class MockURLProtocol: URLProtocol {
    
    // MARK: - Static Configuration
    
    /// Mock responses by URL
    public static var mockResponses: [URL: MockResponse] = [:]
    
    /// Global mock error
    public static var mockError: Error?
    
    /// Global response handler
    public static var mockHandler: ((URLRequest) async throws -> (Data, HTTPURLResponse))?
    
    /// Network condition simulation
    public static var networkCondition: NetworkCondition = .online
    
    /// Request interceptor for validation
    public static var requestInterceptor: ((URLRequest) -> Void)?
    
    /// Reset all mocks
    public static func reset() {
        mockResponses.removeAll()
        mockError = nil
        mockHandler = nil
        networkCondition = .online
        requestInterceptor = nil
    }
    
    // MARK: - URLProtocol Implementation
    
    public override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    public override func startLoading() {
        // Call request interceptor
        Self.requestInterceptor?(request)
        
        Task {
            do {
                // Simulate network condition
                try await simulateNetworkCondition()
                
                // Check for global error
                if let error = Self.mockError {
                    throw error
                }
                
                // Check for handler
                if let handler = Self.mockHandler {
                    let (data, response) = try await handler(request)
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    client?.urlProtocol(self, didLoad: data)
                    client?.urlProtocolDidFinishLoading(self)
                    return
                }
                
                // Check for mock response
                if let url = request.url,
                   let mockResponse = Self.mockResponses[url] {
                    
                    if let error = mockResponse.error {
                        throw error
                    }
                    
                    let response = mockResponse.response ?? HTTPURLResponse(
                        url: url,
                        statusCode: mockResponse.statusCode,
                        httpVersion: nil,
                        headerFields: mockResponse.headers
                    )!
                    
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    
                    if let data = mockResponse.data {
                        client?.urlProtocol(self, didLoad: data)
                    }
                    
                    client?.urlProtocolDidFinishLoading(self)
                    return
                }
                
                // Default 404 response
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 404,
                    httpVersion: nil,
                    headerFields: nil
                )!
                
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocolDidFinishLoading(self)
                
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
        }
    }
    
    public override func stopLoading() {
        // No-op
    }
    
    // MARK: - Private Methods
    
    private func simulateNetworkCondition() async throws {
        switch Self.networkCondition {
        case .offline:
            throw URLError(.notConnectedToInternet)
            
        case .slow3G:
            try await Task.sleep(nanoseconds: 500_000_000) // 500ms
            
        case .lossy(let lossRate):
            if Double.random(in: 0...1) < lossRate {
                throw URLError(.networkConnectionLost)
            }
            
        case .latency(let ms):
            try await Task.sleep(nanoseconds: UInt64(ms) * 1_000_000)
            
        case .online:
            break
        }
    }
}

// MARK: - Mock Response

public struct MockResponse {
    public let data: Data?
    public let statusCode: Int
    public let headers: [String: String]?
    public let error: Error?
    public let response: HTTPURLResponse?
    
    public init(
        data: Data? = nil,
        statusCode: Int = 200,
        headers: [String: String]? = nil,
        error: Error? = nil,
        response: HTTPURLResponse? = nil
    ) {
        self.data = data
        self.statusCode = statusCode
        self.headers = headers
        self.error = error
        self.response = response
    }
    
    /// Create JSON response
    public static func json<T: Encodable>(
        _ object: T,
        statusCode: Int = 200,
        headers: [String: String]? = nil
    ) throws -> MockResponse {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(object)
        
        var allHeaders = headers ?? [:]
        allHeaders["Content-Type"] = "application/json"
        
        return MockResponse(
            data: data,
            statusCode: statusCode,
            headers: allHeaders
        )
    }
    
    /// Create error response
    public static func error(_ error: Error) -> MockResponse {
        return MockResponse(error: error)
    }
    
    /// Create network error
    public static func networkError(_ code: URLError.Code) -> MockResponse {
        return MockResponse(error: URLError(code))
    }
}

// MARK: - URL Extension

public extension URL {
    /// Create URL from path for testing
    static func test(_ path: String) -> URL {
        return URL(string: "https://api.test.com\(path)")!
    }
}