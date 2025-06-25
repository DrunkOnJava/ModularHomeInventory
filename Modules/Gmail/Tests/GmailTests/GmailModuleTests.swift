import XCTest
@testable import Gmail

final class GmailModuleTests: XCTestCase {
    var sut: GmailModule!
    
    override func setUp() {
        super.setUp()
        sut = GmailModule()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testModuleInitialization() async throws {
        // Given
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.userEmail)
        XCTAssertTrue(sut.messages.isEmpty)
        
        // When
        try await sut.initialize()
        
        // Then
        // Module should be initialized but not authenticated
        XCTAssertFalse(sut.isAuthenticated)
    }
    
    func testGmailMessageInitialization() {
        // Given
        let id = "msg123"
        let threadId = "thread123"
        let subject = "Test Email"
        let from = "sender@example.com"
        let to = ["recipient@example.com"]
        let date = Date()
        let snippet = "This is a test email..."
        let body = "Full email body"
        let isRead = false
        let labels = ["INBOX", "IMPORTANT"]
        
        // When
        let message = GmailMessage(
            id: id,
            threadId: threadId,
            subject: subject,
            from: from,
            to: to,
            date: date,
            snippet: snippet,
            body: body,
            isRead: isRead,
            labels: labels
        )
        
        // Then
        XCTAssertEqual(message.id, id)
        XCTAssertEqual(message.threadId, threadId)
        XCTAssertEqual(message.subject, subject)
        XCTAssertEqual(message.from, from)
        XCTAssertEqual(message.to, to)
        XCTAssertEqual(message.date, date)
        XCTAssertEqual(message.snippet, snippet)
        XCTAssertEqual(message.body, body)
        XCTAssertEqual(message.isRead, isRead)
        XCTAssertEqual(message.labels, labels)
    }
    
    func testSignOut() {
        // Given
        // Simulate authenticated state
        // Note: In real tests, you would mock the service
        
        // When
        sut.signOut()
        
        // Then
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.userEmail)
        XCTAssertTrue(sut.messages.isEmpty)
        XCTAssertNil(sut.error)
    }
    
    func testAuthenticationFailure() async {
        // Given
        XCTAssertFalse(sut.isAuthenticated)
        
        // When
        let result = try? await sut.authenticate()
        
        // Then
        // Since authentication is not implemented, it should return false
        XCTAssertEqual(result, false)
        XCTAssertFalse(sut.isAuthenticated)
    }
}