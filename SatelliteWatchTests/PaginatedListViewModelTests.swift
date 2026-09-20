import XCTest
@testable import SatelliteWatch

@MainActor
final class PaginatedListViewModelTests: XCTestCase {

    // MARK: - Loading

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

    func testLoadInitialRequestsFirstPageAtConfiguredPageSize() async throws {
        let service = ControllableSpaceXService()
        service.enqueueRocketPage(.page([.fixture(id: "a")], page: 1))
        let viewModel = PaginatedListViewModel<Rocket>(service: service, pageSize: 7)

        await viewModel.loadInitial()

        let call = try XCTUnwrap(service.rocketPageCalls.last)
        XCTAssertEqual(call.page, 1)
        XCTAssertEqual(call.limit, 7)
    }

    func testInitialLoadFailureSetsErrorAndLeavesListEmpty() async {
        let service = ControllableSpaceXService()
        service.enqueueRocketPageError(SpaceXAPIError.httpStatus(525))
        let viewModel = PaginatedListViewModel<Rocket>(service: service)

        await viewModel.loadInitial()

        XCTAssertTrue(viewModel.items.isEmpty)
        XCTAssertEqual(viewModel.errorMessage, SpaceXAPIError.httpStatus(525).errorDescription)
        XCTAssertFalse(viewModel.isInitialLoading)
    }

    // MARK: - Appending

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

