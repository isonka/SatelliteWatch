import Foundation

struct SpaceXAPIClient: SpaceXServiceProtocol {
    private let transport: @Sendable (URLRequest) async throws -> (Data, URLResponse)
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        transport: @escaping @Sendable (URLRequest) async throws -> (Data, URLResponse) = {
            try await URLSession.shared.data(for: $0)
        },
        decoder: JSONDecoder = SpaceXJSONDecoderFactory.make(),
        encoder: JSONEncoder = SpaceXJSONEncoderFactory.make()
    ) {
        self.transport = transport
        self.decoder = decoder
        self.encoder = encoder
    }

    func fetchLaunches(
        page: Int,
        limit: Int,
        startDate: Date?,
        endDate: Date?
    ) async throws -> PaginatedResponse<Launch> {
        var query: [String: SpaceXQueryValue] = [:]

        let bounds = LaunchDateRangeEncoder.queryBounds(start: startDate, end: endDate)
        if bounds.startUTC != nil || bounds.endUTC != nil {
            var dateQuery: [String: SpaceXQueryValue] = [:]
            if let startUTC = bounds.startUTC {
                dateQuery["$gte"] = .string(startUTC)
            }
            if let endUTC = bounds.endUTC {
                dateQuery["$lte"] = .string(endUTC)
            }
            query["date_utc"] = .object(dateQuery)
        }

        let body = SpaceXQueryRequest(
            query: query,
            options: SpaceXQueryOptions(
                page: page,
                limit: limit,
                sort: ["date_utc": "desc"],
                populate: ["rocket", "launchpad"]
            )
        )

        return try await post(endpoint: .launchesQuery, body: body)
    }

    func fetchRockets(page: Int, limit: Int) async throws -> PaginatedResponse<Rocket> {
        let body = SpaceXQueryRequest(
            query: [:],
            options: SpaceXQueryOptions(
                page: page,
                limit: limit,
                sort: ["name": "asc"],
                populate: nil
            )
        )
        return try await post(endpoint: .rocketsQuery, body: body)
    }

    func fetchRocket(id: String) async throws -> Rocket {
        try await get(endpoint: .rocket(id: id))
    }

    private func post<Body: Encodable, Response: Decodable>(
        endpoint: SpaceXEndpoint,
        body: Body
    ) async throws -> Response {
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try encoder.encode(body)
        return try await perform(request)
    }

    private func get<Response: Decodable>(endpoint: SpaceXEndpoint) async throws -> Response {
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return try await perform(request)
    }

    private func perform<Response: Decodable>(_ request: URLRequest) async throws -> Response {
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
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw SpaceXAPIError.decoding(error.localizedDescription)
        }
    }
}
