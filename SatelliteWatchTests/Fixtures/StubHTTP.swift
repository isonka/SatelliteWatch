import Foundation
import os
@testable import SatelliteWatch

enum StubHTTP {
    static func response(
        statusCode: Int = 200,
        url: URL,
        body: Data = Data()
    ) -> (Data, URLResponse) {
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        return (body, response)
    }

    static func jsonResponse(
        statusCode: Int = 200,
        url: URL,
        json: String
    ) -> (Data, URLResponse) {
        response(statusCode: statusCode, url: url, body: Data(json.utf8))
    }
}

final class RequestCapture: @unchecked Sendable {
    private let lock = OSAllocatedUnfairLock<URLRequest?>(initialState: nil)

    func store(_ request: URLRequest) {
        lock.withLock { $0 = request }
    }

    var value: URLRequest? {
        lock.withLock { $0 }
    }
}
