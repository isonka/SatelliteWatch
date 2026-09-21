import Foundation

struct LaunchLibraryAPIClient: ServiceProtocol {
    private let http: HTTPClient
    private let rocketCache: RocketIDCache

    init(http: HTTPClient = HTTPClient()) {
        self.http = http
        self.rocketCache = RocketIDCache()
    }

    init(transport: @escaping HTTPClient.Transport) {
        self.http = HTTPClient(transport: transport)
        self.rocketCache = RocketIDCache()
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
        if let cached = rocketCache.rocket(for: id) {
            return cached
        }
        let dto: LaunchLibraryRocketDTO = try await http.get(
            url: LaunchLibraryEndpoint.rocket(id: id).url
        )
        let rocket = Rocket(library: dto)
        rocketCache.store(rocket, for: id)
        return rocket
    }
}

private final class RocketIDCache: @unchecked Sendable {
    private let lock = NSLock()
    private var rockets: [String: Rocket] = [:]

    func rocket(for id: String) -> Rocket? {
        lock.lock()
        defer { lock.unlock() }
        return rockets[id]
    }

    func store(_ rocket: Rocket, for id: String) {
        lock.lock()
        defer { lock.unlock() }
        rockets[id] = rocket
    }
}
