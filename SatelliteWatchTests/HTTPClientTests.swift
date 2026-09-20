import XCTest
@testable import SatelliteWatch

final class HTTPClientTests: XCTestCase {
    func testGETSetsDefaultHeaders() async throws {
        let captured = RequestCapture()
        let client = HTTPClient { request in
            captured.store(request)
            return StubHTTP.jsonResponse(url: request.url!, json: #"{"ok":true}"#)
        }

        struct OK: Decodable { let ok: Bool }
        let url = URL(string: "https://example.com/item")!
        let body: OK = try await client.get(url: url)

        XCTAssertTrue(body.ok)
        let request = try XCTUnwrap(captured.value)
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
        XCTAssertEqual(request.value(forHTTPHeaderField: "User-Agent"), HTTPClient.defaultUserAgent)
        XCTAssertNil(request.value(forHTTPHeaderField: "Content-Type"))
    }

    func testPOSTEncodesJSONBody() async throws {
        let captured = RequestCapture()
        let client = HTTPClient { request in
            captured.store(request)
            return StubHTTP.jsonResponse(url: request.url!, json: #"{"ok":true}"#)
        }

        struct Payload: Encodable { let page: Int }
        struct OK: Decodable { let ok: Bool }
        let _: OK = try await client.post(
            url: URL(string: "https://example.com/query")!,
            body: Payload(page: 2)
        )

        let request = try XCTUnwrap(captured.value)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: try XCTUnwrap(request.httpBody)) as? [String: Int]
        )
        XCTAssertEqual(json["page"], 2)
    }

    func testHTTPStatusMapsToSpaceXAPIError() async {
        let client = HTTPClient { request in
            StubHTTP.response(statusCode: 525, url: request.url!)
        }

        do {
            let _: Envelope = try await client.get(
                url: URL(string: "https://example.com/x")!
            )
            XCTFail("Expected error")
        } catch let error as SpaceXAPIError {
            XCTAssertEqual(error, .httpStatus(525))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testInvalidJSONMapsToDecodingError() async {
        let client = HTTPClient { request in
            StubHTTP.response(statusCode: 200, url: request.url!, body: Data("not-json".utf8))
        }

        do {
            let _: Envelope = try await client.get(
                url: URL(string: "https://example.com/x")!
            )
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
        let client = HTTPClient { _ in
            throw URLError(.notConnectedToInternet)
        }

        do {
            let _: Envelope = try await client.get(
                url: URL(string: "https://example.com/x")!
            )
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
        let client = HTTPClient { request in
            (
                Data(),
                URLResponse(
                    url: request.url!,
                    mimeType: nil,
                    expectedContentLength: 0,
                    textEncodingName: nil
                )
            )
        }

        do {
            let _: Envelope = try await client.get(
                url: URL(string: "https://example.com/x")!
            )
            XCTFail("Expected error")
        } catch let error as SpaceXAPIError {
            XCTAssertEqual(error, .invalidResponse)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

private struct Envelope: Decodable {
    let unused: String
}
