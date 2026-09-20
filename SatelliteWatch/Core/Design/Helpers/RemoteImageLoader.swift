import ImageIO
import UIKit

actor RemoteImageLoader {
    static let shared = RemoteImageLoader()

    private let cache = NSCache<NSString, UIImage>()
    private let fetch: @Sendable (URL) async throws -> Data
    private var inFlight: [NSString: Task<UIImage?, Never>] = [:]

    init(
        fetch: @escaping @Sendable (URL) async throws -> Data = { url in
            try await RemoteImageLoader.fetchHTTPData(from: url)
        }
    ) {
        self.fetch = fetch
        cache.countLimit = 80
        cache.totalCostLimit = 40 * 1024 * 1024
    }

    func image(from url: URL, maxPixelSize: CGFloat) async -> UIImage? {
        guard HTTPURL.isAllowed(url) else { return nil }
        let key = Self.cacheKey(url: url, maxPixelSize: maxPixelSize)
        if let cached = cache.object(forKey: key) {
            return cached
        }

        let task: Task<UIImage?, Never>
        let ownsTask: Bool
        if let existing = inFlight[key] {
            task = existing
            ownsTask = false
        } else {
            task = Task {
                await self.performLoad(url: url, key: key, maxPixelSize: maxPixelSize)
            }
            inFlight[key] = task
            ownsTask = true
        }

        let image = await task.value
        if ownsTask {
            inFlight[key] = nil
        }
        return image
    }

    nonisolated static func downsample(data: Data, maxPixelSize: CGFloat) -> UIImage? {
        let sourceOptions: [CFString: Any] = [kCGImageSourceShouldCache: false]
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions as CFDictionary) else {
            return nil
        }

        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: max(1, Int(maxPixelSize.rounded()))
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            thumbnailOptions as CFDictionary
        ) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    nonisolated static func fetchHTTPData(from url: URL) async throws -> Data {
        guard HTTPURL.isAllowed(url) else {
            throw URLError(.unsupportedURL)
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        return try dataIfHTTPSuccess(data: data, response: response)
    }

    nonisolated static func dataIfHTTPSuccess(data: Data, response: URLResponse) throws -> Data {
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode)
        else {
            throw URLError(.badServerResponse)
        }
        return data
    }

    private func performLoad(url: URL, key: NSString, maxPixelSize: CGFloat) async -> UIImage? {
        do {
            let data = try await fetch(url)
            try Task.checkCancellation()
            guard let image = Self.downsample(data: data, maxPixelSize: maxPixelSize) else {
                return nil
            }
            cache.setObject(
                image,
                forKey: key,
                cost: Int(maxPixelSize * maxPixelSize * 4)
            )
            return image
        } catch {
            return nil
        }
    }

    nonisolated private static func cacheKey(url: URL, maxPixelSize: CGFloat) -> NSString {
        "\(url.absoluteString)#\(Int(maxPixelSize.rounded()))" as NSString
    }
}
