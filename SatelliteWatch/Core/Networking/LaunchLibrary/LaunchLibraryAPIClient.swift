import Foundation

struct LaunchLibraryAPIClient: SpaceXServiceProtocol {
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
        let bounds = LaunchDateRangeEncoder.queryBounds(start: startDate, end: endDate)
        let response: LaunchLibraryListResponse<LaunchLibraryLaunchDTO> = try await http.get(
            url: LaunchLibraryEndpoint.launches(
                page: page,
                limit: limit,
                startUTC: bounds.startUTC,
                endUTC: bounds.endUTC
            ).url
        )
        return response.mappedPage(page: page, limit: limit) { Launch(library: $0) }
    }

    func fetchRockets(page: Int, limit: Int) async throws -> PaginatedResponse<Rocket> {
        let response: LaunchLibraryListResponse<LaunchLibraryRocketDTO> = try await http.get(
            url: LaunchLibraryEndpoint.rockets(page: page, limit: limit).url
        )
        return response.mappedPage(page: page, limit: limit) { Rocket(library: $0) }
    }

    func fetchRocket(id: String) async throws -> Rocket {
        let dto: LaunchLibraryRocketDTO = try await http.get(
            url: LaunchLibraryEndpoint.rocket(id: id).url
        )
        return Rocket(library: dto)
    }
}
