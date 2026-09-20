import Foundation
@testable import SatelliteWatch
import XCTest

final class LaunchLibraryAPIClientTests: XCTestCase {
    func testLaunchesRequestUpcomingAndPreviousOnce() async throws {
        let stub = StubLaunchLibraryTransport()
        let client = LaunchLibraryAPIClient { try await stub.data(for: $0) }

        _ = try await client.fetchLaunches(page: 1, limit: 20, startDate: nil, endDate: nil)

        let requests = await stub.requests
        XCTAssertEqual(requests.count, 2)
        XCTAssertTrue(requests.allSatisfy { $0.httpMethod == "GET" })
        XCTAssertTrue(requests.allSatisfy { $0.httpBody == nil })
        XCTAssertTrue(requests.allSatisfy { $0.url?.host() == "ll.thespacedevs.com" })

        let paths = Set(requests.compactMap { $0.url?.path() })
        XCTAssertEqual(paths, [
            "/2.2.0/launch/upcoming",
            "/2.2.0/launch/previous"
        ])

        for request in requests {
            let items = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?
                .queryItems ?? []
            let names = items.map(\.name)
            XCTAssertTrue(names.contains("lsp__id"))
            XCTAssertTrue(names.contains("limit"))
            XCTAssertFalse(names.contains("offset"))
            XCTAssertEqual(items.first { $0.name == "lsp__id" }?.value, "121")
            XCTAssertEqual(items.first { $0.name == "limit" }?.value, "100")
        }
    }

    func testMapsMediaIdentifiersAndLinks() async throws {
        let stub = StubLaunchLibraryTransport()
        let client = LaunchLibraryAPIClient { try await stub.data(for: $0) }

        let page = try await client.fetchLaunches(page: 1, limit: 20, startDate: nil, endDate: nil)
        let rich = try XCTUnwrap(page.docs.first { $0.name.contains("Starlink") })
        let sparse = try XCTUnwrap(page.docs.first { $0.name.contains("USSF") })

        XCTAssertEqual(rich.id, "d1471f9d-e9d0-4146-8e97-90863e48bfc8")
        XCTAssertEqual(rich.launchSiteName, "Space Launch Complex 4E")
        XCTAssertEqual(rich.details, "A batch of 27 satellites.")
        XCTAssertEqual(rich.webcastURL?.absoluteString, "https://www.youtube.com/watch?v=gOcigcsXtHk")
        XCTAssertEqual(rich.rocket?.id, "164")
        XCTAssertEqual(
            rich.patchImageURL?.absoluteString,
            "https://example.com/starlink-patch.png"
        )
        XCTAssertEqual(rich.success, true)
        XCTAssertFalse(rich.upcoming)

        XCTAssertEqual(sparse.launchSiteName, "Unknown launch site")
        XCTAssertNil(sparse.rocket)
        XCTAssertNil(sparse.details)
        XCTAssertNil(sparse.webcastURL)
        XCTAssertNil(sparse.patchImageURL)
    }

    func testUpcomingLaunchHasUnknownOutcomeEvenWhenStatusLooksSuccessful() async throws {
        let stub = StubLaunchLibraryTransport()
        let client = LaunchLibraryAPIClient { try await stub.data(for: $0) }

        let page = try await client.fetchLaunches(page: 1, limit: 20, startDate: nil, endDate: nil)
        let scheduled = try XCTUnwrap(page.docs.first { $0.name.contains("Scheduled") })

        XCTAssertTrue(scheduled.upcoming)
        XCTAssertNil(scheduled.success)
        XCTAssertEqual(scheduled.status, .upcoming)
        XCTAssertEqual(
            scheduled.patchImageURL?.absoluteString,
            "https://example.com/falcon9.jpg"
        )
    }

    func testOverlappingUpcomingLaunchKeepsPreviousOutcome() async throws {
        let stub = StubLaunchLibraryTransport()
        let client = LaunchLibraryAPIClient { try await stub.data(for: $0) }

        let page = try await client.fetchLaunches(page: 1, limit: 20, startDate: nil, endDate: nil)
        let starlink = try XCTUnwrap(
            page.docs.first { $0.id == "d1471f9d-e9d0-4146-8e97-90863e48bfc8" }
        )

        XCTAssertEqual(page.docs.filter { $0.id == starlink.id }.count, 1)
        XCTAssertFalse(starlink.upcoming)
        XCTAssertEqual(starlink.success, true)
    }

