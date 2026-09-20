import Foundation
@testable import SatelliteWatch
import XCTest

final class RocketLaunchesMatchingTests: XCTestCase {
    func testKeepsOnlyLaunchesForThisRocketFromTheLoadedList() {
        let falcon = Rocket.fixture(id: "falcon9")
        let heavy = Rocket.fixture(id: "falconheavy", name: "Falcon Heavy")
        let matching = Launch.fixture(id: "a", rocket: .id("falcon9"))
        let populated = Launch.fixture(id: "b", rocket: .populated(falcon))
        let other = Launch.fixture(id: "c", rocket: .id("falconheavy"))
        let missing = Launch.fixture(id: "d", rocket: nil)

        let result = falcon.launches(from: [matching, populated, other, missing])

        XCTAssertEqual(result.map(\.id), ["a", "b"])
        XCTAssertEqual(heavy.launches(from: [matching, other]).map(\.id), ["c"])
        XCTAssertTrue(falcon.launches(from: []).isEmpty)
    }
}
