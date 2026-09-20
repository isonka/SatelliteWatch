import Foundation
@testable import SatelliteWatch
import XCTest

final class SpaceXAPIClientTests: XCTestCase {
    func testFetchLaunchesPostsV5QueryAndDecodesPage() async throws {
        let stub = StubHTTPTransport(data: SpaceXJSONFixtures.populatedLaunchPage)
        let client = SpaceXAPIClient { try await stub.data(for: $0) }

        let page = try await client.fetchLaunches(page: 1, limit: 20, startDate: nil, endDate: nil)
        let lastRequest = await stub.lastRequest
        let request = try XCTUnwrap(lastRequest)

        XCTAssertEqual(page.docs.first?.name, "CRS-20")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString.hasSuffix("/v5/launches/query"), true)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")

        let body = try XCTUnwrap(request.httpBody.flatMap {
            try JSONSerialization.jsonObject(with: $0) as? [String: Any]
        })
        let options = try XCTUnwrap(body["options"] as? [String: Any])
        XCTAssertEqual(jsonInt(options["page"]), 1)
        XCTAssertEqual(jsonInt(options["limit"]), 20)
        XCTAssertEqual(options["populate"] as? [String], ["rocket", "launchpad"])
    }

    func testFetchLaunchesEncodesDateBounds() async throws {
        let start = Date(timeIntervalSince1970: 1_577_836_800)
        let end = Date(timeIntervalSince1970: 1_577_923_200)
        let expected = LaunchDateRangeEncoder.queryBounds(start: start, end: end)

        let stub = StubHTTPTransport(data: SpaceXJSONFixtures.populatedLaunchPage)
        let client = SpaceXAPIClient { try await stub.data(for: $0) }

        _ = try await client.fetchLaunches(page: 1, limit: 20, startDate: start, endDate: end)
        let lastRequest = await stub.lastRequest
        let body = try XCTUnwrap(lastRequest?.httpBody.flatMap {
            try JSONSerialization.jsonObject(with: $0) as? [String: Any]
        })
        let query = try XCTUnwrap(body["query"] as? [String: Any])
        let dateUTC = try XCTUnwrap(query["date_utc"] as? [String: Any])
        XCTAssertEqual(dateUTC["$gte"] as? String, expected.startUTC)
        XCTAssertEqual(dateUTC["$lte"] as? String, expected.endUTC)
    }

    func testFetchRocketsPostsV4Query() async throws {
        let stub = StubHTTPTransport(data: SpaceXJSONFixtures.rocketPage)
        let client = SpaceXAPIClient { try await stub.data(for: $0) }

        let page = try await client.fetchRockets(page: 2, limit: 10)
        let lastRequest = await stub.lastRequest
        let request = try XCTUnwrap(lastRequest)

        XCTAssertEqual(page.docs.first?.name, "Falcon 9")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString.hasSuffix("/v4/rockets/query"), true)

        let body = try XCTUnwrap(request.httpBody.flatMap {
            try JSONSerialization.jsonObject(with: $0) as? [String: Any]
        })
        let options = try XCTUnwrap(body["options"] as? [String: Any])
        XCTAssertEqual(jsonInt(options["page"]), 2)
        XCTAssertEqual(jsonInt(options["limit"]), 10)
    }

    func testFetchRocketUsesGETByID() async throws {
        let stub = StubHTTPTransport(data: SpaceXJSONFixtures.rocket)
        let client = SpaceXAPIClient { try await stub.data(for: $0) }

        let rocket = try await client.fetchRocket(id: "falcon9")
        let lastRequest = await stub.lastRequest
        let request = try XCTUnwrap(lastRequest)

        XCTAssertEqual(rocket.id, "falcon9")
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.url?.absoluteString.hasSuffix("/v4/rockets/falcon9"), true)
        XCTAssertNil(request.httpBody)
    }

    func testMapsNon2xxToHTTPStatusError() async {
        let stub = StubHTTPTransport(data: Data(), statusCode: 500)
        let client = SpaceXAPIClient { try await stub.data(for: $0) }

        await assertThrows(SpaceXAPIError.httpStatus(500)) {
            try await client.fetchRockets(page: 1, limit: 20)
        }
    }

    func testMapsNonHTTPResponseToInvalidResponse() async {
        let stub = StubHTTPTransport(data: Data(), nonHTTP: true)
        let client = SpaceXAPIClient { try await stub.data(for: $0) }

        await assertThrows(SpaceXAPIError.invalidResponse) {
            try await client.fetchRocket(id: "falcon9")
        }
    }

    func testMapsMalformedJSONToDecodingError() async {
        let stub = StubHTTPTransport(data: Data("not-json".utf8))
        let client = SpaceXAPIClient { try await stub.data(for: $0) }

        do {
            _ = try await client.fetchRockets(page: 1, limit: 20)
            XCTFail("Expected decoding error")
        } catch let error as SpaceXAPIError {
            guard case .decoding = error else {
                XCTFail("Expected decoding, got \(error.debugDescription)")
                return
            }
        } catch {
            XCTFail("Expected SpaceXAPIError, got \(error)")
        }
    }

    func testMapsCancelledURLErrorToCancellationError() async {
        let stub = StubHTTPTransport(error: URLError(.cancelled))
        let client = SpaceXAPIClient { try await stub.data(for: $0) }

        do {
            _ = try await client.fetchLaunches(page: 1, limit: 20, startDate: nil, endDate: nil)
            XCTFail("Expected cancellation")
        } catch is CancellationError {
            // expected
        } catch {
            XCTFail("Expected CancellationError, got \(error)")
        }
    }

    func testMapsTransportFailure() async {
        let stub = StubHTTPTransport(error: URLError(.notConnectedToInternet))
        let client = SpaceXAPIClient { try await stub.data(for: $0) }

        do {
            _ = try await client.fetchRockets(page: 1, limit: 20)
            XCTFail("Expected transport error")
        } catch let error as SpaceXAPIError {
            guard case .transport = error else {
                XCTFail("Expected transport, got \(error.debugDescription)")
                return
            }
        } catch {
            XCTFail("Expected SpaceXAPIError, got \(error)")
        }
    }
}

private func jsonInt(_ value: Any?) -> Int? {
    (value as? Int) ?? (value as? NSNumber)?.intValue
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

private actor StubHTTPTransport {
    private(set) var requests: [URLRequest] = []
    private let data: Data
    private let statusCode: Int
    private let nonHTTP: Bool
    private let error: Error?

    var lastRequest: URLRequest? { requests.last }

    init(
        data: Data = Data(),
        statusCode: Int = 200,
        nonHTTP: Bool = false,
        error: Error? = nil
    ) {
        self.data = data
        self.statusCode = statusCode
        self.nonHTTP = nonHTTP
        self.error = error
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        if let error {
            throw error
        }
        let url = request.url ?? URL(string: "https://api.spacexdata.com")!
        if nonHTTP {
            return (
                data,
                URLResponse(
                    url: url,
                    mimeType: nil,
                    expectedContentLength: 0,
                    textEncodingName: nil
                )
            )
        }
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        return (data, response)
    }
}
