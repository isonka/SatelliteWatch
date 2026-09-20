import Foundation
import os
@testable import SatelliteWatch

final class ControllableSpaceXService: SpaceXServiceProtocol, @unchecked Sendable {
    private struct Scripted<Value>: @unchecked Sendable {
        let result: Result<Value, Error>
        let gate: TestGate?
    }

    private struct State: @unchecked Sendable {
        var launchResponses: [Scripted<PaginatedResponse<Launch>>] = []
        var rocketPageResponses: [Scripted<PaginatedResponse<Rocket>>] = []
        var rocketByID: [String: Result<Rocket, Error>] = [:]
        var defaultRocket: Result<Rocket, Error> = .success(.fixture())
        var rocketGate: TestGate?
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

    func enqueueLaunchResponse(_ response: PaginatedResponse<Launch>, gatedBy gate: TestGate? = nil) {
        state.withLock { $0.launchResponses.append(Scripted(result: .success(response), gate: gate)) }
    }

    func enqueueLaunchError(_ error: Error, gatedBy gate: TestGate? = nil) {
        state.withLock { $0.launchResponses.append(Scripted(result: .failure(error), gate: gate)) }
    }

    func enqueueRocketPage(_ response: PaginatedResponse<Rocket>, gatedBy gate: TestGate? = nil) {
        state.withLock { $0.rocketPageResponses.append(Scripted(result: .success(response), gate: gate)) }
    }

    func enqueueRocketPageError(_ error: Error, gatedBy gate: TestGate? = nil) {
        state.withLock { $0.rocketPageResponses.append(Scripted(result: .failure(error), gate: gate)) }
    }

    func setRocket(id: String, result: Result<Rocket, Error>) {
        state.withLock { $0.rocketByID[id] = result }
    }

    func setDefaultRocket(_ result: Result<Rocket, Error>) {
        state.withLock { $0.defaultRocket = result }
    }

    func setRocketGate(_ gate: TestGate?) {
        state.withLock { $0.rocketGate = gate }
    }

    func fetchLaunches(
        page: Int,
        limit: Int,
        startDate: Date?,
        endDate: Date?
    ) async throws -> PaginatedResponse<Launch> {
        let scripted = state.withLock { state -> Scripted<PaginatedResponse<Launch>> in
            state.launchCalls.append((page, limit, startDate, endDate))
            guard !state.launchResponses.isEmpty else {
                return Scripted(result: .success(.page([], page: page, limit: limit)), gate: nil)
            }
            return state.launchResponses.removeFirst()
        }

        await scripted.gate?.enterAndWait()
        return try scripted.result.get()
    }

    func fetchRockets(page: Int, limit: Int) async throws -> PaginatedResponse<Rocket> {
        let scripted = state.withLock { state -> Scripted<PaginatedResponse<Rocket>> in
            state.rocketPageCalls.append((page, limit))
            guard !state.rocketPageResponses.isEmpty else {
                return Scripted(result: .success(.page([], page: page, limit: limit)), gate: nil)
            }
            return state.rocketPageResponses.removeFirst()
        }

        await scripted.gate?.enterAndWait()
        return try scripted.result.get()
    }

    func fetchRocket(id: String) async throws -> Rocket {
        let (gate, result) = state.withLock { state -> (TestGate?, Result<Rocket, Error>) in
            state.rocketIDCalls.append(id)
            return (state.rocketGate, state.rocketByID[id] ?? state.defaultRocket)
        }

        await gate?.enterAndWait()
        return try result.get()
    }
}
