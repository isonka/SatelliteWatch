import Foundation
@testable import SatelliteWatch
import Testing

struct SpaceXAPIClientTests {
    @Test func fetchLaunchesPostsV5QueryAndDecodesPage() async throws {
        let stub = StubHTTPTransport(data: SpaceXJSONFixtures.populatedLaunchPage)
        let client = SpaceXAPIClient { try await stub.data(for: $0) }

        let page = try await client.fetchLaunches(page: 1, limit: 20, startDate: nil, endDate: nil)
        let request = try #require(await stub.lastRequest)

        #expect(page.docs.first?.name == "CRS-20")
        #expect(request.httpMethod == "POST")
        #expect(request.url?.absoluteString.hasSuffix("/v5/launches/query") == true)
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

        let body = try #require(request.httpBody.flatMap {
            try JSONSerialization.jsonObject(with: $0) as? [String: Any]
        })
        let options = try #require(body["options"] as? [String: Any])
        #expect(jsonInt(options["page"]) == 1)
        #expect(jsonInt(options["limit"]) == 20)
        #expect((options["populate"] as? [String]) == ["rocket", "launchpad"])
    }

    @Test func fetchLaunchesEncodesDateBounds() async throws {
        let start = Date(timeIntervalSince1970: 1_577_836_800)
        let end = Date(timeIntervalSince1970: 1_577_923_200)
        let expected = LaunchDateRangeEncoder.queryBounds(start: start, end: end)

        let stub = StubHTTPTransport(data: SpaceXJSONFixtures.populatedLaunchPage)
        let client = SpaceXAPIClient { try await stub.data(for: $0) }

        _ = try await client.fetchLaunches(page: 1, limit: 20, startDate: start, endDate: end)
        let body = try #require(await stub.lastRequest?.httpBody.flatMap {
            try JSONSerialization.jsonObject(with: $0) as? [String: Any]
        })
        let query = try #require(body["query"] as? [String: Any])
        let dateUTC = try #require(query["date_utc"] as? [String: Any])
        #expect(dateUTC["$gte"] as? String == expected.startUTC)
        #expect(dateUTC["$lte"] as? String == expected.endUTC)
    }

    @Test func fetchRocketsPostsV4Query() async throws {
        let stub = StubHTTPTransport(data: SpaceXJSONFixtures.rocketPage)
        let client = SpaceXAPIClient { try await stub.data(for: $0) }

        let page = try await client.fetchRockets(page: 2, limit: 10)
        let request = try #require(await stub.lastRequest)

        #expect(page.docs.first?.name == "Falcon 9")
        #expect(request.httpMethod == "POST")
        #expect(request.url?.absoluteString.hasSuffix("/v4/rockets/query") == true)

        let body = try #require(request.httpBody.flatMap {
            try JSONSerialization.jsonObject(with: $0) as? [String: Any]
        })
        let options = try #require(body["options"] as? [String: Any])
        #expect(jsonInt(options["page"]) == 2)
        #expect(jsonInt(options["limit"]) == 10)
    }

    @Test func fetchRocketUsesGETByID() async throws {
        let stub = StubHTTPTransport(data: SpaceXJSONFixtures.rocket)
        let client = SpaceXAPIClient { try await stub.data(for: $0) }

        let rocket = try await client.fetchRocket(id: "falcon9")
        let request = try #require(await stub.lastRequest)

        #expect(rocket.id == "falcon9")
        #expect(request.httpMethod == "GET")
        #expect(request.url?.absoluteString.hasSuffix("/v4/rockets/falcon9") == true)
        #expect(request.httpBody == nil)
    }

    @Test func mapsNon2xxToHTTPStatusError() async {
        let stub = StubHTTPTransport(data: Data(), statusCode: 500)
        let client = SpaceXAPIClient { try await stub.data(for: $0) }

        await #expect(throws: SpaceXAPIError.httpStatus(500)) {
            try await client.fetchRockets(page: 1, limit: 20)
        }
    }

    @Test func mapsNonHTTPResponseToInvalidResponse() async {
        let stub = StubHTTPTransport(data: Data(), nonHTTP: true)
        let client = SpaceXAPIClient { try await stub.data(for: $0) }

        await #expect(throws: SpaceXAPIError.invalidResponse) {
            try await client.fetchRocket(id: "falcon9")
        }
    }

    @Test func mapsMalformedJSONToDecodingError() async {
        let stub = StubHTTPTransport(data: Data("not-json".utf8))
        let client = SpaceXAPIClient { try await stub.data(for: $0) }

        do {
            _ = try await client.fetchRockets(page: 1, limit: 20)
            Issue.record("Expected decoding error")
        } catch let error as SpaceXAPIError {
            guard case .decoding = error else {
                Issue.record("Expected decoding, got \(error.debugDescription)")
                return
            }
        } catch {
            Issue.record("Expected SpaceXAPIError, got \(error)")
        }
    }

    @Test func mapsCancelledURLErrorToCancellationError() async {
        let stub = StubHTTPTransport(error: URLError(.cancelled))
        let client = SpaceXAPIClient { try await stub.data(for: $0) }

        do {
            _ = try await client.fetchLaunches(page: 1, limit: 20, startDate: nil, endDate: nil)
            Issue.record("Expected cancellation")
        } catch is CancellationError {
            // expected
        } catch {
            Issue.record("Expected CancellationError, got \(error)")
        }
    }

    @Test func mapsTransportFailure() async {
        let stub = StubHTTPTransport(error: URLError(.notConnectedToInternet))
        let client = SpaceXAPIClient { try await stub.data(for: $0) }

        do {
            _ = try await client.fetchRockets(page: 1, limit: 20)
            Issue.record("Expected transport error")
        } catch let error as SpaceXAPIError {
            guard case .transport = error else {
                Issue.record("Expected transport, got \(error.debugDescription)")
                return
            }
        } catch {
            Issue.record("Expected SpaceXAPIError, got \(error)")
        }
    }
}

private func jsonInt(_ value: Any?) -> Int? {
    (value as? Int) ?? (value as? NSNumber)?.intValue
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
