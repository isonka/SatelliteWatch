import os
import XCTest
@testable import SatelliteWatch

final class RemoteImageLoaderTests: XCTestCase {
    func testRejectsNonHTTPURL() async {
        let loader = RemoteImageLoader { _ in
            XCTFail("fetch should not run")
            return Data()
        }
        let image = await loader.image(from: URL(string: "file:///tmp/x.png")!, maxPixelSize: 64)
        XCTAssertNil(image)
    }

    func testCachesSuccessfulImage() async throws {
        final class Counter: @unchecked Sendable {
            private let value = OSAllocatedUnfairLock(initialState: 0)

            func increment() {
                value.withLock { $0 += 1 }
            }

            var current: Int {
                value.withLock { $0 }
            }
        }

        let counter = Counter()
        let png = try XCTUnwrap(Self.tinyPNG)
        let loader = RemoteImageLoader { _ in
            counter.increment()
            return png
        }
        let url = URL(string: "https://example.com/patch.png")!

        let first = await loader.image(from: url, maxPixelSize: 32)
        let second = await loader.image(from: url, maxPixelSize: 32)

        XCTAssertNotNil(first)
        XCTAssertNotNil(second)
        XCTAssertEqual(counter.current, 1)
    }

    func testDataIfHTTPSuccessRequires2xx() throws {
        let url = URL(string: "https://example.com/a")!
        let ok = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        XCTAssertEqual(try RemoteImageLoader.dataIfHTTPSuccess(data: Data([1]), response: ok), Data([1]))

        let bad = HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil)!
        XCTAssertThrowsError(try RemoteImageLoader.dataIfHTTPSuccess(data: Data(), response: bad))
    }

    private static var tinyPNG: Data? {
        // 1x1 transparent PNG
        Data(
            base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO5WNlwAAAAASUVORK5CYII="
        )
    }
}
