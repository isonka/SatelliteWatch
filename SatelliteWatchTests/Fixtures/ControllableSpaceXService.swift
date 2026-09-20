import Foundation
import XCTest
@testable import SatelliteWatch

final class ControllableSpaceXService: SpaceXServiceProtocol, @unchecked Sendable {
    var launchesPages: [Int: PaginatedResponse<Launch>] = [:]
    var rocketsPages: [Int: PaginatedResponse<Rocket>] = [:]
    var failOnPage: Int?
    var rocketError: Error?
    var parkFetches = false
    var delayNanoseconds: UInt64 = 0
    private(set) var launchFetchCount = 0
    private(set) var rocketListFetchCount = 0
    private(set) var rocketFetchCount = 0
    private(set) var lastRocketID: String?
    private(set) var lastStartDate: Date?
    private(set) var lastEndDate: Date?

    private var parkContinuation: CheckedContinuation<Void, any Error>?

    func releaseParkedFetch() {
        parkContinuation?.resume()
        parkContinuation = nil
    }

    func fetchLaunches(
        page: Int,
        limit: Int,
        startDate: Date?,
        endDate: Date?
    ) async throws -> PaginatedResponse<Launch> {
        launchFetchCount += 1
        lastStartDate = startDate
        lastEndDate = endDate
        try await waitIfNeeded()

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
        try await waitIfNeeded()

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

    private func waitIfNeeded() async throws {
        if parkFetches {
            try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { continuation in
                    if let existing = parkContinuation {
                        existing.resume(throwing: CancellationError())
                    }
                    parkContinuation = continuation
                }
            } onCancel: { [self] in
                parkContinuation?.resume(throwing: CancellationError())
                parkContinuation = nil
            }
            return
        }

        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }
        try Task.checkCancellation()
    }
}

@MainActor
func waitUntil(
    timeoutNanoseconds: UInt64 = 1_000_000_000,
    file: StaticString = #filePath,
    line: UInt = #line,
    _ condition: @Sendable () -> Bool
) async {
    let deadline = DispatchTime.now().uptimeNanoseconds + timeoutNanoseconds
    while !condition() {
        if DispatchTime.now().uptimeNanoseconds >= deadline {
            XCTFail("Timed out waiting for condition", file: file, line: line)
            return
        }
        await Task.yield()
    }
}
