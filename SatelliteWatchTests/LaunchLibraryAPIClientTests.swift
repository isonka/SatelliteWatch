import os
import XCTest
@testable import SatelliteWatch

final class LaunchLibraryAPIClientTests: XCTestCase {
    func testFetchLaunchesPage1SendsLimitOffsetAndOrdering() async throws {
        let captured = RequestCapture()
        let client = LaunchLibraryAPIClient { request in
            captured.store(request)
            return StubHTTP.jsonResponse(url: request.url!, json: LaunchLibraryJSONFixtures.launchesPage1)
        }

        let page = try await client.fetchLaunches(page: 1, limit: 1, startDate: nil, endDate: nil)

        XCTAssertEqual(page.docs.map(\.id), ["upcoming-1"])
        XCTAssertTrue(page.docs[0].upcoming)
        XCTAssertNil(page.docs[0].success)
        XCTAssertTrue(page.hasNextPage)
        XCTAssertEqual(page.totalDocs, 2)
        XCTAssertEqual(page.page, 1)
        XCTAssertEqual(page.nextPage, 2)

        let request = try XCTUnwrap(captured.value)
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.url?.path, "/2.2.0/launch")
        XCTAssertEqual(request.queryValue("lsp__id"), "121")
        XCTAssertEqual(request.queryValue("limit"), "1")
        XCTAssertEqual(request.queryValue("offset"), "0")
        XCTAssertEqual(request.queryValue("ordering"), "-net")
        XCTAssertEqual(request.queryValue("mode"), "detailed")
        XCTAssertNil(request.queryValue("net__gte"))
        XCTAssertNil(request.queryValue("net__lte"))
    }

    func testFetchLaunchesPage2UsesOffsetAndNextIsNil() async throws {
        let captured = RequestCapture()
        let client = LaunchLibraryAPIClient { request in
            captured.store(request)
            return StubHTTP.jsonResponse(url: request.url!, json: LaunchLibraryJSONFixtures.launchesPage2)
        }

        let page = try await client.fetchLaunches(page: 2, limit: 1, startDate: nil, endDate: nil)

        XCTAssertEqual(page.docs.map(\.id), ["previous-1"])
        XCTAssertFalse(page.docs[0].upcoming)
        XCTAssertEqual(page.docs[0].success, true)
        XCTAssertFalse(page.hasNextPage)
        XCTAssertEqual(page.page, 2)
        XCTAssertNil(page.nextPage)

        let request = try XCTUnwrap(captured.value)
        XCTAssertEqual(request.queryValue("limit"), "1")
        XCTAssertEqual(request.queryValue("offset"), "1")
    }

    func testFetchLaunchesSendsDateBoundsAsQuery() async throws {
        let captured = RequestCapture()
        let client = LaunchLibraryAPIClient { request in
            captured.store(request)
            return StubHTTP.jsonResponse(url: request.url!, json: LaunchLibraryJSONFixtures.launchesPage2)
        }

        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        let end = calendar.date(from: DateComponents(year: 2024, month: 12, day: 31))!
        let bounds = LaunchDateRangeEncoder.queryBounds(start: start, end: end)

        _ = try await client.fetchLaunches(page: 1, limit: 20, startDate: start, endDate: end)

        let request = try XCTUnwrap(captured.value)
        XCTAssertEqual(request.queryValue("net__gte"), bounds.startUTC)
        XCTAssertEqual(request.queryValue("net__lte"), bounds.endUTC)
    }

    func testFetchRocketsSendsOffsetAndHasNextFromNextURL() async throws {
        let captured = RequestCapture()
        let client = LaunchLibraryAPIClient { request in
            captured.store(request)
            return StubHTTP.jsonResponse(url: request.url!, json: LaunchLibraryJSONFixtures.rocketsPage)
        }

        let page = try await client.fetchRockets(page: 2, limit: 20)
        XCTAssertEqual(page.docs.map(\.id), ["164", "188"])
        XCTAssertTrue(page.hasNextPage)
        XCTAssertEqual(page.totalDocs, 40)
        XCTAssertEqual(page.page, 2)

        let request = try XCTUnwrap(captured.value)
        XCTAssertEqual(request.url?.path, "/2.2.0/config/launcher")
        XCTAssertEqual(request.queryValue("manufacturer__name"), "SpaceX")
        XCTAssertEqual(request.queryValue("limit"), "20")
        XCTAssertEqual(request.queryValue("offset"), "20")
        XCTAssertEqual(request.queryValue("mode"), "detailed")
    }

    func testFetchRocketUsesDetailPath() async throws {
        let captured = RequestCapture()
        let client = LaunchLibraryAPIClient { request in
            captured.store(request)
            return StubHTTP.jsonResponse(url: request.url!, json: LaunchLibraryJSONFixtures.rocketFalconHeavy)
        }

        let rocket = try await client.fetchRocket(id: "188")
        XCTAssertEqual(rocket.name, "Falcon Heavy")

        let request = try XCTUnwrap(captured.value)
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.url?.path, "/2.2.0/config/launcher/188")
        XCTAssertNil(request.url?.query)
    }

    func testFetchRocketCachesByID() async throws {
        let transportCalls = OSAllocatedUnfairLock(initialState: 0)
        let client = LaunchLibraryAPIClient { request in
            transportCalls.withLock { $0 += 1 }
            return StubHTTP.jsonResponse(url: request.url!, json: LaunchLibraryJSONFixtures.rocketFalconHeavy)
        }

        let first = try await client.fetchRocket(id: "188")
        let second = try await client.fetchRocket(id: "188")

        XCTAssertEqual(first, second)
        XCTAssertEqual(transportCalls.withLock { $0 }, 1)
    }

    func testFetchRocketMissingIDReturns404() async {
        let client = LaunchLibraryAPIClient { request in
            StubHTTP.response(statusCode: 404, url: request.url!)
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
            return StubHTTP.jsonResponse(url: request.url!, json: LaunchLibraryJSONFixtures.rocketsPage)
        }

        _ = try await client.fetchRockets(page: 1, limit: 20)
        XCTAssertEqual(
            captured.value?.value(forHTTPHeaderField: "User-Agent"),
            HTTPClient.defaultUserAgent
        )
    }

    func testOffsetClampsPageAndLimit() {
        XCTAssertEqual(LaunchLibraryEndpoint.offset(page: 1, limit: 20), 0)
        XCTAssertEqual(LaunchLibraryEndpoint.offset(page: 3, limit: 20), 40)
        XCTAssertEqual(LaunchLibraryEndpoint.offset(page: 0, limit: 20), 0)
        XCTAssertEqual(LaunchLibraryEndpoint.offset(page: 2, limit: 0), 1)
    }
}
