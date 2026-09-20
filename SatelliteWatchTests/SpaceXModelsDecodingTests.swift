import Foundation
@testable import SatelliteWatch
import XCTest

final class SpaceXModelsDecodingTests: XCTestCase {
    func testDecodesPopulatedLaunchPage() throws {
        let response = try SpaceXJSONDecoderFactory.make()
            .decode(PaginatedResponse<Launch>.self, from: SpaceXJSONFixtures.populatedLaunchPage)

        XCTAssertEqual(response.docs.count, 1)
        XCTAssertEqual(response.page, 1)
        XCTAssertFalse(response.hasNextPage)
        XCTAssertEqual(response.docs[0].name, "CRS-20")
        XCTAssertEqual(response.docs[0].populatedRocket?.name, "Falcon 9")
        XCTAssertTrue(response.docs[0].launchSiteName.contains("Cape Canaveral"))
        XCTAssertNotNil(response.docs[0].webcastURL)
    }

    func testDecodesLaunchWithIDReferencesAndNullables() throws {
        let launch = try SpaceXJSONDecoderFactory.make()
            .decode(Launch.self, from: SpaceXJSONFixtures.launchWithIDReferences)

        XCTAssertNil(launch.details)
        XCTAssertNil(launch.patchImageURL)
        XCTAssertNil(launch.webcastURL)
        XCTAssertNil(launch.populatedRocket)
        XCTAssertEqual(launch.launchSiteName, "Unknown launch site")
    }

    func testDecodesRocketPage() throws {
        let response = try SpaceXJSONDecoderFactory.make()
            .decode(PaginatedResponse<Rocket>.self, from: SpaceXJSONFixtures.rocketPage)

        XCTAssertEqual(response.docs[0].name, "Falcon 9")
        XCTAssertEqual(response.docs[0].successRatePct, 98)
        XCTAssertEqual(response.docs[0].engines?.number, 9)
        XCTAssertNotNil(response.docs[0].primaryImageURL)
    }

    func testDecodesSparsePaginationEnvelope() throws {
        let json = """
        { "docs": [], "page": 3, "hasNextPage": true }
        """.data(using: .utf8)!

        let response = try SpaceXJSONDecoderFactory.make()
            .decode(PaginatedResponse<Rocket>.self, from: json)

        XCTAssertTrue(response.docs.isEmpty)
        XCTAssertEqual(response.page, 3)
        XCTAssertTrue(response.hasNextPage)
        XCTAssertEqual(response.totalDocs, 0)
        XCTAssertFalse(response.hasPrevPage)
    }

    func testFixtureBuildsLaunchForDirectUse() {
        let launch = Launch.fixture(success: nil, upcoming: true)
        XCTAssertTrue(launch.upcoming)
        XCTAssertNil(launch.success)
        XCTAssertEqual(launch.populatedRocket?.name, "Falcon 9")
    }

    func testEncodesLaunchDateRangeBounds() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let start = calendar.date(from: DateComponents(year: 2020, month: 1, day: 1))!
        let end = calendar.date(from: DateComponents(year: 2020, month: 1, day: 2))!

        let bounds = LaunchDateRangeEncoder.queryBounds(
            start: start,
            end: end,
            calendar: calendar,
            timeZone: TimeZone(secondsFromGMT: 0)!
        )

        XCTAssertEqual(bounds.startUTC, "2020-01-01T00:00:00.000Z")
        XCTAssertEqual(bounds.endUTC, "2020-01-02T23:59:59.999Z")
    }

    func testEndpointPathsUseMixedVersions() {
        XCTAssertTrue(SpaceXEndpoint.launchesQuery.url.absoluteString.hasSuffix("/v5/launches/query"))
        XCTAssertTrue(SpaceXEndpoint.rocketsQuery.url.absoluteString.hasSuffix("/v4/rockets/query"))
        XCTAssertTrue(SpaceXEndpoint.rocket(id: "falcon9").url.absoluteString.hasSuffix("/v4/rockets/falcon9"))
    }

    func testEncodesQueryRequestBody() throws {
        let body = SpaceXQueryRequest(
            query: [
                "date_utc": .object([
                    "$gte": .string("2020-01-01T00:00:00.000Z")
                ])
            ],
            options: SpaceXQueryOptions(
                page: 2,
                limit: 20,
                sort: ["date_utc": "desc"],
                populate: ["rocket", "launchpad"]
            )
        )

        let data = try SpaceXJSONEncoderFactory.make().encode(body)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertTrue(json.contains("\"page\":2"))
        XCTAssertTrue(json.contains("\"limit\":20"))
        XCTAssertTrue(json.contains("date_utc"))
        XCTAssertTrue(json.contains("rocket"))
    }
}
