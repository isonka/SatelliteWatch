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
}
