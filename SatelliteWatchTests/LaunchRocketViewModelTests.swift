import Foundation
@testable import SatelliteWatch
import XCTest

@MainActor
final class LaunchRocketViewModelTests: XCTestCase {
    func testPopulatedRocketIsReadyWithoutFetching() async {
        let service = ControllableSpaceXService()
        let viewModel = LaunchRocketViewModel(
            launch: .fixture(rocket: .populated(.fixture(id: "falcon9")))
        )

        XCTAssertEqual(viewModel.state, .loaded(.fixture(id: "falcon9")))

        await viewModel.loadIfNeeded(using: service)
        XCTAssertEqual(service.rocketFetchCount, 0)
    }

    func testUnpopulatedRocketIsFetchedByID() async {
        let service = ControllableSpaceXService()
        let viewModel = LaunchRocketViewModel(
            launch: .fixture(rocket: .id("falconheavy"))
        )

        XCTAssertEqual(viewModel.state, .idle)

        await viewModel.loadIfNeeded(using: service)

        XCTAssertEqual(service.rocketFetchCount, 1)
        XCTAssertEqual(service.lastRocketID, "falconheavy")
        XCTAssertEqual(viewModel.state, .loaded(.fixture(id: "falconheavy")))
    }

    func testLoadIsNotRepeatedOnceLoaded() async {
        let service = ControllableSpaceXService()
        let viewModel = LaunchRocketViewModel(
            launch: .fixture(rocket: .id("falconheavy"))
        )

        await viewModel.loadIfNeeded(using: service)
        await viewModel.loadIfNeeded(using: service)

        XCTAssertEqual(service.rocketFetchCount, 1)
    }

    func testFailureSurfacesMessageAndRetrySucceeds() async {
        let service = ControllableSpaceXService()
        service.rocketError = SpaceXAPIError.httpStatus(500)

        let viewModel = LaunchRocketViewModel(
            launch: .fixture(rocket: .id("falcon9"))
        )

        await viewModel.loadIfNeeded(using: service)

        guard case .failed(let message) = viewModel.state else {
            XCTFail("Expected failed state, got \(viewModel.state)")
            return
        }
        XCTAssertFalse(message.isEmpty)

        service.rocketError = nil
        await viewModel.retry()

        XCTAssertEqual(viewModel.state, .loaded(.fixture(id: "falcon9")))
        XCTAssertEqual(service.rocketFetchCount, 2)
    }

    func testRetryDoesNothingWhenNotFailed() async {
        let service = ControllableSpaceXService()
        let viewModel = LaunchRocketViewModel(
            launch: .fixture(rocket: .populated(.fixture()))
        )

        await viewModel.retry()
        XCTAssertEqual(service.rocketFetchCount, 0)
    }
}
