import Foundation

struct Launch: Identifiable, Sendable, Equatable {
    let id: String
}

struct Rocket: Identifiable, Sendable, Equatable {
    let id: String
}

struct PaginatedResponse<Document: Sendable>: Sendable {
    let docs: [Document]
    let page: Int
    let hasNextPage: Bool
}

protocol SpaceXServiceProtocol: Sendable {
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
