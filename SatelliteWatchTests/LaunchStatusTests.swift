import XCTest
@testable import SatelliteWatch

final class LaunchStatusTests: XCTestCase {
    func testDeriveSuccessAndFailurePreferSuccessFlag() {
        XCTAssertEqual(LaunchStatus.derive(success: true, upcoming: true), .success)
        XCTAssertEqual(LaunchStatus.derive(success: false, upcoming: false), .failure)
    }

    func testDeriveUpcomingWhenSuccessNil() {
        XCTAssertEqual(LaunchStatus.derive(success: nil, upcoming: true), .upcoming)
        XCTAssertEqual(LaunchStatus.derive(success: nil, upcoming: false), .unknown)
    }

    func testTitles() {
        XCTAssertEqual(LaunchStatus.success.title, "Success")
        XCTAssertEqual(LaunchStatus.failure.title, "Failure")
        XCTAssertEqual(LaunchStatus.upcoming.title, "Upcoming")
        XCTAssertEqual(LaunchStatus.unknown.title, "Unknown")
    }

    func testLaunchStatusUsesDerive() {
        XCTAssertEqual(Launch.fixture(success: true, upcoming: false).status, .success)
        XCTAssertEqual(Launch.fixture(success: nil, upcoming: true).status, .upcoming)
    }
}
