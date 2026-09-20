import XCTest
@testable import SatelliteWatch

final class SpaceXJSONDecodingTests: XCTestCase {
    func testDecodePopulatedLaunchPage() throws {
        let data = Data(SpaceXJSONFixtures.populatedLaunchPage.utf8)
        let page = try SpaceXJSONDecoderFactory.make().decode(
            PaginatedResponse<Launch>.self,
            from: data
        )

        XCTAssertEqual(page.docs.count, 1)
        let launch = try XCTUnwrap(page.docs.first)
        XCTAssertEqual(launch.name, "Starlink-15 (v1.0)")
        XCTAssertEqual(launch.populatedRocket?.name, "Falcon 9")
        XCTAssertEqual(launch.launchSiteName, "Kennedy Space Center Historic Launch Complex 39A")
        XCTAssertNotNil(launch.patchImageURL)
        XCTAssertEqual(launch.datePrecision, .hour)
    }

    func testDecodeLaunchWithIDReferences() throws {
        let data = Data(SpaceXJSONFixtures.launchWithIDReferences.utf8)
        let page = try SpaceXJSONDecoderFactory.make().decode(
            PaginatedResponse<Launch>.self,
            from: data
        )
        let launch = try XCTUnwrap(page.docs.first)
        XCTAssertEqual(launch.rocket, .id("5e9d0d95eda69973a809d1ec"))
        XCTAssertEqual(launch.launchpad, .id("5e9e4502f509094188566f88"))
        XCTAssertNil(launch.populatedRocket)
        XCTAssertEqual(launch.launchSiteName, "Unknown launch site")
    }

    func testDecodeRocket() throws {
        let rocket = try SpaceXJSONDecoderFactory.make().decode(
            Rocket.self,
            from: Data(SpaceXJSONFixtures.rocket.utf8)
        )
        XCTAssertEqual(rocket.name, "Falcon 9")
        XCTAssertEqual(rocket.engines?.number, 9)
        XCTAssertEqual(rocket.enginesDisplayText, "9 × merlin 1D+")
    }

    func testParseISO8601WithAndWithoutFractionalSeconds() {
        XCTAssertNotNil(SpaceXJSONDecoderFactory.parseISO8601("2020-10-24T15:31:00.000Z"))
        XCTAssertNotNil(SpaceXJSONDecoderFactory.parseISO8601("2020-10-24T15:31:00Z"))
        XCTAssertNil(SpaceXJSONDecoderFactory.parseISO8601("not-a-date"))
    }

    func testPaginatedResponseDefaultsMissingPagingFields() throws {
        let json = """
        { "docs": [\(SpaceXJSONFixtures.rocket)] }
        """
        let page = try SpaceXJSONDecoderFactory.make().decode(
            PaginatedResponse<Rocket>.self,
            from: Data(json.utf8)
        )
        XCTAssertEqual(page.page, 1)
        XCTAssertFalse(page.hasNextPage)
        XCTAssertEqual(page.totalDocs, 1)
    }

    func testLibraryRocketMappingComputesSuccessRate() throws {
        let dto = try SpaceXJSONDecoderFactory.make().decode(
            LaunchLibraryListResponse<LaunchLibraryRocketDTO>.self,
            from: Data(LaunchLibraryJSONFixtures.rockets.utf8)
        )
        let rocket = Rocket(library: dto.results[0])
        XCTAssertEqual(rocket.id, "164")
        XCTAssertEqual(rocket.name, "Falcon 9 Block 5")
        XCTAssertEqual(rocket.type, "Falcon")
        XCTAssertEqual(rocket.successRatePct, 98)
        XCTAssertNil(rocket.engines)
        XCTAssertEqual(rocket.enginesDisplayText, "Not provided by this data source")
    }

    func testLibraryLaunchMappingSuccessAndPatchPriority() throws {
        let dto = try SpaceXJSONDecoderFactory.make().decode(
            LaunchLibraryListResponse<LaunchLibraryLaunchDTO>.self,
            from: Data(LaunchLibraryJSONFixtures.previousLaunches.utf8)
        )
        let launch = Launch(library: dto.results[0])
        XCTAssertEqual(launch.success, true)
        XCTAssertFalse(launch.upcoming)
        XCTAssertEqual(launch.datePrecision, .day)
        XCTAssertEqual(launch.rocket?.id, "164")
        XCTAssertEqual(launch.links?.patch?.small, "https://example.com/patch.png")
    }

    func testLibraryLaunchMappingDerivesUpcomingWhenOutcomeUnknown() throws {
        let dto = try SpaceXJSONDecoderFactory.make().decode(
            LaunchLibraryListResponse<LaunchLibraryLaunchDTO>.self,
            from: Data(LaunchLibraryJSONFixtures.upcomingLaunches.utf8)
        )
        let launch = Launch(library: dto.results[0])
        XCTAssertTrue(launch.upcoming)
        XCTAssertNil(launch.success)
        XCTAssertEqual(launch.name, "Crew-11")
    }

    func testLibraryListMapsNextURLOntoPaginatedResponse() throws {
        let dto = try SpaceXJSONDecoderFactory.make().decode(
            LaunchLibraryListResponse<LaunchLibraryLaunchDTO>.self,
            from: Data(LaunchLibraryJSONFixtures.launchesPage1.utf8)
        )
        let page = dto.mappedPage(page: 1, limit: 1) { Launch(library: $0) }
        XCTAssertEqual(page.docs.map(\.id), ["upcoming-1"])
        XCTAssertEqual(page.totalDocs, 2)
        XCTAssertTrue(page.hasNextPage)
        XCTAssertEqual(page.nextPage, 2)
        XCTAssertFalse(page.hasPrevPage)
    }
}