    func testPagesClientSideAndIgnoresNextLinks() async throws {
        let stub = StubLaunchLibraryTransport()
        let client = LaunchLibraryAPIClient { try await stub.data(for: $0) }

        let first = try await client.fetchLaunches(page: 1, limit: 2, startDate: nil, endDate: nil)
        XCTAssertEqual(first.docs.count, 2)
        XCTAssertTrue(first.hasNextPage)
        XCTAssertEqual(first.totalDocs, 3)

        let second = try await client.fetchLaunches(page: 2, limit: 2, startDate: nil, endDate: nil)
        XCTAssertEqual(second.docs.count, 1)
        XCTAssertFalse(second.hasNextPage)
        XCTAssertTrue(second.hasPrevPage)

        let launchRequestCount = await stub.launchRequestCount
        XCTAssertEqual(launchRequestCount, 2)

        let ids = Set(first.docs.map(\.id)).union(second.docs.map(\.id))
        XCTAssertEqual(ids.count, 3)
    }

    func testPageOneReusesTheSnapshotWithinTheHour() async throws {
        let stub = StubLaunchLibraryTransport()
        let client = LaunchLibraryAPIClient { try await stub.data(for: $0) }

        _ = try await client.fetchLaunches(page: 1, limit: 2, startDate: nil, endDate: nil)
        _ = try await client.fetchLaunches(page: 1, limit: 2, startDate: nil, endDate: nil)

        let launchRequestCount = await stub.launchRequestCount
        XCTAssertEqual(launchRequestCount, 2)
    }

    func testFiltersByDateRangeClientSide() async throws {
        let stub = StubLaunchLibraryTransport()
        let client = LaunchLibraryAPIClient { try await stub.data(for: $0) }

        let day = Date(timeIntervalSince1970: 1_789_607_276)
        let page = try await client.fetchLaunches(
            page: 1,
            limit: 20,
            startDate: day,
            endDate: day
        )

        XCTAssertEqual(page.docs.count, 1)
        XCTAssertEqual(page.docs.first?.name.contains("USSF"), true)
        XCTAssertEqual(page.totalDocs, 1)
    }

    func testMapsRocketsIncludingImageURL() async throws {
        let stub = StubLaunchLibraryTransport()
        let client = LaunchLibraryAPIClient { try await stub.data(for: $0) }

        let page = try await client.fetchRockets(page: 1, limit: 20)
        let falcon = try XCTUnwrap(page.docs.first)

        XCTAssertEqual(falcon.id, "164")
        XCTAssertEqual(falcon.name, "Falcon 9 Block 5")
        XCTAssertEqual(falcon.type, "Falcon")
        XCTAssertEqual(falcon.successRatePct, 99)
        XCTAssertEqual(falcon.description, "Two-stage rocket.")
        XCTAssertEqual(falcon.active, true)
        XCTAssertNil(falcon.engines)
        XCTAssertEqual(falcon.primaryImageURL?.absoluteString, "https://example.com/falcon9.jpg")

        let lastRequest = await stub.lastRequest
        let request = try XCTUnwrap(lastRequest)
        let items = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
        XCTAssertEqual(request.url?.path().hasSuffix("/config/launcher"), true)
        XCTAssertTrue(items.contains { $0.name == "manufacturer__name" && $0.value == "SpaceX" })
        XCTAssertTrue(items.contains { $0.name == "mode" && $0.value == "detailed" })
        XCTAssertFalse(items.contains { $0.name == "offset" })
    }

    func testFetchRocketResolvesTheLibraryIDFromTheCollection() async throws {
        let stub = StubLaunchLibraryTransport()
        let client = LaunchLibraryAPIClient { try await stub.data(for: $0) }

        let rocket = try await client.fetchRocket(id: "164")
        XCTAssertEqual(rocket.name, "Falcon 9 Block 5")
        let firstRocketRequestCount = await stub.rocketRequestCount
        XCTAssertEqual(firstRocketRequestCount, 1)

        _ = try await client.fetchRocket(id: "164")
        let secondRocketRequestCount = await stub.rocketRequestCount
        XCTAssertEqual(secondRocketRequestCount, 1)
    }

    func testFetchRocketThrowsNotFoundForAnUnknownID() async {
        let stub = StubLaunchLibraryTransport()
        let client = LaunchLibraryAPIClient { try await stub.data(for: $0) }

        await assertThrows(SpaceXAPIError.httpStatus(404)) {
            try await client.fetchRocket(id: "saturn-v")
        }
    }

    func testMapsThrottleToHTTPStatusError() async {
        let stub = StubLaunchLibraryTransport(statusCode: 429)
        let client = LaunchLibraryAPIClient { try await stub.data(for: $0) }

        await assertThrows(SpaceXAPIError.httpStatus(429)) {
            try await client.fetchRockets(page: 1, limit: 20)
        }
    }
}

private func assertThrows<E: Error & Equatable, T>(
    _ expected: E,
    file: StaticString = #filePath,
    line: UInt = #line,
    _ body: () async throws -> T
) async {
    do {
        _ = try await body()
        XCTFail("Expected \(expected) but no error was thrown", file: file, line: line)
    } catch let error as E {
        XCTAssertEqual(error, expected, file: file, line: line)
    } catch {
        XCTFail("Expected \(expected), got \(error)", file: file, line: line)
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
