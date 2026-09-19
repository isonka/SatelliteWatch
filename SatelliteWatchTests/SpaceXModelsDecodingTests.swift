import Foundation
@testable import SatelliteWatch
import Testing

struct SpaceXModelsDecodingTests {
    @Test func decodesPopulatedLaunchPage() throws {
        let response = try SpaceXJSONDecoderFactory.make()
            .decode(PaginatedResponse<Launch>.self, from: SpaceXJSONFixtures.populatedLaunchPage)

        #expect(response.docs.count == 1)
        #expect(response.page == 1)
        #expect(response.hasNextPage == false)
        #expect(response.docs[0].name == "CRS-20")
        #expect(response.docs[0].populatedRocket?.name == "Falcon 9")
        #expect(response.docs[0].launchSiteName.contains("Cape Canaveral"))
        #expect(response.docs[0].webcastURL != nil)
    }

    @Test func decodesLaunchWithIDReferencesAndNullables() throws {
        let launch = try SpaceXJSONDecoderFactory.make()
            .decode(Launch.self, from: SpaceXJSONFixtures.launchWithIDReferences)

        #expect(launch.details == nil)
        #expect(launch.patchImageURL == nil)
        #expect(launch.webcastURL == nil)
        #expect(launch.populatedRocket == nil)
        #expect(launch.launchSiteName == "Unknown launch site")
    }

    @Test func decodesRocketPage() throws {
        let response = try SpaceXJSONDecoderFactory.make()
            .decode(PaginatedResponse<Rocket>.self, from: SpaceXJSONFixtures.rocketPage)

        #expect(response.docs[0].name == "Falcon 9")
        #expect(response.docs[0].successRatePct == 98)
        #expect(response.docs[0].engines?.number == 9)
        #expect(response.docs[0].primaryImageURL != nil)
    }

    @Test func fixtureBuildsLaunchForDirectUse() {
        let launch = Launch.fixture(success: nil, upcoming: true)
        #expect(launch.upcoming)
        #expect(launch.success == nil)
        #expect(launch.populatedRocket?.name == "Falcon 9")
    }

    @Test func encodesLaunchDateRangeBounds() {
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

        #expect(bounds.startUTC == "2020-01-01T00:00:00.000Z")
        #expect(bounds.endUTC == "2020-01-02T23:59:59.999Z")
    }

    @Test func endpointPathsUseMixedVersions() {
        #expect(SpaceXEndpoint.launchesQuery.url.absoluteString.hasSuffix("/v5/launches/query"))
        #expect(SpaceXEndpoint.rocketsQuery.url.absoluteString.hasSuffix("/v4/rockets/query"))
        #expect(SpaceXEndpoint.rocket(id: "falcon9").url.absoluteString.hasSuffix("/v4/rockets/falcon9"))
    }

    @Test func encodesQueryRequestBody() throws {
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
        let json = try #require(String(data: data, encoding: .utf8))
        #expect(json.contains("\"page\":2"))
        #expect(json.contains("\"limit\":20"))
        #expect(json.contains("date_utc"))
        #expect(json.contains("rocket"))
    }
}
