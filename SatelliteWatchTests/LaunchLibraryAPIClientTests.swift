import Foundation
@testable import SatelliteWatch
import Testing

struct LaunchLibraryAPIClientTests {
    @Test func launchesRequestUpcomingAndPreviousOnce() async throws {
        let stub = StubLaunchLibraryTransport()
        let client = LaunchLibraryAPIClient { try await stub.data(for: $0) }

        _ = try await client.fetchLaunches(page: 1, limit: 20, startDate: nil, endDate: nil)

        let requests = await stub.requests
        #expect(requests.count == 2)
        #expect(requests.allSatisfy { $0.httpMethod == "GET" })
        #expect(requests.allSatisfy { $0.httpBody == nil })
        #expect(requests.allSatisfy { $0.url?.host() == "ll.thespacedevs.com" })

        let paths = Set(requests.compactMap { $0.url?.path() })
        #expect(paths == [
            "/2.2.0/launch/upcoming",
            "/2.2.0/launch/previous"
        ])

        for request in requests {
            let items = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?
                .queryItems ?? []
            let names = items.map(\.name)
            #expect(names.contains("lsp__id"))
            #expect(names.contains("limit"))
            #expect(names.contains("offset") == false)
            #expect(items.first { $0.name == "lsp__id" }?.value == "121")
            #expect(items.first { $0.name == "limit" }?.value == "100")
        }
    }

    @Test func mapsMediaIdentifiersAndLinks() async throws {
        let stub = StubLaunchLibraryTransport()
        let client = LaunchLibraryAPIClient { try await stub.data(for: $0) }

        let page = try await client.fetchLaunches(page: 1, limit: 20, startDate: nil, endDate: nil)
        let rich = try #require(page.docs.first { $0.name.contains("Starlink") })
        let sparse = try #require(page.docs.first { $0.name.contains("USSF") })

        #expect(rich.id == "d1471f9d-e9d0-4146-8e97-90863e48bfc8")
        #expect(rich.launchSiteName == "Space Launch Complex 4E")
        #expect(rich.details == "A batch of 27 satellites.")
        #expect(rich.webcastURL?.absoluteString == "https://www.youtube.com/watch?v=gOcigcsXtHk")
        #expect(rich.rocket?.id == "164")
        #expect(
            rich.patchImageURL?.absoluteString
                == "https://example.com/starlink-patch.png"
        )
        #expect(rich.success == true)
        #expect(rich.upcoming == false)

        #expect(sparse.launchSiteName == "Unknown launch site")
        #expect(sparse.rocket == nil)
        #expect(sparse.details == nil)
        #expect(sparse.webcastURL == nil)
        #expect(sparse.patchImageURL == nil)
    }

    @Test func upcomingLaunchHasUnknownOutcomeEvenWhenStatusLooksSuccessful() async throws {
        let stub = StubLaunchLibraryTransport()
        let client = LaunchLibraryAPIClient { try await stub.data(for: $0) }

        let page = try await client.fetchLaunches(page: 1, limit: 20, startDate: nil, endDate: nil)
        let scheduled = try #require(page.docs.first { $0.name.contains("Scheduled") })

        #expect(scheduled.upcoming)
        #expect(scheduled.success == nil)
        #expect(scheduled.status == .upcoming)
        #expect(
            scheduled.patchImageURL?.absoluteString
                == "https://example.com/falcon9.jpg"
        )
    }

    @Test func overlappingUpcomingLaunchKeepsPreviousOutcome() async throws {
        let stub = StubLaunchLibraryTransport()
        let client = LaunchLibraryAPIClient { try await stub.data(for: $0) }

        let page = try await client.fetchLaunches(page: 1, limit: 20, startDate: nil, endDate: nil)
        let starlink = try #require(
            page.docs.first { $0.id == "d1471f9d-e9d0-4146-8e97-90863e48bfc8" }
        )

        #expect(page.docs.filter { $0.id == starlink.id }.count == 1)
        #expect(starlink.upcoming == false)
        #expect(starlink.success == true)
    }

    @Test func pagesClientSideAndIgnoresNextLinks() async throws {
        let stub = StubLaunchLibraryTransport()
        let client = LaunchLibraryAPIClient { try await stub.data(for: $0) }

        let first = try await client.fetchLaunches(page: 1, limit: 2, startDate: nil, endDate: nil)
        #expect(first.docs.count == 2)
        #expect(first.hasNextPage)
        #expect(first.totalDocs == 3)

        let second = try await client.fetchLaunches(page: 2, limit: 2, startDate: nil, endDate: nil)
        #expect(second.docs.count == 1)
        #expect(second.hasNextPage == false)
        #expect(second.hasPrevPage)

        #expect(await stub.launchRequestCount == 2)

        let ids = Set(first.docs.map(\.id)).union(second.docs.map(\.id))
        #expect(ids.count == 3)
    }

    @Test func pageOneReusesTheSnapshotWithinTheHour() async throws {
        let stub = StubLaunchLibraryTransport()
        let client = LaunchLibraryAPIClient { try await stub.data(for: $0) }

        _ = try await client.fetchLaunches(page: 1, limit: 2, startDate: nil, endDate: nil)
        _ = try await client.fetchLaunches(page: 1, limit: 2, startDate: nil, endDate: nil)

        #expect(await stub.launchRequestCount == 2)
    }

    @Test func filtersByDateRangeClientSide() async throws {
        let stub = StubLaunchLibraryTransport()
        let client = LaunchLibraryAPIClient { try await stub.data(for: $0) }

        let day = Date(timeIntervalSince1970: 1_789_607_276)
        let page = try await client.fetchLaunches(
            page: 1,
            limit: 20,
            startDate: day,
            endDate: day
        )

        #expect(page.docs.count == 1)
        #expect(page.docs.first?.name.contains("USSF") == true)
        #expect(page.totalDocs == 1)
    }

    @Test func mapsRocketsIncludingImageURL() async throws {
        let stub = StubLaunchLibraryTransport()
        let client = LaunchLibraryAPIClient { try await stub.data(for: $0) }

        let page = try await client.fetchRockets(page: 1, limit: 20)
        let falcon = try #require(page.docs.first)

        #expect(falcon.id == "164")
        #expect(falcon.name == "Falcon 9 Block 5")
        #expect(falcon.type == "Falcon")
        #expect(falcon.successRatePct == 99)
        #expect(falcon.description == "Two-stage rocket.")
        #expect(falcon.active == true)
        #expect(falcon.engines == nil)
        #expect(falcon.primaryImageURL?.absoluteString == "https://example.com/falcon9.jpg")

        let request = try #require(await stub.lastRequest)
        let items = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(request.url?.path().hasSuffix("/config/launcher") == true)
        #expect(items.contains { $0.name == "manufacturer__name" && $0.value == "SpaceX" })
        #expect(items.contains { $0.name == "mode" && $0.value == "detailed" })
        #expect(items.contains { $0.name == "offset" } == false)
    }

    @Test func fetchRocketResolvesTheLibraryIDFromTheCollection() async throws {
        let stub = StubLaunchLibraryTransport()
        let client = LaunchLibraryAPIClient { try await stub.data(for: $0) }

        let rocket = try await client.fetchRocket(id: "164")
        #expect(rocket.name == "Falcon 9 Block 5")
        #expect(await stub.rocketRequestCount == 1)

        _ = try await client.fetchRocket(id: "164")
        #expect(await stub.rocketRequestCount == 1)
    }

    @Test func fetchRocketThrowsNotFoundForAnUnknownID() async {
        let stub = StubLaunchLibraryTransport()
        let client = LaunchLibraryAPIClient { try await stub.data(for: $0) }

        await #expect(throws: SpaceXAPIError.httpStatus(404)) {
            try await client.fetchRocket(id: "saturn-v")
        }
    }

    @Test func mapsThrottleToHTTPStatusError() async {
        let stub = StubLaunchLibraryTransport(statusCode: 429)
        let client = LaunchLibraryAPIClient { try await stub.data(for: $0) }

        await #expect(throws: SpaceXAPIError.httpStatus(429)) {
            try await client.fetchRockets(page: 1, limit: 20)
        }
    }
}

