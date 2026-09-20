import Foundation
@testable import SatelliteWatch
import Testing

struct RocketLaunchesMatchingTests {
    @Test func keepsOnlyLaunchesForThisRocketFromTheLoadedList() {
        let falcon = Rocket.fixture(id: "falcon9")
        let heavy = Rocket.fixture(id: "falconheavy", name: "Falcon Heavy")
        let matching = Launch.fixture(id: "a", rocket: .id("falcon9"))
        let populated = Launch.fixture(id: "b", rocket: .populated(falcon))
        let other = Launch.fixture(id: "c", rocket: .id("falconheavy"))
        let missing = Launch.fixture(id: "d", rocket: nil)

        let result = falcon.launches(from: [matching, populated, other, missing])

        #expect(result.map(\.id) == ["a", "b"])
        #expect(heavy.launches(from: [matching, other]).map(\.id) == ["c"])
        #expect(falcon.launches(from: []).isEmpty)
    }
}
