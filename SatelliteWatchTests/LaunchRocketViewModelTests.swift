import Foundation
@testable import SatelliteWatch
import Testing

@MainActor
struct LaunchRocketViewModelTests {
    @Test func populatedRocketIsReadyWithoutFetching() async {
        let service = ControllableSpaceXService()
        let viewModel = LaunchRocketViewModel(
            launch: .fixture(rocket: .populated(.fixture(id: "falcon9")))
        )

        #expect(viewModel.state == .loaded(.fixture(id: "falcon9")))

        await viewModel.loadIfNeeded(using: service)
        #expect(service.rocketFetchCount == 0)
    }

    @Test func unpopulatedRocketIsFetchedByID() async {
        let service = ControllableSpaceXService()
        let viewModel = LaunchRocketViewModel(
            launch: .fixture(rocket: .id("falconheavy"))
        )

        #expect(viewModel.state == .idle)

        await viewModel.loadIfNeeded(using: service)

        #expect(service.rocketFetchCount == 1)
        #expect(service.lastRocketID == "falconheavy")
        #expect(viewModel.state == .loaded(.fixture(id: "falconheavy")))
    }

    @Test func loadIsNotRepeatedOnceLoaded() async {
        let service = ControllableSpaceXService()
        let viewModel = LaunchRocketViewModel(
            launch: .fixture(rocket: .id("falconheavy"))
        )

        await viewModel.loadIfNeeded(using: service)
        await viewModel.loadIfNeeded(using: service)

        #expect(service.rocketFetchCount == 1)
    }

    @Test func failureSurfacesMessageAndRetrySucceeds() async {
        let service = ControllableSpaceXService()
        service.rocketError = SpaceXAPIError.httpStatus(500)

        let viewModel = LaunchRocketViewModel(
            launch: .fixture(rocket: .id("falcon9"))
        )

        await viewModel.loadIfNeeded(using: service)

        guard case .failed(let message) = viewModel.state else {
            Issue.record("Expected failed state, got \(viewModel.state)")
            return
        }
        #expect(!message.isEmpty)

        service.rocketError = nil
        await viewModel.retry()

        #expect(viewModel.state == .loaded(.fixture(id: "falcon9")))
        #expect(service.rocketFetchCount == 2)
    }

    @Test func retryDoesNothingWhenNotFailed() async {
        let service = ControllableSpaceXService()
        let viewModel = LaunchRocketViewModel(
            launch: .fixture(rocket: .populated(.fixture()))
        )

        await viewModel.retry()
        #expect(service.rocketFetchCount == 0)
    }
}
