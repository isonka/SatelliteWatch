import XCTest
@testable import SatelliteWatch

final class SpaceXAPIClientTests: XCTestCase {
    func testFetchLaunchesPostsQueryWithPopulateSortAndDateBounds() async throws {
        let captured = RequestCapture()
        let client = SpaceXAPIClient { request in
            captured.store(request)
            return StubHTTP.jsonResponse(
                url: request.url!,
                json: SpaceXJSONFixtures.populatedLaunchPage
            )
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        let end = calendar.date(from: DateComponents(year: 2024, month: 1, day: 2))!

        let page = try await client.fetchLaunches(page: 2, limit: 10, startDate: start, endDate: end)

        XCTAssertEqual(page.docs.count, 1)
        let request = try XCTUnwrap(captured.value)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url, SpaceXEndpoint.launchesQuery.url)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")

        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        let options = try XCTUnwrap(json["options"] as? [String: Any])
        XCTAssertEqual(options["page"] as? Int, 2)
        XCTAssertEqual(options["limit"] as? Int, 10)
        XCTAssertEqual(options["populate"] as? [String], ["rocket", "launchpad"])
        let sort = try XCTUnwrap(options["sort"] as? [String: String])
        XCTAssertEqual(sort["date_utc"], "desc")

        let query = try XCTUnwrap(json["query"] as? [String: Any])
        let dateUTC = try XCTUnwrap(query["date_utc"] as? [String: String])
        XCTAssertNotNil(dateUTC["$gte"])
        XCTAssertNotNil(dateUTC["$lte"])
    }

    func testFetchRocketsPostsSortedQuery() async throws {
        let captured = RequestCapture()
        let client = SpaceXAPIClient { request in
            captured.store(request)
            return StubHTTP.jsonResponse(url: request.url!, json: SpaceXJSONFixtures.rocketPage)
        }

        let page = try await client.fetchRockets(page: 1, limit: 20)
        XCTAssertEqual(page.docs.first?.name, "Falcon 9")

        let request = try XCTUnwrap(captured.value)
        XCTAssertEqual(request.url, SpaceXEndpoint.rocketsQuery.url)
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        let options = try XCTUnwrap(json["options"] as? [String: Any])
        let sort = try XCTUnwrap(options["sort"] as? [String: String])
        XCTAssertEqual(sort["name"], "asc")
    }

    func testFetchRocketUsesGET() async throws {
        let captured = RequestCapture()
        let client = SpaceXAPIClient { request in
            captured.store(request)
            return StubHTTP.jsonResponse(url: request.url!, json: SpaceXJSONFixtures.rocket)
        }

        let rocket = try await client.fetchRocket(id: "5e9d0d95eda69973a809d1ec")
        XCTAssertEqual(rocket.name, "Falcon 9")

        let request = try XCTUnwrap(captured.value)
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(
            request.url,
            SpaceXEndpoint.rocket(id: "5e9d0d95eda69973a809d1ec").url
        )
    }

    func testHTTPStatusMapsToSpaceXAPIError() async {
        let client = SpaceXAPIClient { request in
            StubHTTP.response(statusCode: 525, url: request.url!)
        }

        do {
            _ = try await client.fetchRockets(page: 1, limit: 20)
            XCTFail("Expected error")
        } catch let error as SpaceXAPIError {
            XCTAssertEqual(error, .httpStatus(525))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testInvalidJSONMapsToDecodingError() async {
        let client = SpaceXAPIClient { request in
            StubHTTP.response(statusCode: 200, url: request.url!, body: Data("not-json".utf8))
        }

        do {
            _ = try await client.fetchRocket(id: "x")
            XCTFail("Expected error")
        } catch let error as SpaceXAPIError {
            guard case .decoding = error else {
                return XCTFail("Expected decoding, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testTransportFailureMapsToTransportError() async {
        let client = SpaceXAPIClient { _ in
            throw URLError(.notConnectedToInternet)
        }

        do {
            _ = try await client.fetchRockets(page: 1, limit: 20)
            XCTFail("Expected error")
        } catch let error as SpaceXAPIError {
            guard case .transport = error else {
                return XCTFail("Expected transport, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testNonHTTPResponseMapsToInvalidResponse() async {
        let client = SpaceXAPIClient { request in
            (Data(), URLResponse(url: request.url!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil))
        }

        do {
            _ = try await client.fetchRockets(page: 1, limit: 20)
            XCTFail("Expected error")
        } catch let error as SpaceXAPIError {
            XCTAssertEqual(error, .invalidResponse)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testMultiPageRocketDecode() async throws {
        let client = SpaceXAPIClient { request in
            StubHTTP.jsonResponse(url: request.url!, json: SpaceXJSONFixtures.multiPageRocketsPage1)
        }
        let page = try await client.fetchRockets(page: 1, limit: 2)
        XCTAssertEqual(page.docs.map(\.id), ["rocket-a", "rocket-b"])
        XCTAssertTrue(page.hasNextPage)
        XCTAssertEqual(page.nextPage, 2)
    }
}
