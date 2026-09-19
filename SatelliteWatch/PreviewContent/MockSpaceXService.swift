import Foundation

struct MockSpaceXService: SpaceXServiceProtocol {
    func fetchLaunches(
        page: Int,
        limit: Int,
        startDate: Date?,
        endDate: Date?
    ) async throws -> PaginatedResponse<Launch> {
        PaginatedResponse(docs: [], page: page, hasNextPage: false)
    }

    func fetchRockets(
        page: Int,
        limit: Int
    ) async throws -> PaginatedResponse<Rocket> {
        PaginatedResponse(docs: [], page: page, hasNextPage: false)
    }

    func fetchRocket(id: String) async throws -> Rocket {
        Rocket(
            id: id,
            name: "Mock Rocket",
            type: "rocket",
            active: true,
            description: nil,
            successRatePct: nil,
            flickrImages: nil,
            engines: nil
        )
    }
}
