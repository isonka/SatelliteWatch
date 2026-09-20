import Foundation
@testable import SatelliteWatch
import XCTest

@MainActor
final class PaginatedListViewModelTests: XCTestCase {
    func testReplaceAndAppendWithPolicyC() async {
        let service = ControllableSpaceXService()
        service.rocketsPages = [
            1: .fixture(docs: [Rocket.fixture(id: "a")], page: 1, hasNextPage: true),
            2: .fixture(docs: [Rocket.fixture(id: "b")], page: 2, hasNextPage: false)
        ]

        let viewModel = PaginatedListViewModel<Rocket>(pageSize: 1) { page, limit in
            try await service.fetchRockets(page: page, limit: limit)
        }

        await viewModel.loadInitial()
        XCTAssertEqual(viewModel.items.map(\.id), ["a"])

        await viewModel.loadNextPageIfNeeded(currentItem: viewModel.items.last)
        XCTAssertEqual(viewModel.items.map(\.id), ["a", "b"])
        XCTAssertFalse(viewModel.hasNextPage)
    }

    /// Pull-to-refresh runs inside a SwiftUI `.refreshable` task. If that task
    /// is cancelled mid-flight the list must not be left silently empty: with no
    /// rows, no error and no spinner, the screen renders its empty state even
    /// though data was there a moment ago.
    func testCancelledRefreshKeepsExistingRows() async {
        let service = ControllableSpaceXService()
        service.rocketsPages = [
            1: .fixture(docs: [Rocket.fixture(id: "a")], page: 1, hasNextPage: false)
        ]

        let viewModel = PaginatedListViewModel<Rocket>(pageSize: 20) { page, limit in
            try await service.fetchRockets(page: page, limit: limit)
        }
        await viewModel.loadInitial()
        XCTAssertEqual(viewModel.items.map(\.id), ["a"])

        service.parkFetches = true
        let refresh = Task { await viewModel.refresh() }
        await waitUntil { service.rocketListFetchCount == 2 }
        refresh.cancel()
        await refresh.value

        XCTAssertEqual(viewModel.items.map(\.id), ["a"])
        XCTAssertFalse(viewModel.isInitialLoading)
    }

    func testRefreshKeepsRowsVisibleWhileLoading() async {
        let service = ControllableSpaceXService()
        service.rocketsPages = [
            1: .fixture(docs: [Rocket.fixture(id: "a")], page: 1, hasNextPage: false)
        ]

        let viewModel = PaginatedListViewModel<Rocket>(pageSize: 20) { page, limit in
            try await service.fetchRockets(page: page, limit: limit)
        }
        await viewModel.loadInitial()

        service.parkFetches = true
        service.rocketsPages = [
            1: .fixture(docs: [Rocket.fixture(id: "b")], page: 1, hasNextPage: false)
        ]
        let refresh = Task { await viewModel.refresh() }
        await waitUntil { service.rocketListFetchCount == 2 }

        XCTAssertEqual(viewModel.items.map(\.id), ["a"])
        XCTAssertTrue(viewModel.isRefreshing)
        XCTAssertFalse(viewModel.isInitialLoading)

        service.parkFetches = false
        service.releaseParkedFetch()
        await refresh.value
        XCTAssertEqual(viewModel.items.map(\.id), ["b"])
        XCTAssertFalse(viewModel.isRefreshing)
    }

    func testShouldLoadNextPageOnlyNearEnd() async {
        let service = ControllableSpaceXService()
        let docs = (1...10).map { Rocket.fixture(id: "\($0)") }
        service.rocketsPages = [
            1: .fixture(docs: docs, page: 1, hasNextPage: true)
        ]

        let viewModel = PaginatedListViewModel<Rocket>(pageSize: 10) { page, limit in
            try await service.fetchRockets(page: page, limit: limit)
        }
        await viewModel.loadInitial()

        XCTAssertFalse(viewModel.shouldLoadNextPage(currentItem: viewModel.items.first))
        XCTAssertTrue(viewModel.shouldLoadNextPage(currentItem: viewModel.items.last))
    }

    func testRetryLoadsNextPageAfterAppendFailure() async {
        let service = ControllableSpaceXService()
        service.rocketsPages = [
            1: .fixture(docs: [Rocket.fixture(id: "a")], page: 1, hasNextPage: true)
        ]
        service.failOnPage = 2

        let viewModel = PaginatedListViewModel<Rocket>(pageSize: 1) { page, limit in
            try await service.fetchRockets(page: page, limit: limit)
        }

        await viewModel.loadInitial()
        await viewModel.loadNextPageIfNeeded(currentItem: viewModel.items.last)
        XCTAssertEqual(viewModel.items.map(\.id), ["a"])
        XCTAssertNotNil(viewModel.errorMessage)

        service.failOnPage = nil
        service.rocketsPages[2] = .fixture(
            docs: [Rocket.fixture(id: "b")],
            page: 2,
            hasNextPage: false
        )
        await viewModel.retry()

        XCTAssertEqual(viewModel.items.map(\.id), ["a", "b"])
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(service.rocketListFetchCount, 3)
    }
}
