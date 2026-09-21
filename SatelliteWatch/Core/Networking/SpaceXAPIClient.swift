import Foundation

struct SpaceXAPIClient: ServiceProtocol {
    private let http: HTTPClient

    init(http: HTTPClient = HTTPClient()) {
        self.http = http
    }

    init(transport: @escaping HTTPClient.Transport) {
        self.http = HTTPClient(transport: transport)
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

        return try await http.post(url: SpaceXEndpoint.launchesQuery.url, body: body)
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
        return try await http.post(url: SpaceXEndpoint.rocketsQuery.url, body: body)
    }

    func fetchRocket(id: String) async throws -> Rocket {
        try await http.get(url: SpaceXEndpoint.rocket(id: id).url)
    }
}
