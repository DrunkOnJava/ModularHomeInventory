import XCTest
@testable import Scanner

final class ScannerModuleTests: XCTestCase {
    func testModuleInitialization() {
        // Swift 5.9 test
        let dependencies = ScannerModuleDependencies()
        let module = ScannerModule(dependencies: dependencies)
        XCTAssertNotNil(module)
    }
}