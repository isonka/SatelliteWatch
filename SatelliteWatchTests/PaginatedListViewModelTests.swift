import XCTest
@testable import SatelliteWatch

@MainActor
final class PaginatedListViewModelTests: XCTestCase {
    func testLoadInitialReplacesItemsAndClearsError() async {
        let service = ControllableSpaceXService()
        service.enqueueRocketPage(.page([.fixture(id: "a"), .fixture(id: "b")], page: 1, hasNextPage: true))
        let viewModel = PaginatedListViewModel<Rocket>(service: service, pageSize: 2)

        await viewModel.loadInitial()

        XCTAssertEqual(viewModel.items.map(\.id), ["a", "b"])
        XCTAssertTrue(viewModel.hasNextPage)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isInitialLoading)
    }

    func testAppendLoadsNextPageAndDedupesIDs() async {
        let service = ControllableSpaceXService()
        service.enqueueRocketPage(
            .page([.fixture(id: "a"), .fixture(id: "b")], page: 1, limit: 2, hasNextPage: true)
        )
        service.enqueueRocketPage(
            .page([.fixture(id: "b"), .fixture(id: "c")], page: 2, limit: 2, hasNextPage: false)
        )
        let viewModel = PaginatedListViewModel<Rocket>(service: service, pageSize: 2)

        await viewModel.loadInitial()
        await viewModel.loadNextPageIfNeeded(currentItem: viewModel.items.last)

        XCTAssertEqual(viewModel.items.map(\.id), ["a", "b", "c"])
        XCTAssertFalse(viewModel.hasNextPage)
        XCTAssertEqual(service.rocketPageCalls.count, 2)
    }

    func testAppendFailureKeepsExistingRowsAndSetsError() async {
        let service = ControllableSpaceXService()
        service.enqueueRocketPage(.page([.fixture(id: "a")], page: 1, hasNextPage: true))
        service.enqueueRocketPageError(SpaceXAPIError.httpStatus(500))
        let viewModel = PaginatedListViewModel<Rocket>(service: service, pageSize: 1)

        await viewModel.loadInitial()
        await viewModel.loadNextPageIfNeeded(currentItem: viewModel.items.last)

        XCTAssertEqual(viewModel.items.map(\.id), ["a"])
        XCTAssertEqual(viewModel.errorMessage, SpaceXAPIError.httpStatus(500).errorDescription)
        XCTAssertFalse(viewModel.isLoadingMore)
    }

    func testRetryOnEmptyReloadsInitial() async {
        let service = ControllableSpaceXService()
        service.enqueueRocketPageError(SpaceXAPIError.httpStatus(503))
        service.enqueueRocketPage(.page([.fixture(id: "ok")], page: 1))
        let viewModel = PaginatedListViewModel<Rocket>(service: service)

        await viewModel.loadInitial()
        XCTAssertTrue(viewModel.items.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)

        await viewModel.retry()
        XCTAssertEqual(viewModel.items.map(\.id), ["ok"])
        XCTAssertNil(viewModel.errorMessage)
    }

    func testRetryWithItemsRequestsNextPage() async {
        let service = ControllableSpaceXService()
        service.enqueueRocketPage(.page([.fixture(id: "a")], page: 1, hasNextPage: true))
        service.enqueueRocketPageError(SpaceXAPIError.transport("down"))
        service.enqueueRocketPage(.page([.fixture(id: "b")], page: 2, hasNextPage: false))
        let viewModel = PaginatedListViewModel<Rocket>(service: service, pageSize: 1)

        await viewModel.loadInitial()
        await viewModel.loadNextPageIfNeeded(currentItem: viewModel.items.last)
        XCTAssertNotNil(viewModel.errorMessage)

        await viewModel.retry()
        XCTAssertEqual(viewModel.items.map(\.id), ["a", "b"])
        XCTAssertNil(viewModel.errorMessage)
    }

    func testShouldLoadNextPageThreshold() async {
        let rockets = (0..<6).map { Rocket.fixture(id: "r\($0)") }
        let service = ControllableSpaceXService()
        service.enqueueRocketPage(.page(rockets, page: 1, hasNextPage: true))
        let viewModel = PaginatedListViewModel<Rocket>(service: service, pageSize: 6)

        await viewModel.loadInitial()

        XCTAssertFalse(viewModel.shouldLoadNextPage(currentItem: nil))
        XCTAssertFalse(viewModel.shouldLoadNextPage(currentItem: rockets[0]))
        XCTAssertTrue(viewModel.shouldLoadNextPage(currentItem: rockets[1]))
        XCTAssertTrue(viewModel.shouldLoadNextPage(currentItem: rockets[5]))
    }

    func testShouldLoadNextPageFalseWhenNoNextPage() async {
        let service = ControllableSpaceXService()
        service.enqueueRocketPage(.page([.fixture(id: "a")], page: 1, hasNextPage: false))
        let viewModel = PaginatedListViewModel<Rocket>(service: service)

        await viewModel.loadInitial()
        XCTAssertFalse(viewModel.shouldLoadNextPage(currentItem: viewModel.items.last))
    }

    func testStaleGenerationIgnoredWhenSupersededByRefresh() async {
        let service = ControllableSpaceXService()
        service.setRocketsDelay(nanoseconds: 200_000_000)
        service.enqueueRocketPage(.page([.fixture(id: "slow")], page: 1))
        service.enqueueRocketPage(.page([.fixture(id: "fast")], page: 1))

        let viewModel = PaginatedListViewModel<Rocket>(service: service)

        async let first: Void = viewModel.loadInitial()
        try? await Task.sleep(nanoseconds: 30_000_000)
        await viewModel.refresh()
        await first

        XCTAssertEqual(viewModel.items.map(\.id), ["fast"])
    }

    func testInitialLoadFailureSetsError() async {
        let service = ControllableSpaceXService()
        service.enqueueRocketPageError(SpaceXAPIError.httpStatus(525))
        let viewModel = PaginatedListViewModel<Rocket>(service: service)

        await viewModel.loadInitial()

        XCTAssertTrue(viewModel.items.isEmpty)
        XCTAssertEqual(viewModel.errorMessage, SpaceXAPIError.httpStatus(525).errorDescription)
        XCTAssertFalse(viewModel.isInitialLoading)
    }
}