private enum LaunchLibraryJSONFixtures {
    static let previous = """
    {
      "count": 900,
      "next": "https://ll.thespacedevs.com/2.2.0/launch/previous/?limit=100&lsp__id=121&offset=100",
      "results": [
        {
          "id": "d1471f9d-e9d0-4146-8e97-90863e48bfc8",
          "name": "Falcon 9 Block 5 | Starlink Group 15-27",
          "net": "2026-09-20T01:47:00Z",
          "image": "https://example.com/falcon9.jpg",
          "status": { "id": 3, "abbrev": "Success" },
          "net_precision": { "abbrev": "SEC" },
          "rocket": {
            "configuration": {
              "id": 164,
              "name": "Falcon 9",
              "full_name": "Falcon 9 Block 5"
            }
          },
          "mission": {
            "description": "A batch of 27 satellites.",
            "info_urls": ["https://www.spacex.com/launches/sl-15-27"],
            "vid_urls": [{ "url": "https://www.youtube.com/watch?v=gOcigcsXtHk" }]
          },
          "pad": {
            "id": 16,
            "name": "Space Launch Complex 4E",
            "wiki_url": "https://en.wikipedia.org/wiki/Vandenberg",
            "location": { "name": "Vandenberg SFB, CA, USA", "country_code": "USA" }
          },
          "program": [
            {
              "mission_patches": [
                {
                  "priority": 10,
                  "image_url": "https://example.com/starlink-patch.png"
                }
              ]
            }
          ]
        },
        {
          "id": "sparse-ussf",
          "name": "Falcon 9 Block 5 | USSF-259",
          "net": "2026-09-17T01:07:56Z",
          "status": { "id": 3, "abbrev": "Success" }
        }
      ]
    }
    """.data(using: .utf8)!

