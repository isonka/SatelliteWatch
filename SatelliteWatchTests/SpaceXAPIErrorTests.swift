import XCTest
@testable import SatelliteWatch

final class SpaceXAPIErrorTests: XCTestCase {
    func testUserFacingMessages() {
        XCTAssertEqual(
            SpaceXAPIError.invalidResponse.errorDescription,
            "Received an unexpected response. Please try again."
        )
        XCTAssertEqual(
            SpaceXAPIError.decoding("x").errorDescription,
            "Data could not be read. Please try again later."
        )
        XCTAssertEqual(
            SpaceXAPIError.transport("x").errorDescription,
            "Unable to connect. Check your internet connection and try again."
        )
        XCTAssertEqual(
            SpaceXAPIError.httpStatus(404).errorDescription,
            "The requested data could not be found."
        )
        XCTAssertEqual(
            SpaceXAPIError.httpStatus(429).errorDescription,
            "Too many requests. Wait and try again."
        )
        XCTAssertEqual(
            SpaceXAPIError.httpStatus(525).errorDescription,
            "The SpaceX API is archived and unavailable right now. Try again later."
        )
        XCTAssertEqual(
            SpaceXAPIError.httpStatus(503).errorDescription,
            "Launch data is temporarily unavailable. Please try again later."
        )
        XCTAssertEqual(
            SpaceXAPIError.httpStatus(418).errorDescription,
            "Unable to load data right now. Please try again."
        )
    }

    func testDebugDescription() {
        XCTAssertEqual(SpaceXAPIError.httpStatus(525).debugDescription, "httpStatus(525)")
        XCTAssertEqual(SpaceXAPIError.decoding("bad").debugDescription, "decoding(bad)")
    }
}
