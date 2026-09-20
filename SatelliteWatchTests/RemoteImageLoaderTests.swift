import Foundation
import UIKit
@testable import SatelliteWatch
import XCTest

@MainActor
final class RemoteImageLoaderTests: XCTestCase {
    func testDownsampleCapsLongestPixelEdge() throws {
        let thumbnail = RemoteImageLoader.downsample(data: try pngData(), maxPixelSize: 16)

        guard let cgImage = thumbnail?.cgImage else {
            XCTFail("Downsample returned no image")
            return
        }
        XCTAssertLessThanOrEqual(max(cgImage.width, cgImage.height), 16)
    }

    func testConcurrentSameKeySharesOneRequest() async throws {
        let stub = StubImageFetch(data: try pngData(), delayNanoseconds: 150_000_000)
        let loader = RemoteImageLoader { url in
            try await stub.fetch(url)
        }
        let url = URL(string: "https://images.test/same.png")!

        async let first = loader.image(from: url, maxPixelSize: 16)
        async let second = loader.image(from: url, maxPixelSize: 16)
        let images = await (first, second)

        XCTAssertNotNil(images.0)
        XCTAssertNotNil(images.1)
        let count = await stub.count
        XCTAssertEqual(count, 1)
    }

    func testDifferentPixelSizesDoNotShareARequest() async throws {
        let stub = StubImageFetch(data: try pngData(), delayNanoseconds: 150_000_000)
        let loader = RemoteImageLoader { url in
            try await stub.fetch(url)
        }
        let url = URL(string: "https://images.test/sizes.png")!

        async let first = loader.image(from: url, maxPixelSize: 16)
        async let second = loader.image(from: url, maxPixelSize: 32)
        _ = await (first, second)
        let count = await stub.count
        XCTAssertEqual(count, 2)
    }

    func testCacheHitDoesNotRefetch() async throws {
        let stub = StubImageFetch(data: try pngData())
        let loader = RemoteImageLoader { url in
            try await stub.fetch(url)
        }
        let url = URL(string: "https://images.test/cached.png")!

        let first = await loader.image(from: url, maxPixelSize: 16)
        let second = await loader.image(from: url, maxPixelSize: 16)

        XCTAssertNotNil(first)
        XCTAssertNotNil(second)
        let count = await stub.count
        XCTAssertEqual(count, 1)
    }

    func testFileURLDoesNotFetch() async {
        let stub = StubImageFetch(data: Data())
        let loader = RemoteImageLoader { url in
            try await stub.fetch(url)
        }
        let image = await loader.image(
            from: URL(string: "file:///tmp/secret.png")!,
            maxPixelSize: 16
        )

        XCTAssertNil(image)
        let count = await stub.count
        XCTAssertEqual(count, 0)
    }

    func testHTTPErrorStatusIsRejected() throws {
        let url = URL(string: "https://images.test/missing.png")!
        let notFound = HTTPURLResponse(
            url: url,
            statusCode: 404,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!
        XCTAssertThrowsError(
            try RemoteImageLoader.dataIfHTTPSuccess(data: Data(), response: notFound)
        )

        let ok = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!
        let body = Data("ok".utf8)
        XCTAssertEqual(try RemoteImageLoader.dataIfHTTPSuccess(data: body, response: ok), body)
    }

    private func pngData() throws -> Data {
        let data = UIGraphicsImageRenderer(size: CGSize(width: 64, height: 32)).image { renderer in
            UIColor.red.setFill()
            renderer.fill(CGRect(x: 0, y: 0, width: 64, height: 32))
        }.pngData()
        guard let data else {
            struct PNGEncodingError: Error {}
            throw PNGEncodingError()
        }
        return data
    }
}

private actor StubImageFetch {
    private(set) var count = 0
    private let data: Data
    private let delayNanoseconds: UInt64

    init(data: Data, delayNanoseconds: UInt64 = 0) {
        self.data = data
        self.delayNanoseconds = delayNanoseconds
    }

    func fetch(_ url: URL) async throws -> Data {
        count += 1
        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }
        return data
    }
}
