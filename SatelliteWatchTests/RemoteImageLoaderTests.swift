import Foundation
import UIKit
@testable import SatelliteWatch
import Testing

@MainActor
struct RemoteImageLoaderTests {
    @Test func downsampleCapsLongestPixelEdge() throws {
        let thumbnail = RemoteImageLoader.downsample(data: try pngData(), maxPixelSize: 16)

        guard let cgImage = thumbnail?.cgImage else {
            Issue.record("Downsample returned no image")
            return
        }
        #expect(max(cgImage.width, cgImage.height) <= 16)
    }

    @Test func concurrentSameKeySharesOneRequest() async throws {
        let stub = StubImageFetch(data: try pngData(), delayNanoseconds: 150_000_000)
        let loader = RemoteImageLoader { url in
            try await stub.fetch(url)
        }
        let url = URL(string: "https://images.test/same.png")!

        async let first = loader.image(from: url, maxPixelSize: 16)
        async let second = loader.image(from: url, maxPixelSize: 16)
        let images = await (first, second)

        #expect(images.0 != nil)
        #expect(images.1 != nil)
        #expect(await stub.count == 1)
    }

    @Test func differentPixelSizesDoNotShareARequest() async throws {
        let stub = StubImageFetch(data: try pngData(), delayNanoseconds: 150_000_000)
        let loader = RemoteImageLoader { url in
            try await stub.fetch(url)
        }
        let url = URL(string: "https://images.test/sizes.png")!

        async let first = loader.image(from: url, maxPixelSize: 16)
        async let second = loader.image(from: url, maxPixelSize: 32)
        _ = await (first, second)

        #expect(await stub.count == 2)
    }

    @Test func cacheHitDoesNotRefetch() async throws {
        let stub = StubImageFetch(data: try pngData())
        let loader = RemoteImageLoader { url in
            try await stub.fetch(url)
        }
        let url = URL(string: "https://images.test/cached.png")!

        let first = await loader.image(from: url, maxPixelSize: 16)
        let second = await loader.image(from: url, maxPixelSize: 16)

        #expect(first != nil)
        #expect(second != nil)
        #expect(await stub.count == 1)
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
