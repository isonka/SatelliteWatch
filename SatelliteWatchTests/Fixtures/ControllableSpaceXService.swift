import Foundation
@testable import SatelliteWatch

final class ControllableSpaceXService: SpaceXServiceProtocol, @unchecked Sendable {
    var launchesPages: [Int: PaginatedResponse<Launch>] = [:]
    var rocketsPages: [Int: PaginatedResponse<Rocket>] = [:]
    var failOnPage: Int?
    var rocketError: Error?
    var delayNanoseconds: UInt64 = 0
    private(set) var launchFetchCount = 0
    private(set) var rocketListFetchCount = 0
    private(set) var rocketFetchCount = 0
    private(set) var lastRocketID: String?
    private(set) var lastStartDate: Date?
    private(set) var lastEndDate: Date?

    func fetchLaunches(
        page: Int,
        limit: Int,
        startDate: Date?,
        endDate: Date?
    ) async throws -> PaginatedResponse<Launch> {
        launchFetchCount += 1
        lastStartDate = startDate
        lastEndDate = endDate

        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }
        try Task.checkCancellation()

        if failOnPage == page {
            throw SpaceXAPIError.httpStatus(500)
        }
        guard let response = launchesPages[page] else {
            throw SpaceXAPIError.invalidResponse
        }
        return response
    }

    func fetchRockets(page: Int, limit: Int) async throws -> PaginatedResponse<Rocket> {
        rocketListFetchCount += 1

        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }
        try Task.checkCancellation()

        if failOnPage == page {
            throw SpaceXAPIError.httpStatus(500)
        }
        guard let response = rocketsPages[page] else {
            throw SpaceXAPIError.invalidResponse
        }
        return response
    }

    func fetchRocket(id: String) async throws -> Rocket {
        rocketFetchCount += 1
        lastRocketID = id

        if let rocketError {
            throw rocketError
        }
        return .fixture(id: id)
    }
}
