import Foundation
import os
@testable import SatelliteWatch

/// Test double with scripted responses, call counting, and optional delays.
final class ControllableSpaceXService: SpaceXServiceProtocol, @unchecked Sendable {
    private struct State {
        var launchResponses: [Result<PaginatedResponse<Launch>, Error>] = []
        var rocketPageResponses: [Result<PaginatedResponse<Rocket>, Error>] = []
        var rocketByID: [String: Result<Rocket, Error>] = [:]
        var defaultRocket: Result<Rocket, Error> = .success(.fixture())
        var launchesDelayNanoseconds: UInt64 = 0
        var rocketsDelayNanoseconds: UInt64 = 0
        var rocketDelayNanoseconds: UInt64 = 0
        var launchCalls: [(page: Int, limit: Int, start: Date?, end: Date?)] = []
        var rocketPageCalls: [(page: Int, limit: Int)] = []
        var rocketIDCalls: [String] = []
    }

    private let state = OSAllocatedUnfairLock(initialState: State())

    var launchCalls: [(page: Int, limit: Int, start: Date?, end: Date?)] {
        state.withLock { $0.launchCalls }
    }

    var rocketPageCalls: [(page: Int, limit: Int)] {
        state.withLock { $0.rocketPageCalls }
    }

    var rocketIDCalls: [String] {
        state.withLock { $0.rocketIDCalls }
    }

    func enqueueLaunchResponse(_ response: PaginatedResponse<Launch>) {
        state.withLock { $0.launchResponses.append(.success(response)) }
    }

    func enqueueLaunchError(_ error: Error) {
        state.withLock { $0.launchResponses.append(.failure(error)) }
    }

    func enqueueRocketPage(_ response: PaginatedResponse<Rocket>) {
        state.withLock { $0.rocketPageResponses.append(.success(response)) }
    }

    func enqueueRocketPageError(_ error: Error) {
        state.withLock { $0.rocketPageResponses.append(.failure(error)) }
    }

    func setRocket(id: String, result: Result<Rocket, Error>) {
        state.withLock { $0.rocketByID[id] = result }
    }

    func setDefaultRocket(_ result: Result<Rocket, Error>) {
        state.withLock { $0.defaultRocket = result }
    }

    func setLaunchesDelay(nanoseconds: UInt64) {
        state.withLock { $0.launchesDelayNanoseconds = nanoseconds }
    }

    func setRocketsDelay(nanoseconds: UInt64) {
        state.withLock { $0.rocketsDelayNanoseconds = nanoseconds }
    }

    func setRocketDelay(nanoseconds: UInt64) {
        state.withLock { $0.rocketDelayNanoseconds = nanoseconds }
    }

    func fetchLaunches(
        page: Int,
        limit: Int,
        startDate: Date?,
        endDate: Date?
    ) async throws -> PaginatedResponse<Launch> {
        let (delay, result) = state.withLock { state -> (UInt64, Result<PaginatedResponse<Launch>, Error>) in
            state.launchCalls.append((page, limit, startDate, endDate))
            let delay = state.launchesDelayNanoseconds
            let result: Result<PaginatedResponse<Launch>, Error>
            if state.launchResponses.isEmpty {
                result = .success(.page([], page: page, limit: limit))
            } else {
                result = state.launchResponses.removeFirst()
            }
            return (delay, result)
        }

        if delay > 0 {
            try await Task.sleep(nanoseconds: delay)
        }
        return try result.get()
    }

    func fetchRockets(page: Int, limit: Int) async throws -> PaginatedResponse<Rocket> {
        let (delay, result) = state.withLock { state -> (UInt64, Result<PaginatedResponse<Rocket>, Error>) in
            state.rocketPageCalls.append((page, limit))
            let delay = state.rocketsDelayNanoseconds
            let result: Result<PaginatedResponse<Rocket>, Error>
            if state.rocketPageResponses.isEmpty {
                result = .success(.page([], page: page, limit: limit))
            } else {
                result = state.rocketPageResponses.removeFirst()
            }
            return (delay, result)
        }

        if delay > 0 {
            try await Task.sleep(nanoseconds: delay)
        }
        return try result.get()
    }

    func fetchRocket(id: String) async throws -> Rocket {
        let (delay, result) = state.withLock { state -> (UInt64, Result<Rocket, Error>) in
            state.rocketIDCalls.append(id)
            return (state.rocketDelayNanoseconds, state.rocketByID[id] ?? state.defaultRocket)
        }

        if delay > 0 {
            try await Task.sleep(nanoseconds: delay)
        }
        return try result.get()
    }
}
