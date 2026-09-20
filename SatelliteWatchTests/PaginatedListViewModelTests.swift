import Foundation
@testable import SatelliteWatch
import Testing

@MainActor
struct PaginatedListViewModelTests {
    @Test func replaceAndAppendWithPolicyC() async {
        let service = ControllableSpaceXService()
        service.rocketsPages = [
            1: .fixture(docs: [Rocket.fixture(id: "a")], page: 1, hasNextPage: true),
            2: .fixture(docs: [Rocket.fixture(id: "b")], page: 2, hasNextPage: false)
        ]

        let viewModel = PaginatedListViewModel<Rocket>(pageSize: 1) { page, limit in
            try await service.fetchRockets(page: page, limit: limit)
        }

        await viewModel.loadInitial()
        #expect(viewModel.items.map(\.id) == ["a"])

        await viewModel.loadNextPageIfNeeded(currentItem: viewModel.items.last)
        #expect(viewModel.items.map(\.id) == ["a", "b"])
        #expect(viewModel.hasNextPage == false)
    }

    /// Pull-to-refresh runs inside a SwiftUI `.refreshable` task. If that task
    /// is cancelled mid-flight the list must not be left silently empty: with no
    /// rows, no error and no spinner, the screen renders its empty state even
    /// though data was there a moment ago.
    @Test func cancelledRefreshKeepsExistingRows() async {
        let service = ControllableSpaceXService()
        service.rocketsPages = [
            1: .fixture(docs: [Rocket.fixture(id: "a")], page: 1, hasNextPage: false)
        ]

        let viewModel = PaginatedListViewModel<Rocket>(pageSize: 20) { page, limit in
            try await service.fetchRockets(page: page, limit: limit)
        }
        await viewModel.loadInitial()
        #expect(viewModel.items.map(\.id) == ["a"])

        service.delayNanoseconds = 200_000_000
        let refresh = Task { await viewModel.refresh() }
        try? await Task.sleep(nanoseconds: 20_000_000)
        refresh.cancel()
        await refresh.value

        #expect(viewModel.items.map(\.id) == ["a"])
        #expect(viewModel.isInitialLoading == false)
    }

    @Test func refreshKeepsRowsVisibleWhileLoading() async {
        let service = ControllableSpaceXService()
        service.rocketsPages = [
            1: .fixture(docs: [Rocket.fixture(id: "a")], page: 1, hasNextPage: false)
        ]

        let viewModel = PaginatedListViewModel<Rocket>(pageSize: 20) { page, limit in
            try await service.fetchRockets(page: page, limit: limit)
        }
        await viewModel.loadInitial()

        service.delayNanoseconds = 200_000_000
        service.rocketsPages = [
            1: .fixture(docs: [Rocket.fixture(id: "b")], page: 1, hasNextPage: false)
        ]
        let refresh = Task { await viewModel.refresh() }
        try? await Task.sleep(nanoseconds: 20_000_000)

        #expect(viewModel.items.map(\.id) == ["a"])
        #expect(viewModel.isRefreshing)
        #expect(viewModel.isInitialLoading == false)

        await refresh.value
        #expect(viewModel.items.map(\.id) == ["b"])
        #expect(viewModel.isRefreshing == false)
    }

    @Test func shouldLoadNextPageOnlyNearEnd() async {
        let service = ControllableSpaceXService()
        let docs = (1...10).map { Rocket.fixture(id: "\($0)") }
        service.rocketsPages = [
            1: .fixture(docs: docs, page: 1, hasNextPage: true)
        ]

        let viewModel = PaginatedListViewModel<Rocket>(pageSize: 10) { page, limit in
            try await service.fetchRockets(page: page, limit: limit)
        }
        await viewModel.loadInitial()

        #expect(viewModel.shouldLoadNextPage(currentItem: viewModel.items.first) == false)
        #expect(viewModel.shouldLoadNextPage(currentItem: viewModel.items.last) == true)
    }

    @Test func retryLoadsNextPageAfterAppendFailure() async {
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
        #expect(viewModel.items.map(\.id) == ["a"])
        #expect(viewModel.errorMessage != nil)

        service.failOnPage = nil
        service.rocketsPages[2] = .fixture(
            docs: [Rocket.fixture(id: "b")],
            page: 2,
            hasNextPage: false
        )
        await viewModel.retry()

        #expect(viewModel.items.map(\.id) == ["a", "b"])
        #expect(viewModel.errorMessage == nil)
        #expect(service.rocketListFetchCount == 3)
    }
}
