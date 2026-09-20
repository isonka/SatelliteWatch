import XCTest
@testable import SatelliteWatch

final class HTTPURLTests: XCTestCase {
    func testParseAcceptsHTTPAndHTTPS() {
        XCTAssertNotNil(HTTPURL.parse("https://example.com/a.png"))
        XCTAssertNotNil(HTTPURL.parse("http://example.com/a.png"))
    }

    func testParseRejectsNonHTTPSchemesAndNil() {
        XCTAssertNil(HTTPURL.parse(nil))
        XCTAssertNil(HTTPURL.parse(""))
        XCTAssertNil(HTTPURL.parse("ftp://example.com/a.png"))
        XCTAssertNil(HTTPURL.parse("file:///tmp/a.png"))
        XCTAssertNil(HTTPURL.parse("not a url"))
    }

    func testIsAllowed() {
        XCTAssertTrue(HTTPURL.isAllowed(URL(string: "https://x.com")!))
        XCTAssertTrue(HTTPURL.isAllowed(URL(string: "HTTP://x.com")!))
        XCTAssertFalse(HTTPURL.isAllowed(URL(string: "mailto:a@b.com")!))
    }
}
