import Foundation
import Observation

@Observable
@MainActor
final class LaunchRocketViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded(Rocket)
        case failed(String)
        case unavailable
    }

    private(set) var state: State

    private let rocketID: String?
    private var service: (any SpaceXServiceProtocol)?

    init(launch: Launch) {
        rocketID = launch.rocket?.id

        switch launch.rocket {
        case .populated(let rocket):
            state = .loaded(rocket)
        case .id:
            state = .idle
        case nil:
            state = .unavailable
        }
    }

    func loadIfNeeded(using service: any SpaceXServiceProtocol) async {
        self.service = service
        guard state == .idle else { return }
        await load()
    }

    func retry() async {
        guard case .failed = state else { return }
        await load()
    }

    private func load() async {
        guard let service, let rocketID else { return }
        state = .loading

        do {
            state = .loaded(try await service.fetchRocket(id: rocketID))
        } catch is CancellationError {
            state = .idle
        } catch let error as URLError where error.code == .cancelled {
            state = .idle
        } catch {
            state = .failed(
                (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            )
        }
    }
}
