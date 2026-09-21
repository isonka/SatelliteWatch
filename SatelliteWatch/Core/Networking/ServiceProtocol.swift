import Foundation

protocol ServiceProtocol: Sendable {
    func fetchLaunches(
        page: Int,
        limit: Int,
        startDate: Date?,
        endDate: Date?
    ) async throws -> PaginatedResponse<Launch>

    func fetchRockets(
        page: Int,
        limit: Int
    ) async throws -> PaginatedResponse<Rocket>

    func fetchRocket(id: String) async throws -> Rocket
}