    func testAppendAsksForThePageAfterTheOneTheServerReported() async throws {
        let service = ControllableSpaceXService()
        // The server answers "page 4" even though page 1 was requested; the next
        // append must follow the server's number, not a local counter.
        service.enqueueRocketPage(.page([.fixture(id: "a")], page: 4, hasNextPage: true))
        service.enqueueRocketPage(.page([.fixture(id: "b")], page: 5, hasNextPage: false))
        let viewModel = PaginatedListViewModel<Rocket>(service: service, pageSize: 1)

        await viewModel.loadInitial()
        await viewModel.loadNextPageIfNeeded(currentItem: viewModel.items.last)

        XCTAssertEqual(service.rocketPageCalls.map(\.page), [1, 5])
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

    func testSecondAppendIsIgnoredWhileTheFirstIsStillInFlight() async {
        let gate = TestGate()
        let service = ControllableSpaceXService()
        service.enqueueRocketPage(.page([.fixture(id: "a")], page: 1, hasNextPage: true))
        service.enqueueRocketPage(.page([.fixture(id: "b")], page: 2, hasNextPage: true), gatedBy: gate)
        let viewModel = PaginatedListViewModel<Rocket>(service: service, pageSize: 1)

        await viewModel.loadInitial()

        // First append parks inside the service; the second must be dropped
        // rather than queued, or the list would double-load a page.
        let firstAppend = Task { await viewModel.loadNextPageIfNeeded(currentItem: viewModel.items.last) }
        await gate.waitUntilEntered()
        await viewModel.loadNextPageIfNeeded(currentItem: viewModel.items.last)
        await gate.open()
        await firstAppend.value

        XCTAssertEqual(service.rocketPageCalls.count, 2)
        XCTAssertEqual(viewModel.items.map(\.id), ["a", "b"])
    }

    // MARK: - Prefetch threshold

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

    func testShouldLoadNextPageFalseForAnItemNotInTheList() async {
        let service = ControllableSpaceXService()
        service.enqueueRocketPage(.page([.fixture(id: "a")], page: 1, hasNextPage: true))
        let viewModel = PaginatedListViewModel<Rocket>(service: service)

        await viewModel.loadInitial()
        XCTAssertFalse(viewModel.shouldLoadNextPage(currentItem: .fixture(id: "not-in-list")))
    }

    // MARK: - Retry

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

    // MARK: - Refresh

    func testRefreshReplacesRowsRatherThanAppending() async {
        let service = ControllableSpaceXService()
        service.enqueueRocketPage(.page([.fixture(id: "old")], page: 1, hasNextPage: true))
        service.enqueueRocketPage(.page([.fixture(id: "new")], page: 1, hasNextPage: false))
        let viewModel = PaginatedListViewModel<Rocket>(service: service)

        await viewModel.loadInitial()
        await viewModel.refresh()

        XCTAssertEqual(viewModel.items.map(\.id), ["new"])
        XCTAssertFalse(viewModel.isRefreshing)
    }

    func testRefreshFailureSurfacesErrorAndClearsTheRefreshFlag() async {
        let service = ControllableSpaceXService()
        service.enqueueRocketPage(.page([.fixture(id: "a")], page: 1))
        service.enqueueRocketPageError(SpaceXAPIError.transport("offline"))
        let viewModel = PaginatedListViewModel<Rocket>(service: service)

        await viewModel.loadInitial()
        await viewModel.refresh()

        XCTAssertEqual(viewModel.errorMessage, SpaceXAPIError.transport("offline").errorDescription)
        XCTAssertFalse(viewModel.isRefreshing)
    }

    /// A slow first load must not overwrite the rows a later refresh already
    /// delivered. The gate makes the interleaving exact instead of timing-based.
    func testStaleGenerationIsDiscardedWhenSupersededByRefresh() async {
        let gate = TestGate()
        let service = ControllableSpaceXService()
        service.enqueueRocketPage(.page([.fixture(id: "slow")], page: 1), gatedBy: gate)
        service.enqueueRocketPage(.page([.fixture(id: "fast")], page: 1))
        let viewModel = PaginatedListViewModel<Rocket>(service: service)

        let slowLoad = Task { await viewModel.loadInitial() }
        await gate.waitUntilEntered()      // the slow fetch is provably in flight
        await viewModel.refresh()          // supersedes it and completes first
        await gate.open()                  // only now may the stale fetch return
        await slowLoad.value

        XCTAssertEqual(viewModel.items.map(\.id), ["fast"])
        XCTAssertNil(viewModel.errorMessage)
    }

    /// Same race, but the superseded request is the one that fails: its error
    /// must not appear over the fresher successful page.
    func testStaleFailureDoesNotOverwriteAFresherSuccess() async {
        let gate = TestGate()
        let service = ControllableSpaceXService()
        service.enqueueRocketPageError(SpaceXAPIError.httpStatus(500), gatedBy: gate)
        service.enqueueRocketPage(.page([.fixture(id: "fresh")], page: 1))
        let viewModel = PaginatedListViewModel<Rocket>(service: service)

        let failingLoad = Task { await viewModel.loadInitial() }
        await gate.waitUntilEntered()
        await viewModel.refresh()
        await gate.open()
        await failingLoad.value

        XCTAssertEqual(viewModel.items.map(\.id), ["fresh"])
        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - Cancellation

    /// Cancelling the caller must abandon the in-flight page instead of
    /// applying it late.
    func testCancellingTheCallerDiscardsTheInFlightPage() async {
        let gate = TestGate()
        let service = ControllableSpaceXService()
        service.enqueueRocketPage(.page([.fixture(id: "late")], page: 1), gatedBy: gate)
        let viewModel = PaginatedListViewModel<Rocket>(service: service)

        let load = Task { await viewModel.loadInitial() }
        await gate.waitUntilEntered()
        load.cancel()
        await gate.open()
        await load.value

        XCTAssertTrue(viewModel.items.isEmpty)
        XCTAssertNil(viewModel.errorMessage)
    }

    /// A cancellation is not a failure: it must never reach the user as an
    /// error banner. Both cancellation shapes the client can throw are covered.
    func testCancellationErrorIsNotShownToTheUser() async {
        let service = ControllableSpaceXService()
        service.enqueueRocketPageError(CancellationError())
        let viewModel = PaginatedListViewModel<Rocket>(service: service)

        await viewModel.loadInitial()

        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.items.isEmpty)
        XCTAssertFalse(viewModel.isInitialLoading)
    }

    func testCancelledURLErrorIsNotShownToTheUser() async {
        let service = ControllableSpaceXService()
        service.enqueueRocketPageError(URLError(.cancelled))
        let viewModel = PaginatedListViewModel<Rocket>(service: service)

        await viewModel.loadInitial()

        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isInitialLoading)
    }
}