    static let upcoming = """
    {
      "count": 100,
      "next": "https://ll.thespacedevs.com/2.2.0/launch/upcoming/?limit=100&lsp__id=121&offset=100",
      "results": [
        {
          "id": "d1471f9d-e9d0-4146-8e97-90863e48bfc8",
          "name": "Falcon 9 Block 5 | Starlink Group 15-27",
          "net": "2026-09-20T01:47:00Z",
          "image": "https://example.com/falcon9.jpg",
          "status": { "id": 3, "abbrev": "Success" }
        },
        {
          "id": "scheduled-flight",
          "name": "Falcon 9 Block 5 | Scheduled Flight",
          "net": "2099-01-01T00:00:00Z",
          "image": "https://example.com/falcon9.jpg",
          "status": { "id": 1, "abbrev": "Go" }
        }
      ]
    }
    """.data(using: .utf8)!

    static let rockets = """
    {
      "count": 13,
      "next": null,
      "results": [
        {
          "id": 164,
          "name": "Falcon 9",
          "full_name": "Falcon 9 Block 5",
          "family": "Falcon",
          "description": "Two-stage rocket.",
          "active": true,
          "image_url": "https://example.com/falcon9.jpg",
          "total_launch_count": 100,
          "successful_launches": 99
        }
      ]
    }
    """.data(using: .utf8)!
}

private actor StubLaunchLibraryTransport {
    private(set) var requests: [URLRequest] = []
    private let previous: Data
    private let upcoming: Data
    private let rockets: Data
    private let statusCode: Int

    var lastRequest: URLRequest? { requests.last }

    var launchRequestCount: Int {
        requests.filter {
            let path = $0.url?.path() ?? ""
            return path.hasSuffix("/launch/upcoming") || path.hasSuffix("/launch/previous")
        }.count
    }

    var rocketRequestCount: Int {
        requests.filter { $0.url?.path().hasSuffix("/config/launcher") == true }.count
    }

    init(
        previous: Data = LaunchLibraryJSONFixtures.previous,
        upcoming: Data = LaunchLibraryJSONFixtures.upcoming,
        rockets: Data = LaunchLibraryJSONFixtures.rockets,
        statusCode: Int = 200
    ) {
        self.previous = previous
        self.upcoming = upcoming
        self.rockets = rockets
        self.statusCode = statusCode
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)

        let url = request.url ?? LaunchLibraryEndpoint.baseURL
        let path = url.path()
        let body: Data
        if path.hasSuffix("/launch/upcoming") {
            body = upcoming
        } else if path.hasSuffix("/launch/previous") {
            body = previous
        } else {
            body = rockets
        }

        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        return (body, response)
    }
}
