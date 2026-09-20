import XCTest
@testable import SatelliteWatch

final class ModelHelpersTests: XCTestCase {
    func testEnginesDisplayTextWithParts() {
        let rocket = Rocket.fixture(
            engines: RocketEngines(number: 9, type: "merlin", version: "1D+")
        )
        XCTAssertEqual(rocket.enginesDisplayText, "9 × merlin 1D+")
    }

    func testEnginesDisplayTextMissingSource() {
        XCTAssertEqual(Rocket.fixture(engines: nil).enginesDisplayText, "Not provided by this data source")
        XCTAssertEqual(
            Rocket.fixture(engines: RocketEngines(number: nil, type: nil, version: nil)).enginesDisplayText,
            "Not provided by this data source"
        )
    }

    func testEnginesDisplayTextPartialUsesPlaceholders() {
        let rocket = Rocket.fixture(
            engines: RocketEngines(number: nil, type: "merlin", version: nil)
        )
        XCTAssertEqual(rocket.enginesDisplayText, "— × merlin")
    }

    func testRocketLaunchesFiltersByRocketID() {
        let falcon = Rocket.fixture(id: "falcon9")
        let heavy = Rocket.fixture(id: "heavy")
        let launches = [
            Launch.fixture(id: "a", rocket: .id("falcon9")),
            Launch.fixture(id: "b", rocket: .populated(heavy)),
            Launch.fixture(id: "c", rocket: .populated(falcon))
        ]
        XCTAssertEqual(falcon.launches(from: launches).map(\.id), ["a", "c"])
    }

    func testLaunchSiteNameAndPatchURL() {
        let populated = Launch.fixture(launchpad: .populated(.fixture(fullName: "Pad Full")))
        XCTAssertEqual(populated.launchSiteName, "Pad Full")

        let idOnly = Launch.fixture(launchpad: .id("pad-1"))
        XCTAssertEqual(idOnly.launchSiteName, "Unknown launch site")

        XCTAssertNotNil(Launch.fixture().patchImageURL)
        XCTAssertNil(Launch.fixture(links: nil).patchImageURL)
    }

    func testLaunchpadDisplayNameFallback() {
        XCTAssertEqual(
            LaunchpadSummary.fixture(name: "Short", fullName: nil).displayName,
            "Short"
        )
        XCTAssertEqual(
            LaunchpadSummary.fixture(name: nil, fullName: nil).displayName,
            "Unknown launch site"
        )
    }

    func testDatePrecisionLibraryAbbrev() {
        XCTAssertEqual(DatePrecision(libraryAbbrev: "HOUR"), .hour)
        XCTAssertEqual(DatePrecision(libraryAbbrev: "day"), .day)
        XCTAssertEqual(DatePrecision(libraryAbbrev: "MONTH"), .month)
        XCTAssertEqual(DatePrecision(libraryAbbrev: "QTR"), .quarter)
        XCTAssertEqual(DatePrecision(libraryAbbrev: "HALF"), .half)
        XCTAssertEqual(DatePrecision(libraryAbbrev: "YEAR"), .year)
        XCTAssertNil(DatePrecision(libraryAbbrev: "NOPE"))
        XCTAssertNil(DatePrecision(libraryAbbrev: nil))
    }
}
