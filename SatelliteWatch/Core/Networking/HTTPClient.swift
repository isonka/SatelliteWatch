import Foundation

struct HTTPClient: Sendable {
    typealias Transport = @Sendable (URLRequest) async throws -> (Data, URLResponse)

    static let defaultUserAgent = "SatelliteWatch/1.0 (iOS)"

    private static let cachedSession: URLSession = {
        let cache = URLCache(
            memoryCapacity: 8 * 1_024 * 1_024,
            diskCapacity: 32 * 1_024 * 1_024
        )
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = cache
        return URLSession(configuration: configuration)
    }()

    static let defaultTransport: Transport = { request in
        try await cachedSession.data(for: request)
    }

    private let transport: Transport

    init(transport: @escaping Transport = HTTPClient.defaultTransport) {
        self.transport = transport
    }

    func get<Response: Decodable>(url: URL) async throws -> Response {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyDefaultHeaders(to: &request)
        return try await send(request)
    }

    func post<Body: Encodable, Response: Decodable>(
        url: URL,
        body: Body
    ) async throws -> Response {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        applyDefaultHeaders(to: &request)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try SpaceXJSONEncoderFactory.make().encode(body)
        return try await send(request)
    }

    func send<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await transport(request)
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch {
            throw SpaceXAPIError.transport(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw SpaceXAPIError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            throw SpaceXAPIError.httpStatus(http.statusCode)
        }

        do {
            return try SpaceXJSONDecoderFactory.make().decode(Response.self, from: data)
        } catch {
            throw SpaceXAPIError.decoding(error.localizedDescription)
        }
    }

    private func applyDefaultHeaders(to request: inout URLRequest) {
        if request.value(forHTTPHeaderField: "Accept") == nil {
            request.setValue("application/json", forHTTPHeaderField: "Accept")
        }
        if request.value(forHTTPHeaderField: "User-Agent") == nil {
            request.setValue(Self.defaultUserAgent, forHTTPHeaderField: "User-Agent")
        }
    }
}
