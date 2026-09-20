import XCTest
@testable import SatelliteWatch

@MainActor
final class LaunchRocketViewModelTests: XCTestCase {
    func testPopulatedRocketStartsLoadedWithoutFetch() async {
        let launch = Launch.fixture(rocket: .populated(.fixture(id: "falcon9", name: "Falcon 9")))
        let viewModel = LaunchRocketViewModel(launch: launch)
        let service = ControllableSpaceXService()

        await viewModel.loadIfNeeded(using: service)

        XCTAssertEqual(viewModel.state, .loaded(.fixture(id: "falcon9", name: "Falcon 9")))
        XCTAssertTrue(service.rocketIDCalls.isEmpty)
    }

    func testIDOnlyFetchesRocket() async {
        let launch = Launch.fixture(rocket: .id("falcon9"))
        let viewModel = LaunchRocketViewModel(launch: launch)
        let service = ControllableSpaceXService()
        let rocket = Rocket.fixture(id: "falcon9", name: "Fetched")
        service.setRocket(id: "falcon9", result: .success(rocket))

        XCTAssertEqual(viewModel.state, .idle)
        await viewModel.loadIfNeeded(using: service)

        XCTAssertEqual(viewModel.state, .loaded(rocket))
        XCTAssertEqual(service.rocketIDCalls, ["falcon9"])
    }

    func testMissingRocketIsUnavailable() async {
        let launch = Launch.fixture(rocket: nil)
        let viewModel = LaunchRocketViewModel(launch: launch)
        let service = ControllableSpaceXService()

        await viewModel.loadIfNeeded(using: service)

        XCTAssertEqual(viewModel.state, .unavailable)
        XCTAssertTrue(service.rocketIDCalls.isEmpty)
    }

    func testFetchFailureThenRetry() async {
        let launch = Launch.fixture(rocket: .id("falcon9"))
        let viewModel = LaunchRocketViewModel(launch: launch)
        let service = ControllableSpaceXService()
        service.setRocket(id: "falcon9", result: .failure(SpaceXAPIError.httpStatus(404)))

        await viewModel.loadIfNeeded(using: service)
        XCTAssertEqual(
            viewModel.state,
            .failed(SpaceXAPIError.httpStatus(404).errorDescription ?? "")
        )

        service.setRocket(id: "falcon9", result: .success(.fixture(id: "falcon9")))
        await viewModel.retry()
        XCTAssertEqual(viewModel.state, .loaded(.fixture(id: "falcon9")))
    }

    func testRetryIgnoredUnlessFailed() async {
        let launch = Launch.fixture(rocket: .populated(.fixture()))
        let viewModel = LaunchRocketViewModel(launch: launch)
        let service = ControllableSpaceXService()

        await viewModel.retry()
        XCTAssertTrue(service.rocketIDCalls.isEmpty)
        XCTAssertEqual(viewModel.state, .loaded(.fixture()))
    }
}
