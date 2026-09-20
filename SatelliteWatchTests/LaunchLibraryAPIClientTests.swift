import XCTest
@testable import SatelliteWatch

final class LaunchLibraryAPIClientTests: XCTestCase {
    func testFetchLaunchesMergesDedupesAndSortsDescending() async throws {
        let client = LaunchLibraryAPIClient { request in
            let path = request.url!.path
            if path.contains("/launch/upcoming") {
                return StubHTTP.jsonResponse(url: request.url!, json: LaunchLibraryJSONFixtures.upcomingLaunches)
            }
            if path.contains("/launch/previous") {
                return StubHTTP.jsonResponse(url: request.url!, json: LaunchLibraryJSONFixtures.previousLaunches)
            }
            return StubHTTP.response(statusCode: 404, url: request.url!)
        }

        let page = try await client.fetchLaunches(page: 1, limit: 20, startDate: nil, endDate: nil)
        // previous-1 and upcoming-1 (previous wins on duplicate id)
        XCTAssertEqual(page.docs.map(\.id), ["upcoming-1", "previous-1"])
        XCTAssertEqual(page.docs.first?.name, "Crew-11 (overlap stale)")
        XCTAssertEqual(page.docs.first?.success, true)
        XCTAssertFalse(page.docs.first?.upcoming ?? true)
        XCTAssertEqual(page.totalDocs, 2)
    }

    func testFetchLaunchesPaginatesInMemory() async throws {
        let client = makeLaunchClient()

        let page1 = try await client.fetchLaunches(page: 1, limit: 1, startDate: nil, endDate: nil)
        XCTAssertEqual(page1.docs.count, 1)
        XCTAssertTrue(page1.hasNextPage)
        XCTAssertEqual(page1.totalDocs, 2)

        let page2 = try await client.fetchLaunches(page: 2, limit: 1, startDate: nil, endDate: nil)
        XCTAssertEqual(page2.docs.count, 1)
        XCTAssertFalse(page2.hasNextPage)
        XCTAssertTrue(page2.hasPrevPage)
    }

    func testFetchLaunchesAppliesLocalDateFilter() async throws {
        let client = makeLaunchClient()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        let end = calendar.date(from: DateComponents(year: 2024, month: 12, day: 31))!

        let page = try await client.fetchLaunches(page: 1, limit: 20, startDate: start, endDate: end)
        XCTAssertEqual(page.docs.map(\.id), ["previous-1"])
    }

    func testFetchRocketsAndFetchByID() async throws {
        let client = LaunchLibraryAPIClient { request in
            XCTAssertTrue(request.url!.path.contains("/config/launcher"))
            return StubHTTP.jsonResponse(url: request.url!, json: LaunchLibraryJSONFixtures.rockets)
        }

        let page = try await client.fetchRockets(page: 1, limit: 20)
        XCTAssertEqual(page.docs.map(\.id), ["164", "188"])
        XCTAssertEqual(page.docs.first?.name, "Falcon 9 Block 5")

        let rocket = try await client.fetchRocket(id: "188")
        XCTAssertEqual(rocket.name, "Falcon Heavy")
    }

    func testFetchRocketMissingIDReturns404() async {
        let client = LaunchLibraryAPIClient { request in
            StubHTTP.jsonResponse(url: request.url!, json: LaunchLibraryJSONFixtures.rockets)
        }

        do {
            _ = try await client.fetchRocket(id: "missing")
            XCTFail("Expected error")
        } catch let error as SpaceXAPIError {
            XCTAssertEqual(error, .httpStatus(404))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testHTTPErrorSurfaces() async {
        let client = LaunchLibraryAPIClient { request in
            StubHTTP.response(statusCode: 429, url: request.url!)
        }

        do {
            _ = try await client.fetchRockets(page: 1, limit: 20)
            XCTFail("Expected error")
        } catch let error as SpaceXAPIError {
            XCTAssertEqual(error, .httpStatus(429))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRequestSetsUserAgent() async throws {
        let captured = RequestCapture()
        let client = LaunchLibraryAPIClient { request in
            captured.store(request)
            return StubHTTP.jsonResponse(url: request.url!, json: LaunchLibraryJSONFixtures.rockets)
        }

        _ = try await client.fetchRockets(page: 1, limit: 20)
        XCTAssertEqual(
            captured.value?.value(forHTTPHeaderField: "User-Agent"),
            "SatelliteWatch/1.0 (iOS)"
        )
    }

    private func makeLaunchClient() -> LaunchLibraryAPIClient {
        LaunchLibraryAPIClient { request in
            let path = request.url!.path
            if path.contains("/launch/upcoming") {
                return StubHTTP.jsonResponse(url: request.url!, json: LaunchLibraryJSONFixtures.upcomingLaunches)
            }
            if path.contains("/launch/previous") {
                return StubHTTP.jsonResponse(url: request.url!, json: LaunchLibraryJSONFixtures.previousLaunches)
            }
            return StubHTTP.response(statusCode: 404, url: request.url!)
        }
    }
}
