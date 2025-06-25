import XCTest
@testable import Gmail

final class GmailTests: XCTestCase {
    func testGmailModuleInitialization() {
        let module = GmailModule()
        XCTAssertNotNil(module)
    }
}